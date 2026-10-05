import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ChatsService } from './chats.service';

// Дефолты для тестов, которым перевод не важен: «выключен» (appSettings
// возвращает null → !== 'false' → true... нет, для простоты большинства
// существующих тестов перевод должен быть вне игры — appSettings.get
// возвращает 'false', чтобы send() не дёргал translation вовсе, если тест
// явно не проверяет эту логику).
const FAKE_TRANSLATION = { translateMessage: jest.fn().mockResolvedValue({ translations: {}, status: 'SKIPPED' }) };
const FAKE_APP_SETTINGS = { get: jest.fn().mockResolvedValue('false') };

function driverCtx(driverId = 'd1') {
  return { user: { id: 'u-driver', locale: 'ru' }, driver: { id: driverId }, companyMember: null } as any;
}

function companyCtx(companyId = 'c1') {
  return { user: { id: 'u-company', locale: 'ru' }, driver: null, companyMember: { companyId } } as any;
}

describe('ChatsService.findOrCreate — чат по паре водитель+компания(+груз) (задача 017, п.1)', () => {
  it('driver without cargoId is rejected — pre-deal chat always starts from a cargo card', async () => {
    const prisma: any = {};
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);
    await expect(service.findOrCreate(driverCtx(), {})).rejects.toThrow(BadRequestException);
  });

  it('driver + cargoId resolves companyId from the cargo and reuses an existing chat if one exists', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1' }) },
      chat: { findFirst: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', dealId: null }), create: jest.fn() },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'ru', phone: null } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    const result = await service.findOrCreate(driverCtx(), { cargoId: 'cargo1' });

    expect(prisma.chat.findFirst).toHaveBeenCalledWith({ where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' } });
    expect(prisma.chat.create).not.toHaveBeenCalled();
    expect(result.id).toBe('chat1');
  });

  it('company without driverId is rejected', async () => {
    const prisma: any = {};
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);
    await expect(service.findOrCreate(companyCtx(), {})).rejects.toThrow(BadRequestException);
  });

  it('company + driverId creates a cargo-less chat (general contact from "who is at the point")', async () => {
    const prisma: any = {
      chat: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'chat2', driverId: 'd1', companyId: 'c1', cargoId: null, dealId: null }) },
      deal: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'ru', phone: null } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.findOrCreate(companyCtx(), { driverId: 'd1' });

    expect(prisma.chat.create).toHaveBeenCalledWith({ data: { driverId: 'd1', companyId: 'c1', cargoId: null, dealId: null } });
  });

  it('creating a chat for a pair that already has a deal attaches dealId immediately', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1' }) },
      chat: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'chat3', driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', dealId: 'deal1' }) },
      deal: { findFirst: jest.fn().mockResolvedValue({ id: 'deal1' }) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.findOrCreate(driverCtx(), { cargoId: 'cargo1' });

    expect(prisma.chat.create).toHaveBeenCalledWith({ data: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', dealId: 'deal1' } });
  });
});

describe('ChatsService — counterpart resolution (decisions.md «Компания: проверка, роли, контакты», задача 012)', () => {
  it('for a cargo with a publishing logist, the driver sees that logist, not the owner', async () => {
    const prisma: any = {
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      cargo: { findUnique: jest.fn().mockResolvedValue({ publishedByUserId: 'logist-1' }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'zh', phone: '+86123' } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    const result = await (service as any).toThreadDto({ id: 'chat1', cargoId: 'cargo1', dealId: null, driverId: 'd1', companyId: 'c1' }, driverCtx());

    expect(prisma.companyMember.findFirst).toHaveBeenCalledWith(expect.objectContaining({ where: { userId: 'logist-1' } }));
    expect(result.counterpartPhone).toBe('+86123');
  });

  it('falls back to the oldest OWNER when the cargo has no publisher (pre-017 cargo) or the chat has no cargo at all', async () => {
    const prisma: any = {
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      cargo: { findUnique: jest.fn().mockResolvedValue({ publishedByUserId: null }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'ru', phone: '+77000000000' } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await (service as any).toThreadDto({ id: 'chat1', cargoId: 'cargo1', dealId: null, driverId: 'd1', companyId: 'c1' }, driverCtx());

    expect(prisma.companyMember.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { companyId: 'c1', role: 'OWNER' }, orderBy: { createdAt: 'asc' } }),
    );
  });
});

describe('ChatsService.myChats — логист видит чаты всей компании (decisions.md, задача 012)', () => {
  it('queries by companyId (not a single member) for a company context', async () => {
    const prisma: any = {
      chat: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.myChats(companyCtx('c1'));

    expect(prisma.chat.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { companyId: 'c1' } }));
  });

  it('queries by driverId for a driver context', async () => {
    const prisma: any = { chat: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.myChats(driverCtx('d1'));

    expect(prisma.chat.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { driverId: 'd1' } }));
  });
});

