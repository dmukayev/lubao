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
    service = new CompaniesService(prisma);
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

describe('CompaniesService.setPassword', () => {
  it('hashes the password and stores it on the user', async () => {
    const prisma = { user: { update: jest.fn().mockResolvedValue(undefined) } };
    const service = new CompaniesService(prisma as any);

    await service.setPassword('user-1', 'super-secret-1');

    expect(prisma.user.update).toHaveBeenCalledTimes(1);
    const { where, data } = prisma.user.update.mock.calls[0][0];
    expect(where).toEqual({ id: 'user-1' });
    expect(data.passwordHash).not.toBe('super-secret-1');
    await expect(bcrypt.compare('super-secret-1', data.passwordHash)).resolves.toBe(true);
  });
});
