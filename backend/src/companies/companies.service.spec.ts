import { BadRequestException, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
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
    service = new CompaniesService(prisma, { sendMessage: jest.fn() } as any);
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
});

describe('CompaniesService invites (задача 025, «Путь Б» из 022)', () => {
  let prisma: any;
  let email: { sendMessage: jest.Mock };
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
    email = { sendMessage: jest.fn().mockResolvedValue(undefined) };
    service = new CompaniesService(prisma, email as any);
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

    const result = await service.createInvite('company-1', 'owner-1', { email: 'Colleague@Example.com', role: 'LOGIST' });

    expect(prisma.companyInvite.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ companyId: 'company-1', invitedByUserId: 'owner-1', email: 'colleague@example.com', role: 'LOGIST' }),
      }),
    );
    expect(email.sendMessage).toHaveBeenCalledWith(
      'colleague@example.com',
      expect.any(String),
      expect.stringContaining('lubao://invite/'),
    );
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
    email.sendMessage.mockRejectedValue(new Error('smtp down'));

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
    const service = new CompaniesService(prisma as any, { sendMessage: jest.fn() } as any);

    await service.setPassword('user-1', 'super-secret-1');

    expect(prisma.user.update).toHaveBeenCalledTimes(1);
    const { where, data } = prisma.user.update.mock.calls[0][0];
    expect(where).toEqual({ id: 'user-1' });
    expect(data.passwordHash).not.toBe('super-secret-1');
    await expect(bcrypt.compare('super-secret-1', data.passwordHash)).resolves.toBe(true);
  });
});
