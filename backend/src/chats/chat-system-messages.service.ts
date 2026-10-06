import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

/// Системные сообщения чата (задача 038, п.11) — «водитель готов взять»,
/// «выбран водитель», «перевозка подтверждена», «отклик отозван»,
/// «предложен груз». Не от имени нажавшего: kind=SYSTEM, клиент строит
/// текст из ARB по systemCode+systemParams на языке читателя (моделью не
/// переводится). originalText — русский фолбэк для админки/старых клиентов.
export type ChatSystemCode =
  | 'DRIVER_READY'
  | 'DRIVER_SELECTED'
  | 'DEAL_CONFIRMED'
  | 'RESPONSE_WITHDRAWN'
  | 'RESPONSE_REJECTED'
  | 'CARGO_OFFERED';

const RU_FALLBACK: Record<ChatSystemCode, (params: Record<string, string>) => string> = {
  DRIVER_READY: (p) => `${p.driverName ?? 'Водитель'} готов взять груз`,
  DRIVER_SELECTED: (p) => `Водитель ${p.driverName ?? ''} выбран для перевозки`.replace('  ', ' '),
  RESPONSE_REJECTED: () => 'Логист отклонил отклик',
  DEAL_CONFIRMED: () => 'Перевозка подтверждена водителем',
  RESPONSE_WITHDRAWN: (p) => `${p.driverName ?? 'Водитель'} отозвал отклик`,
  CARGO_OFFERED: () => 'Логист предложил груз',
};

@Injectable()
export class ChatSystemMessagesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime: RealtimeGateway,
  ) {}

  /// Постит системное сообщение в чат пары водитель+компания(+груз).
  /// Чата нет — молча пропускает: событие произошло вне переписки
  /// (отклик с карточки груза до любого чата), создавать пустой тред ради
  /// служебной строки не нужно. Никогда не кидает — системная строка не
  /// должна ломать основное действие.
  async post(params: {
    driverId: string;
    companyId: string;
    cargoId: string | null;
    actorUserId: string;
    code: ChatSystemCode;
    systemParams?: Record<string, string>;
  }): Promise<void> {
    try {
      const chat = await this.prisma.chat.findFirst({
        where: { driverId: params.driverId, companyId: params.companyId, cargoId: params.cargoId },
        select: { id: true },
      });
      if (!chat) return;
      await this.postToChat(chat.id, params.actorUserId, params.code, params.systemParams ?? {});
    } catch {
      // лучший вариант: действие уже выполнено, системная строка — украшение
    }
  }

  /// То же, но в конкретный известный чат (attachCargo уже держит id).
  async postToChat(chatId: string, actorUserId: string, code: ChatSystemCode, systemParams: Record<string, string> = {}): Promise<void> {
    try {
      const message = await this.prisma.message.create({
        data: {
          chatId,
          senderUserId: actorUserId,
          kind: 'SYSTEM',
          systemCode: code,
          systemParams: systemParams as Prisma.InputJsonValue,
          originalText: RU_FALLBACK[code](systemParams),
          originalLang: 'ru',
          translationStatus: 'SKIPPED',
          isRead: true,
        },
      });
      await this.prisma.chat.update({ where: { id: chatId }, data: { updatedAt: new Date() } });
      this.realtime.emitMessageNew(chatId, {
        id: message.id,
        chatId: message.chatId,
        senderUserId: message.senderUserId,
        kind: message.kind,
        systemCode: message.systemCode,
        systemParams: message.systemParams,
        originalText: message.originalText,
        originalLang: message.originalLang,
        translations: message.translations,
        translationStatus: message.translationStatus,
        isRead: message.isRead,
        createdAt: message.createdAt,
      });
      // Карточка/кнопки у второй стороны обновляются сразу (задача 038,
      // п.12) — комнатное событие, личные комнаты здесь не нужны: кого нет
      // в чате, тот увидит состояние при следующем открытии.
      this.realtime.emitThreadUpdated(chatId);
    } catch {
      // см. post()
    }
  }
}
