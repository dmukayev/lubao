import { BadRequestException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Prisma } from '@prisma/client';
import { CompaniesService } from './companies.service';

describe('CompaniesService.registerOwnedCompany', () => {
  let prisma: any;
  let service: CompaniesService;

  beforeEach(() => {
    prisma = {
      companyMember: { findUnique: jest.fn() },
      country: { findUnique: jest.fn() },
      $transaction: jest.fn(async (fn) =>
        fn({
          company: { create: jest.fn().mockResolvedValue({ id: 'company-1', name: 'Yidao', nameRu: 'Идао' }) },
          companyMember: { create: jest.fn().mockResolvedValue({ id: 'member-1', companyId: 'company-1', userId: 'user-1', role: 'OWNER' }) },
          user: { update: jest.fn().mockResolvedValue(undefined) },
        }),
      ),
    };
    service = new CompaniesService(prisma, { sendMessage: jest.fn() } as any, { send: jest.fn() } as any);
  });

  it('rejects a user who already belongs to a company', async () => {
    prisma.companyMember.findUnique.mockResolvedValue({ id: 'existing' });
    await expect(
      service.registerOwnedCompany('user-1', { ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects an unknown countryId', async () => {
    prisma.companyMember.findUnique.mockResolvedValue(null);
    prisma.country.findUnique.mockResolvedValue(null);
    await expect(
      service.registerOwnedCompany('user-1', { ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'missing' }),
    ).rejects.toThrow(NotFoundException);
  });

  it('creates Company + OWNER CompanyMember and sets the owner name, in one transaction', async () => {
    prisma.companyMember.findUnique.mockResolvedValue(null);
    prisma.country.findUnique.mockResolvedValue({ id: 'cn-1', code: 'CN' });

    const result = await service.registerOwnedCompany('user-1', {
      ownerName: 'Ли Вэй',
      companyName: 'Yidao',
      companyNameRu: 'Идао',
      countryId: 'cn-1',
    });

    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(result.company).toEqual(expect.objectContaining({ id: 'company-1', name: 'Yidao', nameRu: 'Идао' }));
    expect(result.companyMember).toEqual(expect.objectContaining({ role: 'OWNER', userId: 'user-1' }));
  });

  it('falls back companyNameRu to companyName when not provided', async () => {
    prisma.companyMember.findUnique.mockResolvedValue(null);
    prisma.country.findUnique.mockResolvedValue({ id: 'cn-1', code: 'CN' });

    let capturedData: any;
    prisma.$transaction.mockImplementation(async (fn: any) =>
      fn({
        company: {
          create: jest.fn((args: any) => {
            capturedData = args.data;
            return Promise.resolve({ id: 'company-1', ...args.data });
          }),
        },
        companyMember: { create: jest.fn().mockResolvedValue({ id: 'member-1', role: 'OWNER', userId: 'user-1', companyId: 'company-1' }) },
        user: { update: jest.fn().mockResolvedValue(undefined) },
      }),
    );

    await service.registerOwnedCompany('user-1', { ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' });
    expect(capturedData.nameRu).toBe('Yidao');
  });

  it('turns a P2002 unique-constraint race on CompanyMember.userId into 400, not 500 (024 п.7)', async () => {
    // Два параллельных запроса оба проходят findUnique (ещё никого нет),
    // но второй падает внутри транзакции на уникальном userId — это
    // единственное место, где гонка реально проявляется.
    prisma.companyMember.findUnique.mockResolvedValue(null);
    prisma.country.findUnique.mockResolvedValue({ id: 'cn-1', code: 'CN' });
    prisma.$transaction.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique constraint failed on the fields: (`userId`)', {
        code: 'P2002',
        clientVersion: '5.22.0',
      }),
    );

    await expect(
      service.registerOwnedCompany('user-1', { ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' }),
    ).rejects.toThrow(BadRequestException);
  });
});

describe('CompaniesService invites (задача 025, «Путь Б» из 022)', () => {
  let prisma: any;
  let email: { sendMessage: jest.Mock; sendTemplate: jest.Mock };
  let service: CompaniesService;

  beforeEach(() => {
    prisma = {
      companyInvite: {
        create: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      user: { findUnique: jest.fn(), create: jest.fn() },
      companyMember: { create: jest.fn() },
      company: { findUniqueOrThrow: jest.fn() },
      $transaction: jest.fn(async (fn: any) =>
        fn({
          user: { create: jest.fn().mockResolvedValue({ id: 'user-2', role: 'COMPANY', email: 'colleague@example.com' }) },
          companyMember: {
            create: jest.fn().mockResolvedValue({ id: 'member-2', companyId: 'company-1', userId: 'user-2', role: 'LOGIST' }),
          },
          companyInvite: { update: jest.fn().mockResolvedValue(undefined) },
        }),
      ),
    };
    email = { sendMessage: jest.fn().mockResolvedValue(undefined), sendTemplate: jest.fn().mockResolvedValue(undefined) };
    service = new CompaniesService(prisma, email as any, { send: jest.fn() } as any);
  });

  it('createInvite generates a unique token, stores it with a 7-day expiry, and emails the link', async () => {
    prisma.companyInvite.create.mockResolvedValue({
      id: 'invite-1',
      email: 'colleague@example.com',
      role: 'LOGIST',
      token: 'abc123',
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      company: { name: 'Yidao' },
    });
    prisma.user.findUnique.mockResolvedValue({ locale: 'zh' });

    const result = await service.createInvite('company-1', 'owner-1', { email: 'Colleague@Example.com', role: 'LOGIST' });

    expect(prisma.companyInvite.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ companyId: 'company-1', invitedByUserId: 'owner-1', email: 'colleague@example.com', role: 'LOGIST' }),
      }),
    );
    // 042, п.2: https-ссылка вместо lubao://, письмо на языке пригласившего.
    expect(email.sendTemplate).toHaveBeenCalledWith('colleague@example.com', 'INVITE', 'zh', {
      company: 'Yidao',
      days: 7,
      link: expect.stringMatching(/^https:\/\/app\.lubao\.kz\/invite\/[0-9a-f]{48}$/),
    });
    expect(result.token).toBe('abc123');
  });

  it('createInvite does not fail if sending the email throws', async () => {
    prisma.companyInvite.create.mockResolvedValue({
      id: 'invite-1',
      email: 'colleague@example.com',
      role: 'LOGIST',
      token: 'abc123',
      expiresAt: new Date(),
      company: { name: 'Yidao' },
    });
    email.sendTemplate.mockRejectedValue(new Error('smtp down'));

    await expect(service.createInvite('company-1', 'owner-1', { email: 'colleague@example.com', role: 'LOGIST' })).resolves.toEqual(
      expect.objectContaining({ token: 'abc123' }),
    );
  });

  it('getInvite rejects an expired invite', async () => {
    prisma.companyInvite.findUnique.mockResolvedValue({
      id: 'invite-1',
      token: 'abc123',
      usedAt: null,
      expiresAt: new Date(Date.now() - 1000),
      company: { name: 'Yidao' },
      role: 'LOGIST',
      email: 'colleague@example.com',
    });
    await expect(service.getInvite('abc123')).rejects.toThrow(NotFoundException);
  });

  it('getInvite rejects an already-used invite', async () => {
    prisma.companyInvite.findUnique.mockResolvedValue({
      id: 'invite-1',
      token: 'abc123',
      usedAt: new Date(),
      expiresAt: new Date(Date.now() + 1000),
      company: { name: 'Yidao' },
      role: 'LOGIST',
      email: 'colleague@example.com',
    });
    await expect(service.getInvite('abc123')).rejects.toThrow(NotFoundException);
  });

  it('getInvite returns company name, role, and email for a valid invite', async () => {
    prisma.companyInvite.findUnique.mockResolvedValue({
      id: 'invite-1',
      token: 'abc123',
      usedAt: null,
      expiresAt: new Date(Date.now() + 1000),
      company: { name: 'Yidao' },
      role: 'LOGIST',
      email: 'colleague@example.com',
    });
    await expect(service.getInvite('abc123')).resolves.toEqual({
      companyName: 'Yidao',
      role: 'LOGIST',
      email: 'colleague@example.com',
    });
  });

  it('acceptInvite rejects an email that is already registered', async () => {
    prisma.companyInvite.findUnique.mockResolvedValue({
      id: 'invite-1',
      token: 'abc123',
      usedAt: null,
      expiresAt: new Date(Date.now() + 1000),
      email: 'colleague@example.com',
      companyId: 'company-1',
      role: 'LOGIST',
    });
    prisma.user.findUnique.mockResolvedValue({ id: 'existing' });

    await expect(service.acceptInvite('abc123', { password: 'password1', name: 'Ли Вэй' })).rejects.toThrow(
      BadRequestException,
    );
  });

  it('acceptInvite creates the user with the invited role, marks the invite used, and confirms the email', async () => {
    prisma.companyInvite.findUnique.mockResolvedValue({
      id: 'invite-1',
      token: 'abc123',
      usedAt: null,
      expiresAt: new Date(Date.now() + 1000),
      email: 'colleague@example.com',
      companyId: 'company-1',
      role: 'LOGIST',
    });
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.company.findUniqueOrThrow.mockResolvedValue({ id: 'company-1', name: 'Yidao', nameRu: 'Идао' });

    const result = await service.acceptInvite('abc123', { password: 'password1', name: 'Ли Вэй' });

    expect(result.user.email).toBe('colleague@example.com');
    expect(result.companyMember).toEqual(expect.objectContaining({ role: 'LOGIST', companyId: 'company-1' }));
  });
});

describe('CompaniesService.setPassword', () => {
  it('hashes the password and stores it on the user', async () => {
    const prisma = { user: { update: jest.fn().mockResolvedValue(undefined) } };
    const service = new CompaniesService(prisma as any, { sendMessage: jest.fn() } as any, { send: jest.fn() } as any);

    await service.setPassword('user-1', 'super-secret-1');

    expect(prisma.user.update).toHaveBeenCalledTimes(1);
    const { where, data } = prisma.user.update.mock.calls[0][0];
    expect(where).toEqual({ id: 'user-1' });
    expect(data.passwordHash).not.toBe('super-secret-1');
    await expect(bcrypt.compare('super-secret-1', data.passwordHash)).resolves.toBe(true);
  });
});

describe('CompaniesService WeCom webhook (задача 011, п.2)', () => {
  it('updateWeComWebhook stores the url and returns it in the company dto', async () => {
    const prisma = {
      company: {
        update: jest.fn().mockResolvedValue({
          id: 'company-1',
          name: 'Yidao',
          nameRu: null,
          countryId: 'cn-1',
          city: null,
          isVerified: true,
          wecomWebhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc',
          ratingAvg: 0,
          ratingCount: 0,
        }),
      },
    };
    const service = new CompaniesService(prisma as any, { sendMessage: jest.fn() } as any, { send: jest.fn() } as any);

    const result = await service.updateWeComWebhook('company-1', 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc');

    expect(prisma.company.update).toHaveBeenCalledWith({
      where: { id: 'company-1' },
      data: { wecomWebhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc' },
    });
    expect(result.wecomWebhookUrl).toBe('https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc');
  });

  it('testWeComWebhook rejects when no webhook is configured', async () => {
    const prisma = { company: { findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'company-1', name: 'Yidao', wecomWebhookUrl: null }) } };
    const wecom = { send: jest.fn() };
    const service = new CompaniesService(prisma as any, { sendMessage: jest.fn() } as any, wecom as any);

    await expect(service.testWeComWebhook('company-1')).rejects.toThrow(BadRequestException);
    expect(wecom.send).not.toHaveBeenCalled();
  });

  it('testWeComWebhook sends a test message through WeComService', async () => {
    const prisma = {
      company: { findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'company-1', name: 'Yidao', wecomWebhookUrl: 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key-123' }) },
    };
    const wecom = { send: jest.fn().mockResolvedValue(undefined) };
    const service = new CompaniesService(prisma as any, { sendMessage: jest.fn() } as any, wecom as any);

    const result = await service.testWeComWebhook('company-1');

    expect(wecom.send).toHaveBeenCalledWith('https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=test-key-123', expect.stringContaining('Yidao'));
    expect(result).toEqual({ success: true });
  });
});

describe('CompaniesService.updateProfile — рег. номер по стране (задача 012, п. «Обязательные поля»)', () => {
  function fixture(countryCode: string) {
    return {
      company: {
        findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'c1', countryId: 'cn-1', country: { code: countryCode } }),
        update: jest.fn((args: any) => Promise.resolve({ id: 'c1', name: 'Yidao', nameRu: 'Идао', countryId: 'cn-1', ratingAvg: 0, ratingCount: 0, isVerified: false, wecomWebhookUrl: null, ...args.data })),
      },
    };
  }

  it('accepts an 18-char alnum 统一社会信用代码 for a Chinese company', async () => {
    const prisma = fixture('CN');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await expect(service.updateProfile('c1', { taxId: '91330000MA2B1C2D3E' })).resolves.toEqual(
      expect.objectContaining({ taxId: '91330000MA2B1C2D3E' }),
    );
  });

  it('rejects a too-short registration number for a Chinese company', async () => {
    const prisma = fixture('CN');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await expect(service.updateProfile('c1', { taxId: '123' })).rejects.toThrow(BadRequestException);
  });

  it('accepts a 12-digit БИН for a Kazakhstani company', async () => {
    const prisma = fixture('KZ');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await expect(service.updateProfile('c1', { taxId: '123456789012' })).resolves.toEqual(
      expect.objectContaining({ taxId: '123456789012' }),
    );
  });

  it('rejects a БИН that is not exactly 12 digits', async () => {
    const prisma = fixture('KZ');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await expect(service.updateProfile('c1', { taxId: '12345' })).rejects.toThrow(BadRequestException);
  });

  it('does not require a format for a country without a defined rule — any non-empty string passes', async () => {
    const prisma = fixture('RU');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await expect(service.updateProfile('c1', { taxId: 'anything-non-empty' })).resolves.toEqual(
      expect.objectContaining({ taxId: 'anything-non-empty' }),
    );
  });

  it('city/legalAddress update without taxId does not run the format check', async () => {
    const prisma = fixture('CN');
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await service.updateProfile('c1', { city: 'Урумчи' });

    expect(prisma.company.update).toHaveBeenCalledWith({ where: { id: 'c1' }, data: { city: 'Урумчи', legalAddress: undefined, taxId: undefined } });
  });
});