describe('ChatsService.thread/messages/send — ForbiddenException for a non-party (задача 017, п.1)', () => {
  it('thread() rejects a driver who is not a party to the chat', async () => {
    const prisma: any = { chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'other-driver', companyId: 'c1' }) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);
    await expect(service.thread('chat1', driverCtx('d1'))).rejects.toThrow(ForbiddenException);
  });

  it('throws NotFoundException for an unknown chat', async () => {
    const prisma: any = { chat: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);
    await expect(service.messages('missing', driverCtx())).rejects.toThrow(NotFoundException);
  });

  it('send() touches chat.updatedAt so "My chats" reorders, and notifies the counterpart (задача 011, CHAT_MESSAGE)', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: null }), update: jest.fn() },
      message: { create: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', senderUserId: 'u-driver', originalText: 'hi', originalLang: 'ru', translations: null, isRead: false, createdAt: new Date() }) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', name: null, locale: 'zh', phone: null } }) },
    };
    const notifications = { notify: jest.fn() };
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, notifications as any, realtime as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.send('chat1', driverCtx(), 'hi');

    expect(prisma.chat.update).toHaveBeenCalledWith({ where: { id: 'chat1' }, data: { updatedAt: expect.any(Date) } });
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['u-company'] },
      'CHAT_MESSAGE',
      expect.objectContaining({ chatId: 'chat1', senderName: 'Ерлан', preview: 'hi' }),
    );
    expect(realtime.emitMessageNew).toHaveBeenCalledWith('chat1', expect.objectContaining({ id: 'm1', senderUserId: 'u-driver', originalText: 'hi' }));
  });

  it('send() truncates a long message to an 80-char preview for the push notification', async () => {
    const longText = 'a'.repeat(200);
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: null }), update: jest.fn() },
      message: { create: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', senderUserId: 'u-driver', originalText: longText, originalLang: 'ru', translations: null, isRead: false, createdAt: new Date() }) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', name: null, locale: 'zh', phone: null } }) },
    };
    const notifications = { notify: jest.fn() };
    const service = new ChatsService(prisma, notifications as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.send('chat1', driverCtx(), longText);

    expect(notifications.notify).toHaveBeenCalledWith(
      expect.anything(),
      'CHAT_MESSAGE',
      expect.objectContaining({ preview: `${'a'.repeat(80)}…` }),
    );
  });
});

describe('ChatsService.markRead — закрывает пробел Message.isRead (задача 017 п.9, задача 011)', () => {
  function fixture() {
    return {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: null }) },
      message: { updateMany: jest.fn().mockResolvedValue({ count: 2 }) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru' } }) },
      cargo: { findUnique: jest.fn().mockResolvedValue(null) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company-a', locale: 'zh' } }) },
    };
  }

  it('driver context: marks any company member\'s messages as read (unchanged — driver has one identity)', async () => {
    const prisma: any = fixture();
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, realtime as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.markRead('chat1', driverCtx('d1'));

    expect(prisma.message.updateMany).toHaveBeenCalledWith({
      where: { chatId: 'chat1', senderUserId: { not: 'u-driver' }, isRead: false },
      data: { isRead: true },
    });
    expect(realtime.emitMessageRead).toHaveBeenCalledWith('chat1', 'u-driver');
  });

  it('company context: marks ONLY the driver\'s messages as read, never a colleague\'s (задача 029, п.4)', async () => {
    const prisma: any = fixture();
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, realtime as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    // Логист A открывает чат, где писал коллега B — старый баг
    // (senderUserId != ctx.user.id) пометил бы сообщения B прочитанными
    // просто потому, что B != A; это неверно: прочитанность отслеживает,
    // увидел ли ВОДИТЕЛЬ сообщение, а не «кто-то из компании кроме A».
    await service.markRead('chat1', companyCtx('c1'));

    expect(prisma.message.updateMany).toHaveBeenCalledWith({
      where: { chatId: 'chat1', senderUserId: 'u-driver', isRead: false },
      data: { isRead: true },
    });
  });

  it('does not emit message:read when there was nothing to mark', async () => {
    const prisma: any = fixture();
    prisma.message.updateMany.mockResolvedValue({ count: 0 });
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, realtime as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.markRead('chat1', driverCtx('d1'));

    expect(realtime.emitMessageRead).not.toHaveBeenCalled();
  });

  it('rejects a non-party', async () => {
    const prisma: any = { chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'other', companyId: 'c1' }) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await expect(service.markRead('chat1', driverCtx('d1'))).rejects.toThrow(ForbiddenException);
  });
});

