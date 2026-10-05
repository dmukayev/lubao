import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContext } from '../common/request-context';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { TranslationService } from '../translation/translation.service';

const CHAT_PREVIEW_LENGTH = 80;

@Injectable()
export class ChatsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly realtime: RealtimeGateway,
    private readonly translation: TranslationService,
    private readonly appSettings: AppSettingsService,
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
      const driverExists = await this.prisma.driver.findUnique({ where: { id: dto.driverId }, select: { id: true } });
      if (!driverExists) throw new NotFoundException('Driver not found');
      // Задача 029, п.13 — компания могла передать cargoId чужого груза
      // (чат всё равно создавался бы с её companyId, но дальше push/чат
      // резолвили бы контакт через publishedByUserId ЧУЖОГО груза —
      // логисту другой компании). Свой груз или вообще без груза, третьего не дано.
      if (dto.cargoId) {
        const cargo = await this.prisma.cargo.findUnique({ where: { id: dto.cargoId }, select: { companyId: true } });
        if (!cargo) throw new NotFoundException('Cargo not found');
        if (cargo.companyId !== ctx.companyMember.companyId) throw new ForbiddenException('Not your cargo');
      }
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
      try {
        chat = await this.prisma.chat.create({ data: { driverId, companyId, cargoId, dealId: deal?.id ?? null } });
      } catch (e) {
        // Двойное нажатие «Написать» (задача 029, п.13) — уникальный
        // индекс @@unique([driverId, companyId, cargoId]) ловит гонку
        // двух параллельных findOrCreate; та, что проиграла, просто
        // находит чат, который успела создать первая.
        if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
          chat = await this.prisma.chat.findFirstOrThrow({ where: { driverId, companyId, cargoId } });
        } else {
          throw e;
        }
      }
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
    // Задача 012 — водитель должен видеть конкретного логиста (его имя,
    // телефон, WeChat), а не «компанию» (decisions.md «Компания: проверка,
    // роли, контакты»). companyMember.fullName/contactPhone/wechatId —
    // пока сотрудник не заполнил «Мой профиль», откатываемся на название
    // компании/User.phone, как было раньше, а не показываем пусто.
    const counterpartName = ctx.driver ? companyMember?.fullName ?? companyMember?.company.name ?? '' : driver.fullName;
    const counterpartLocale = ctx.driver ? companyMember?.user.locale : driver.user.locale;
    return {
      id: chat.id,
      cargoId: chat.cargoId,
      dealId: chat.dealId,
      driverId: chat.driverId,
      companyId: chat.companyId,
      counterpartName,
      counterpartLocale,
      counterpartPhone: ctx.driver ? companyMember?.contactPhone ?? companyMember?.user.phone ?? null : driver.user.phone,
      counterpartWechatId: ctx.driver ? companyMember?.wechatId ?? null : null,
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
        driver: { select: { userId: true } },
      },
    });

    return Promise.all(
      chats.map(async (chat) => {
        // «Чужие» = с другой стороны чата, НЕ «не я» (задача 029, п.4):
        // для водителя — любой сотрудник компании (не он сам); для
        // компании — именно водитель, а не коллега. Иначе сообщение
        // коллеги B в чате считалось непрочитанным для коллеги A, хотя A
        // туда никогда не был адресатом.
        const incomingSenderUserId = ctx.driver ? { not: chat.driver.userId } : chat.driver.userId;
        const [thread, unreadCount] = await Promise.all([
          this.toThreadDto(chat, ctx),
          this.prisma.message.count({ where: { chatId: chat.id, isRead: false, senderUserId: incomingSenderUserId } }),
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
      translationStatus: m.translationStatus,
      isRead: m.isRead,
      createdAt: m.createdAt,
    }));
  }

  async send(chatId: string, ctx: RequestContext, text: string) {
    const chat = await this.loadChat(chatId, ctx);

    // Автоперевод (задача 010) — только на язык собеседника. Задача 029,
    // п.6: НЕ ждём провайдера здесь — DeepSeek мог «висеть» секундами
    // (таймаут 5с, SDK по умолчанию ещё и ретраит), а значит и отправка
    // сообщения «висела» вместе с ним. Сообщение сохраняется и доходит
    // мгновенно с оригиналом (PENDING), перевод — в фоне (translation.
    // processor.ts), по готовности — message:translated в комнату чата.
    const { driver, companyMember } = await this.resolveParties(chat);
    const recipientUserId = ctx.driver ? companyMember?.user.id : driver.user.id;
    const recipientLocale = ctx.driver ? companyMember?.user.locale : driver.user.locale;
    const senderName = ctx.driver ? driver.fullName : companyMember?.user.name || companyMember?.company.name || '';

    const translationEnabled = (await this.appSettings.get('translationEnabled')) !== 'false';
    const needsTranslation = translationEnabled && !!recipientLocale && recipientLocale !== ctx.user.locale;

    const message = await this.prisma.message.create({
      data: {
        chatId: chat.id,
        senderUserId: ctx.user.id,
        originalText: text,
        originalLang: ctx.user.locale,
        translationStatus: needsTranslation ? 'PENDING' : 'SKIPPED',
      },
    });
    // Message не трогает Chat.updatedAt сам по себе — обновляем явно, иначе
    // список «Мои чаты» (order by updatedAt) не поднимет диалог наверх.
    await this.prisma.chat.update({ where: { id: chat.id }, data: { updatedAt: new Date() } });

    if (needsTranslation) {
      await this.translation.enqueueTranslation({
        messageId: message.id,
        chatId: chat.id,
        text,
        from: ctx.user.locale,
        to: recipientLocale!,
        senderUserId: ctx.user.id,
      });
    }

    // Push получателю (задача 011, CHAT_MESSAGE) — не чаще раза в минуту на
    // чат, см. throttle в NOTIFICATION_EVENTS; доставка «пока открыт экран»
    // идёт мгновенно через Socket.IO (realtime.gateway), push — запасной
    // канал на случай закрытого приложения.
    if (recipientUserId) {
      await this.notifications.notify({ userIds: [recipientUserId] }, 'CHAT_MESSAGE', {
        chatId: chat.id,
        senderName,
        // needsTranslation=true → перевод ещё не готов (он асинхронный,
        // п.6) и оригинал получателю не понятен — null даёт нейтральный
        // текст на его языке (см. notification-events.ts).
        preview: needsTranslation ? null : text.length > CHAT_PREVIEW_LENGTH ? `${text.slice(0, CHAT_PREVIEW_LENGTH)}…` : text,
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
      translationStatus: message.translationStatus,
      isRead: message.isRead,
      createdAt: message.createdAt,
    });

    // «Мои чаты» обновляется у обеих сторон даже без открытого chat:<id>
    // (задача 029, п.3) — через личные комнаты, не только через комнату
    // самого чата.
    this.realtime.emitChatUpdated(ctx.user.id, { chatId: chat.id });
    if (recipientUserId) this.realtime.emitChatUpdated(recipientUserId, { chatId: chat.id });

    return {
      id: message.id,
      chatId: message.chatId,
      senderUserId: message.senderUserId,
      isMine: true,
      originalText: message.originalText,
      originalLang: message.originalLang,
      translations: message.translations,
      translationStatus: message.translationStatus,
      isRead: message.isRead,
      createdAt: message.createdAt,
    };
  }

  /// Повторная попытка перевода (задача 010, п.7 — «Перевод недоступен ·
  /// повторить»; уточнения — задача 029, п.20): уважает переключатель
  /// «Перевод выкл.», не трогает уже DONE/SKIPPED (нечего повторять —
  /// только FAILED/PENDING), лимит 60/мин считается на того, кто НАЖАЛ
  /// кнопку (ctx.user.id), а не на исходного отправителя — иначе
  /// получатель, кликающий «повторить» несколько раз, тратил бы лимит
  /// отправителя.
  async retryTranslation(chatId: string, messageId: string, ctx: RequestContext) {
    const chat = await this.loadChat(chatId, ctx);
    const message = await this.prisma.message.findUnique({ where: { id: messageId } });
    if (!message || message.chatId !== chat.id) throw new NotFoundException('Message not found');
    if (message.translationStatus === 'DONE' || message.translationStatus === 'SKIPPED') {
      return this.toMessageDto(message, ctx.user.id);
    }

    const translationEnabled = (await this.appSettings.get('translationEnabled')) !== 'false';
    if (!translationEnabled) return this.toMessageDto(message, ctx.user.id);

    const { driver, companyMember } = await this.resolveParties(chat);
    const isSenderDriver = message.senderUserId === driver.user.id;
    const recipientLocale = isSenderDriver ? companyMember?.user.locale : driver.user.locale;
    if (!recipientLocale) return this.toMessageDto(message, ctx.user.id);

    const { translations, status } = await this.translation.translateMessage(
      ctx.user.id,
      message.originalText,
      message.originalLang,
      recipientLocale,
    );

    const updated = await this.prisma.message.update({
      where: { id: messageId },
      data: {
        translations: Object.keys(translations).length > 0 ? { ...(message.translations as object | null), ...translations } : undefined,
        translationStatus: status,
      },
    });

    if (status === 'DONE') {
      this.realtime.emitMessageNew(chat.id, { ...this.toMessageDto(updated, null), retried: true });
    }
    return this.toMessageDto(updated, ctx.user.id);
  }

  private toMessageDto(message: { id: string; chatId: string; senderUserId: string; originalText: string; originalLang: string; translations: unknown; translationStatus: string; isRead: boolean; createdAt: Date }, viewerUserId: string | null) {
    return {
      id: message.id,
      chatId: message.chatId,
      senderUserId: message.senderUserId,
      isMine: viewerUserId != null && message.senderUserId === viewerUserId,
      originalText: message.originalText,
      originalLang: message.originalLang,
      translations: message.translations,
      translationStatus: message.translationStatus,
      isRead: message.isRead,
      createdAt: message.createdAt,
    };
  }

  /// Проставляет «прочитано» на чужих сообщениях в чате и шлёт
  /// message:read собеседнику (закрывает пробел из задачи 017, п.9:
  /// `Message.isRead` раньше никто не выставлял).
  async markRead(chatId: string, ctx: RequestContext): Promise<{ success: true }> {
    const chat = await this.loadChat(chatId, ctx);
    // «Чужие» = с другой стороны (задача 029, п.4) — см. тот же комментарий
    // в myChats(): для компании это строго водитель, не коллега, который
    // тоже писал в этот чат.
    const { driver } = await this.resolveParties(chat);
    const incomingSenderUserId = ctx.driver ? { not: driver.user.id } : driver.user.id;
    const { count } = await this.prisma.message.updateMany({
      where: { chatId, senderUserId: incomingSenderUserId, isRead: false },
      data: { isRead: true },
    });
    if (count > 0) {
      this.realtime.emitMessageRead(chatId, ctx.user.id);
    }
    return { success: true };
  }
}