describe('CompaniesService.updateMyContact — «Мой профиль» сотрудника (задача 012, п.1/8)', () => {
  it('updates fullName/contactPhone/wechatId for the calling member, by userId', async () => {
    const prisma = {
      companyMember: {
        update: jest.fn().mockResolvedValue({ id: 'm1', companyId: 'c1', userId: 'u1', role: 'LOGIST', fullName: 'Ли Вэй', contactPhone: '+86123', wechatId: 'liwei88' }),
      },
    };
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    const result = await service.updateMyContact('u1', { fullName: 'Ли Вэй', contactPhone: '+86123', wechatId: 'liwei88' });

    expect(prisma.companyMember.update).toHaveBeenCalledWith({
      where: { userId: 'u1' },
      data: { fullName: 'Ли Вэй', contactPhone: '+86123', wechatId: 'liwei88' },
    });
    expect(result.fullName).toBe('Ли Вэй');
  });
});

describe('CompaniesService verification documents — компания подтверждается одним документом (задача 012, п.5)', () => {
  it('submitVerificationDocument creates a PENDING document tied to the company, not a driver', async () => {
    const prisma = {
      verificationDocument: {
        create: jest.fn().mockResolvedValue({ id: 'doc1', type: 'COMPANY_REGISTRATION', fileUrl: 'key.jpg', status: 'PENDING', rejectReason: null, createdAt: new Date() }),
      },
    };
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await service.submitVerificationDocument('u1', 'c1', { type: 'COMPANY_REGISTRATION', fileUrl: 'key.jpg' });

    expect(prisma.verificationDocument.create).toHaveBeenCalledWith({
      data: { userId: 'u1', companyId: 'c1', type: 'COMPANY_REGISTRATION', fileUrl: 'key.jpg', status: 'PENDING' },
    });
  });

  it('listVerificationDocuments returns only this company\'s documents, newest first', async () => {
    const prisma = { verificationDocument: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new CompaniesService(prisma as any, {} as any, {} as any);

    await service.listVerificationDocuments('c1');

    expect(prisma.verificationDocument.findMany).toHaveBeenCalledWith({ where: { companyId: 'c1' }, orderBy: { createdAt: 'desc' } });
  });
});