describe('ChatsService.myChats — unreadCount по "чужой стороне", не по "не я" (задача 029, п.4)', () => {
  it('does not count a colleague\'s own outgoing messages as unread for a company viewer', async () => {
    const prisma: any = {
      chat: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'chat1', cargoId: null, dealId: null, driverId: 'd1', companyId: 'c1', createdAt: new Date(), messages: [], cargo: null, driver: { userId: 'u-driver' } },
        ]),
      },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company-b', locale: 'zh' } }) },
      message: { count: jest.fn().mockResolvedValue(0) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.myChats(companyCtx('c1'));

    expect(prisma.message.count).toHaveBeenCalledWith({ where: { chatId: 'chat1', isRead: false, senderUserId: 'u-driver' } });
  });

  it('for a driver viewer, counts any company-side message as unread (unchanged)', async () => {
    const prisma: any = {
      chat: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'chat1', cargoId: null, dealId: null, driverId: 'd1', companyId: 'c1', createdAt: new Date(), messages: [], cargo: null, driver: { userId: 'u-driver' } },
        ]),
      },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company-a', locale: 'zh' } }) },
      message: { count: jest.fn().mockResolvedValue(0) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.myChats(driverCtx('d1'));

    expect(prisma.message.count).toHaveBeenCalledWith({ where: { chatId: 'chat1', isRead: false, senderUserId: { not: 'u-driver' } } });
  });
});

describe('ChatsService.send — chat:updated в личные комнаты обеих сторон (задача 029, п.3)', () => {
  it('notifies both the sender and the recipient, so "My chats" updates even without an opened chat:<id> room', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: null }), update: jest.fn() },
      message: { create: jest.fn((args: any) => ({ id: 'm1', ...args.data })) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', name: null, locale: 'zh', phone: null } }) },
    };
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, realtime as any, FAKE_TRANSLATION as any, FAKE_APP_SETTINGS as any);

    await service.send('chat1', driverCtx(), 'привет');

    expect(realtime.emitChatUpdated).toHaveBeenCalledWith('u-driver', { chatId: 'chat1' });
    expect(realtime.emitChatUpdated).toHaveBeenCalledWith('u-company', { chatId: 'chat1' });
  });
});

describe('ChatsService.send — автоперевод (задача 010; в фоне — задача 029, п.6)', () => {
  function fixture() {
    return {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: null }), update: jest.fn() },
      message: { create: jest.fn((args: any) => ({ id: 'm1', ...args.data })) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', name: null, locale: 'zh', phone: null } }) },
    };
  }

  it('does not enqueue translation when the setting is off, and stores SKIPPED', async () => {
    const prisma: any = fixture();
    const translation = { enqueueTranslation: jest.fn() };
    const appSettings = { get: jest.fn().mockResolvedValue('false') };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, appSettings as any);

    await service.send('chat1', driverCtx(), 'привет');

    expect(translation.enqueueTranslation).not.toHaveBeenCalled();
    expect(prisma.message.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ translationStatus: 'SKIPPED' }) }));
  });

  it('does not enqueue translation when sender and recipient already share a locale', async () => {
    const prisma: any = fixture();
    prisma.companyMember.findFirst.mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', name: null, locale: 'ru', phone: null } });
    const translation = { enqueueTranslation: jest.fn() };
    const appSettings = { get: jest.fn().mockResolvedValue(null) };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, appSettings as any);

    await service.send('chat1', driverCtx(), 'привет');

    expect(translation.enqueueTranslation).not.toHaveBeenCalled();
    expect(prisma.message.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ translationStatus: 'SKIPPED' }) }));
  });

  it('stores the message as PENDING immediately and enqueues translation — does not wait for a result (задача 029, п.6)', async () => {
    const prisma: any = fixture();
    const translation = { enqueueTranslation: jest.fn().mockResolvedValue(undefined) };
    const appSettings = { get: jest.fn().mockResolvedValue(null) };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, appSettings as any);

    const result = await service.send('chat1', driverCtx(), 'привет');

    expect(prisma.message.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ translationStatus: 'PENDING' }) }),
    );
    expect(prisma.message.create.mock.calls[0][0].data).not.toHaveProperty('translations');
    expect(translation.enqueueTranslation).toHaveBeenCalledWith({
      messageId: 'm1',
      chatId: 'chat1',
      text: 'привет',
      from: 'ru',
      to: 'zh',
      senderUserId: 'u-driver',
    });
    expect(result.translationStatus).toBe('PENDING');
  });
});

