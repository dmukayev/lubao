import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContext } from '../common/request-context';
import { NotificationsService } from '../notifications/notifications.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';

const CHAT_PREVIEW_LENGTH = 80;

@Injectable()
export class ChatsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly realtime: RealtimeGateway,
  ) {}

  private assertParty(chat: { driverId: string; companyId: string }, ctx: RequestContext) {
    const isParty = chat.driverId === ctx.driver?.id || chat.companyId === ctx.companyMember?.companyId;
    if (!isParty) throw new ForbiddenException('Not a party to this chat');
  }

  /// Чат определяется парой водитель+компания (+груз, если есть) — не
  /// только сделкой (задача 017, п.1): водитель пишет логисту по грузу
  /// до отклика, логист — водителю из ленты «Кто будет на точке». Когда
  /// по грузу возникает сделка, тот же чат привязывается к ней задним
  /// числом (см. `ResponsesService`) — история не теряется.
  async findOrCreate(ctx: RequestContext, dto: { driverId?: string; cargoId?: string }) {
    let driverId: string;
    let companyId: string;
    let cargoId: string | null = dto.cargoId ?? null;

    if (ctx.driver) {
      // Водитель пишет по конкретному грузу — груз обязателен, это и есть
      // вход в чат на карточке груза (п.2).
      if (!dto.cargoId) throw new BadRequestException('cargoId is required for a driver-initiated chat');
      const cargo = await this.prisma.cargo.findUnique({ where: { id: dto.cargoId }, select: { companyId: true } });
      if (!cargo) throw new NotFoundException('Cargo not found');
      driverId = ctx.driver.id;
      companyId = cargo.companyId;
      cargoId = dto.cargoId;
    } else if (ctx.companyMember) {
      if (!dto.driverId) throw new BadRequestException('driverId is required for a company-initiated chat');
      driverId = dto.driverId;
      companyId = ctx.companyMember.companyId;
    } else {
      throw new ForbiddenException('Not a driver or company account');
    }

    let chat = await this.prisma.chat.findFirst({ where: { driverId, companyId, cargoId } });
    if (!chat) {
      // Если по этой паре уже есть сделка (чат открыли на старом грузе,
      // который уже превратился в сделку) — сразу привязываем, а не ждём
      // отдельного шага.
      const deal = await this.prisma.deal.findFirst({ where: { driverId, companyId, cargoId: cargoId ?? undefined } });
      chat = await this.prisma.chat.create({ data: { driverId, companyId, cargoId, dealId: deal?.id ?? null } });
    }
    return this.toThreadDto(chat, ctx);
  }

  /// Логист, опубликовавший груз, — не случайный владелец (decisions.md
  /// «Компания: проверка, роли, контакты», задача 012). Для чата без груза
  /// (общий чат логиста с водителем) откатываемся на самого старого OWNER.
  private async resolveCompanyCounterpart(companyId: string, cargoId: string | null) {
    if (cargoId) {
      const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, select: { publishedByUserId: true } });
      if (cargo?.publishedByUserId) {
        const publisher = await this.prisma.companyMember.findFirst({
          where: { userId: cargo.publishedByUserId },
          include: { user: true, company: true },
        });
        if (publisher) return publisher;
      }
    }
    return this.prisma.companyMember.findFirst({
      where: { companyId, role: 'OWNER' },
      orderBy: { createdAt: 'asc' },
      include: { user: true, company: true },
    });
  }

  private async resolveParties(chat: { driverId: string; companyId: string; cargoId: string | null }) {
    const [driver, companyMember] = await Promise.all([
      this.prisma.driver.findUniqueOrThrow({ where: { id: chat.driverId }, include: { user: true } }),
      this.resolveCompanyCounterpart(chat.companyId, chat.cargoId),
    ]);
    return { driver, companyMember };
  }

  private async toThreadDto(chat: { id: string; cargoId: string | null; dealId: string | null; driverId: string; companyId: string }, ctx: RequestContext) {
    const { driver, companyMember } = await this.resolveParties(chat);
    const counterpartName = ctx.driver ? companyMember?.company.name ?? '' : driver.fullName;
    const counterpartLocale = ctx.driver ? companyMember?.user.locale : driver.user.locale;
    return {
      id: chat.id,
      cargoId: chat.cargoId,
      dealId: chat.dealId,
      driverId: chat.driverId,
      companyId: chat.companyId,
      counterpartName,
      counterpartLocale,
      counterpartPhone: ctx.driver ? companyMember?.user.phone ?? null : driver.user.phone,
    };
  }

  private async loadChat(chatId: string, ctx: RequestContext) {
    const chat = await this.prisma.chat.findUnique({ where: { id: chatId } });
    if (!chat) throw new NotFoundException('Chat not found');
    this.assertParty(chat, ctx);
    return chat;
  }

  async thread(chatId: string, ctx: RequestContext) {
    const chat = await this.loadChat(chatId, ctx);
    return this.toThreadDto(chat, ctx);
  }

  /// Мои чаты (п.1) — логист видит чаты **всех** коллег по компании
  /// (decisions.md «Кабинет логиста», задача 012: «логист видит все грузы,
  /// сделки и чаты компании»), не только свои.
  async myChats(ctx: RequestContext) {
    const where = ctx.driver ? { driverId: ctx.driver.id } : { companyId: ctx.companyMember!.companyId };
    const chats = await this.prisma.chat.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      include: {
        messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        cargo: { select: { id: true, point: { select: { name: true } } } },
      },
    });

    return Promise.all(
      chats.map(async (chat) => {
        const [thread, unreadCount] = await Promise.all([
          this.toThreadDto(chat, ctx),
          this.prisma.message.count({ where: { chatId: chat.id, isRead: false, senderUserId: { not: ctx.user.id } } }),
        ]);
        const lastMessage = chat.messages[0] ?? null;
        return {
          ...thread,
          cargoPointName: chat.cargo?.point.name ?? null,
          lastMessageText: lastMessage?.originalText ?? null,
          lastMessageAt: lastMessage?.createdAt ?? chat.createdAt,
          unreadCount,
        };
      }),
    );
  }

  async messages(chatId: string, ctx: RequestContext) {
    const chat = await this.loadChat(chatId, ctx);
    const messages = await this.prisma.message.findMany({ where: { chatId: chat.id }, orderBy: { createdAt: 'asc' } });
    return messages.map((m) => ({
      id: m.id,
      chatId: m.chatId,
      senderUserId: m.senderUserId,
      isMine: m.senderUserId === ctx.user.id,
      originalText: m.originalText,
      originalLang: m.originalLang,
      translations: m.translations,
      isRead: m.isRead,
      createdAt: m.createdAt,
    }));
  }

  async send(chatId: string, ctx: RequestContext, text: string) {
    const chat = await this.loadChat(chatId, ctx);
    const message = await this.prisma.message.create({
      data: { chatId: chat.id, senderUserId: ctx.user.id, originalText: text, originalLang: ctx.user.locale },
    });
    // Message не трогает Chat.updatedAt сам по себе — обновляем явно, иначе
    // список «Мои чаты» (order by updatedAt) не поднимет диалог наверх.
    await this.prisma.chat.update({ where: { id: chat.id }, data: { updatedAt: new Date() } });

    // Push получателю (задача 011, CHAT_MESSAGE) — не чаще раза в минуту на
    // чат, см. throttle в NOTIFICATION_EVENTS; доставка «пока открыт экран»
    // идёт мгновенно через Socket.IO (realtime.gateway), push — запасной
    // канал на случай закрытого приложения.
    const { driver, companyMember } = await this.resolveParties(chat);
    const recipientUserId = ctx.driver ? companyMember?.user.id : driver.user.id;
    const senderName = ctx.driver ? driver.fullName : companyMember?.user.name || companyMember?.company.name || '';
    if (recipientUserId) {
      await this.notifications.notify({ userIds: [recipientUserId] }, 'CHAT_MESSAGE', {
        chatId: chat.id,
        senderName,
        preview: text.length > CHAT_PREVIEW_LENGTH ? `${text.slice(0, CHAT_PREVIEW_LENGTH)}…` : text,
      });
    }

    // Мгновенная доставка собеседнику, пока открыт экран (задача 011, п.6);
    // isMine не передаём — у получателя он другой, чем у отправителя,
    // клиент сам сравнивает senderUserId со своим id.
    this.realtime.emitMessageNew(chat.id, {
      id: message.id,
      chatId: message.chatId,
      senderUserId: message.senderUserId,
      originalText: message.originalText,
      originalLang: message.originalLang,
      translations: message.translations,
      isRead: message.isRead,
      createdAt: message.createdAt,
    });

    return {
      id: message.id,
      chatId: message.chatId,
      senderUserId: message.senderUserId,
      isMine: true,
      originalText: message.originalText,
      originalLang: message.originalLang,
      translations: message.translations,
      isRead: message.isRead,
      createdAt: message.createdAt,
    };
  }

  /// Проставляет «прочитано» на чужих сообщениях в чате и шлёт
  /// message:read собеседнику (закрывает пробел из задачи 017, п.9:
  /// `Message.isRead` раньше никто не выставлял).
  async markRead(chatId: string, ctx: RequestContext): Promise<{ success: true }> {
    await this.loadChat(chatId, ctx);
    const { count } = await this.prisma.message.updateMany({
      where: { chatId, senderUserId: { not: ctx.user.id }, isRead: false },
      data: { isRead: true },
    });
    if (count > 0) {
      this.realtime.emitMessageRead(chatId, ctx.user.id);
    }
    return { success: true };
  }
}
