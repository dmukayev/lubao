import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ChatsService } from './chats.service';

function driverCtx(driverId = 'd1') {
  return { user: { id: 'u-driver', locale: 'ru' }, driver: { id: driverId }, companyMember: null } as any;
}

function companyCtx(companyId = 'c1') {
  return { user: { id: 'u-company', locale: 'ru' }, driver: null, companyMember: { companyId } } as any;
}

describe('ChatsService.findOrCreate — чат по паре водитель+компания(+груз) (задача 017, п.1)', () => {
  it('driver without cargoId is rejected — pre-deal chat always starts from a cargo card', async () => {
    const prisma: any = {};
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);
    await expect(service.findOrCreate(driverCtx(), {})).rejects.toThrow(BadRequestException);
  });

  it('driver + cargoId resolves companyId from the cargo and reuses an existing chat if one exists', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1' }) },
      chat: { findFirst: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', dealId: null }), create: jest.fn() },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'ru', phone: null } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

    const result = await service.findOrCreate(driverCtx(), { cargoId: 'cargo1' });

    expect(prisma.chat.findFirst).toHaveBeenCalledWith({ where: { driverId: 'd1', companyId: 'c1', cargoId: 'cargo1' } });
    expect(prisma.chat.create).not.toHaveBeenCalled();
    expect(result.id).toBe('chat1');
  });

  it('company without driverId is rejected', async () => {
    const prisma: any = {};
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);
    await expect(service.findOrCreate(companyCtx(), {})).rejects.toThrow(BadRequestException);
  });

  it('company + driverId creates a cargo-less chat (general contact from "who is at the point")', async () => {
    const prisma: any = {
      chat: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'chat2', driverId: 'd1', companyId: 'c1', cargoId: null, dealId: null }) },
      deal: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: { findUniqueOrThrow: jest.fn().mockResolvedValue({ fullName: 'Ерлан', user: { locale: 'ru', phone: '+7700' } }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ company: { name: 'Acme' }, user: { locale: 'ru', phone: null } }) },
    };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

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
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

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
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

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
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

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
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

    await service.myChats(companyCtx('c1'));

    expect(prisma.chat.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { companyId: 'c1' } }));
  });

  it('queries by driverId for a driver context', async () => {
    const prisma: any = { chat: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);

    await service.myChats(driverCtx('d1'));

    expect(prisma.chat.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { driverId: 'd1' } }));
  });
});

describe('ChatsService.thread/messages/send — ForbiddenException for a non-party (задача 017, п.1)', () => {
  it('thread() rejects a driver who is not a party to the chat', async () => {
    const prisma: any = { chat: { findUnique: jest.fn().mockResolvedValue({ id: 'chat1', driverId: 'other-driver', companyId: 'c1' }) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);
    await expect(service.thread('chat1', driverCtx('d1'))).rejects.toThrow(ForbiddenException);
  });

  it('throws NotFoundException for an unknown chat', async () => {
    const prisma: any = { chat: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new ChatsService(prisma, { notify: jest.fn() } as any);
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
    const service = new ChatsService(prisma, notifications as any);

    await service.send('chat1', driverCtx(), 'hi');

    expect(prisma.chat.update).toHaveBeenCalledWith({ where: { id: 'chat1' }, data: { updatedAt: expect.any(Date) } });
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['u-company'] },
      'CHAT_MESSAGE',
      expect.objectContaining({ chatId: 'chat1', senderName: 'Ерлан', preview: 'hi' }),
    );
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
    const service = new ChatsService(prisma, notifications as any);

    await service.send('chat1', driverCtx(), longText);

    expect(notifications.notify).toHaveBeenCalledWith(
      expect.anything(),
      'CHAT_MESSAGE',
      expect.objectContaining({ preview: `${'a'.repeat(80)}…` }),
    );
  });
});