describe('ChatsService.retryTranslation (задача 010, п.7)', () => {
  it('re-translates and broadcasts message:new on success', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: {
        findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', senderUserId: 'u-driver', originalText: 'привет', originalLang: 'ru', translations: null, translationStatus: 'FAILED', isRead: false, createdAt: new Date() }),
        update: jest.fn((args: any) => ({ id: 'm1', chatId: 'chat1', senderUserId: 'u-driver', originalText: 'привет', originalLang: 'ru', isRead: false, createdAt: new Date(), ...args.data })),
      },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', locale: 'zh' } }) },
    };
    const translation = { translateMessage: jest.fn().mockResolvedValue({ translations: { zh: '你好' }, status: 'DONE' }) };
    const realtime = { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, realtime as any, translation as any, { get: jest.fn() } as any);

    const result = await service.retryTranslation('chat1', 'm1', driverCtx());

    expect(translation.translateMessage).toHaveBeenCalledWith('u-driver', 'привет', 'ru', 'zh');
    expect(prisma.message.update).toHaveBeenCalledWith({
      where: { id: 'm1' },
      data: { translations: { zh: '你好' }, translationStatus: 'DONE' },
    });
    expect(realtime.emitMessageNew).toHaveBeenCalled();
    expect(result.translationStatus).toBe('DONE');
  });

  it('throws NotFoundException for a message that does not belong to this chat', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: { findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'other-chat' }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, { translateMessage: jest.fn() } as any, { get: jest.fn() } as any);

    await expect(service.retryTranslation('chat1', 'm1', driverCtx())).rejects.toThrow(NotFoundException);
  });

  it('does not re-translate a message that is already DONE (задача 029, п.20)', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: { findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', translationStatus: 'DONE' }) },
    };
    const translation = { translateMessage: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, { get: jest.fn() } as any);

    await service.retryTranslation('chat1', 'm1', driverCtx());

    expect(translation.translateMessage).not.toHaveBeenCalled();
  });

  it('does not re-translate a message that is SKIPPED (same language, or translation was off at send time)', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: { findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', translationStatus: 'SKIPPED' }) },
    };
    const translation = { translateMessage: jest.fn() };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, { get: jest.fn() } as any);

    await service.retryTranslation('chat1', 'm1', driverCtx());

    expect(translation.translateMessage).not.toHaveBeenCalled();
  });

  it('does not re-translate when the "Перевод выкл." setting is off', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: { findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', translationStatus: 'FAILED' }) },
    };
    const translation = { translateMessage: jest.fn() };
    const appSettings = { get: jest.fn().mockResolvedValue('false') };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, appSettings as any);

    await service.retryTranslation('chat1', 'm1', driverCtx());

    expect(translation.translateMessage).not.toHaveBeenCalled();
  });

  it('counts the rate limit against whoever clicked retry, not the original sender (задача 029, п.20)', async () => {
    const prisma: any = {
      chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1' }) },
      message: {
        findUnique: jest.fn().mockResolvedValue({ id: 'm1', chatId: 'chat1', senderUserId: 'u-company', originalText: 'hi', originalLang: 'zh', translationStatus: 'FAILED' }),
        update: jest.fn((args: any) => ({ id: 'm1', chatId: 'chat1', senderUserId: 'u-company', ...args.data })),
      },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { id: 'u-driver', locale: 'ru' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { id: 'u-company', locale: 'zh' } }) },
    };
    const translation = { translateMessage: jest.fn().mockResolvedValue({ translations: { ru: 'привет' }, status: 'DONE' }) };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any, { emitMessageNew: jest.fn(), emitMessageRead: jest.fn(), emitChatUpdated: jest.fn() } as any, translation as any, { get: jest.fn() } as any);

    // Отправитель сообщения — логист (u-company), но RETRY нажимает
    // водитель (driverCtx -> u-driver) — лимит должен считаться на него.
    await service.retryTranslation('chat1', 'm1', driverCtx());

    expect(translation.translateMessage).toHaveBeenCalledWith('u-driver', 'hi', 'zh', 'ru');
  });
});
