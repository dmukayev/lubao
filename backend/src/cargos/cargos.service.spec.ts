import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { CargosService } from './cargos.service';

function baseCargo(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'cargo1',
    companyId: 'c1',
    publishedByUserId: null,
    publishedBy: null,
    pointId: 'p1',
    destinationCountryId: 'kz',
    destinationCityId: null,
    bodyTypeId: 'bt1',
    weightKg: null,
    volumeM3: null,
    photoUrls: [],
    price: 100,
    currency: 'USD',
    readyDate: new Date(),
    description: null,
    status: 'PUBLISHED',
    publishedAt: new Date(),
    expiresAt: new Date(),
    archivedAt: null,
    closeOutcome: null,
    closedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    company: { name: 'Acme', isVerified: true, ratingAvg: 4.5, ratingCount: 3, country: { code: 'KZ' } },
    ...overrides,
  };
}

describe('CargosService — logist contact resolution (задача 017, decisions.md «Компания: проверка, роли, контакты»)', () => {
  it('uses the publishing logist when the cargo has one', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: { id: 'logist1', name: 'Ли Вэй', phone: '+86123' } })) },
      deal: { count: jest.fn().mockResolvedValue(0) },
    };
    const service = new CargosService(prisma, {} as any);

    const result = await service.byId('cargo1');

    expect(result.contactUserId).toBe('logist1');
    expect(result.contactPhone).toBe('+86123');
  });

  it('falls back to the oldest OWNER when the cargo predates publishedByUserId', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: null })) },
      deal: { count: jest.fn().mockResolvedValue(0) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ user: { id: 'owner1', name: 'Owner', phone: '+77001112233' } }) },
    };
    const service = new CargosService(prisma, {} as any);

    const result = await service.byId('cargo1');

    expect(prisma.companyMember.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { companyId: 'c1', role: 'OWNER' }, orderBy: { createdAt: 'asc' } }),
    );
    expect(result.contactUserId).toBe('owner1');
  });

  it('flags isWhatsappBlocked for a China-based company', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ company: { name: 'Acme CN', isVerified: true, ratingAvg: 5, ratingCount: 1, country: { code: 'CN' } } })) },
      deal: { count: jest.fn().mockResolvedValue(0) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new CargosService(prisma, {} as any);

    const result = await service.byId('cargo1');
    expect(result.isWhatsappBlocked).toBe(true);
  });
});

describe('CargosService.closeCargo — закрытие только с исходом (задача 017, п.6)', () => {
  it('refuses to close a cargo that is already closed', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ status: 'CANCELLED' })) } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_OUTSIDE' } as any)).rejects.toThrow(BadRequestException);
  });

  it('FOUND_IN_APP without driverId throws', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()) } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP' } as any)).rejects.toThrow(BadRequestException);
  });

  it('FOUND_IN_APP invites the driver (creating the deal) and marks the cargo CANCELLED with the outcome', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const responses = { inviteDriver: jest.fn() };
    const service = new CargosService(prisma, responses as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP', driverId: 'd1' } as any);

    expect(responses.inviteDriver).toHaveBeenCalledWith('cargo1', 'd1', 'c1');
    expect(prisma.cargo.update).toHaveBeenCalledWith({
      where: { id: 'cargo1' },
      data: { status: 'CANCELLED', closeOutcome: 'FOUND_IN_APP', closedAt: expect.any(Date) },
    });
  });

  it('FOUND_IN_APP does not re-invite a driver whose response is already SELECTED (deal already exists)', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'SELECTED' }) },
    };
    const responses = { inviteDriver: jest.fn() };
    const service = new CargosService(prisma, responses as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP', driverId: 'd1' } as any);

    expect(responses.inviteDriver).not.toHaveBeenCalled();
    expect(prisma.cargo.update).toHaveBeenCalled();
  });

  it('FOUND_OUTSIDE and CARGO_CANCELLED just close the cargo, no invite', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() } };
    const responses = { inviteDriver: jest.fn() };
    const service = new CargosService(prisma, responses as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_OUTSIDE' } as any);

    expect(responses.inviteDriver).not.toHaveBeenCalled();
    expect(prisma.cargo.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ closeOutcome: 'FOUND_OUTSIDE' }) }));
  });
});

describe('CargosService.closeCandidates — union of responses/contacts/chats (задача 017, п.6)', () => {
  it('deduplicates a driver who appears via multiple sources', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()) },
      response: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd1', driver: { fullName: 'Ерлан' } }]) },
      contactEvent: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd1', driver: { fullName: 'Ерлан' } }]) },
      chat: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd2', driver: { fullName: 'Нурлан' } }]) },
    };
    const service = new CargosService(prisma, {} as any);

    const result = await service.closeCandidates('c1', 'cargo1');

    expect(result).toEqual([{ driverId: 'd1', driverName: 'Ерлан' }, { driverId: 'd2', driverName: 'Нурлан' }]);
  });
});

describe('CargosService.feed — hides blocked companies\' cargo (задача 026, п.5)', () => {
  it('filters by company.isBlocked: false, without touching cargo status', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { count: jest.fn() },
    };
    const service = new CargosService(prisma, {} as any);

    await service.feed();

    expect(prisma.cargo.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'PUBLISHED', company: { isBlocked: false } } }),
    );
  });
});

describe('CargosService.create — непроверенная компания не публикует грузы (задача 012, п.4)', () => {
  it('throws COMPANY_NOT_VERIFIED when the company is not verified, without touching the database', async () => {
    const prisma: any = { point: { findFirstOrThrow: jest.fn() }, cargo: { create: jest.fn() } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.create('c1', 'u1', false, { readyDate: '2026-01-01' } as any)).rejects.toThrow(ForbiddenException);
    expect(prisma.point.findFirstOrThrow).not.toHaveBeenCalled();
    expect(prisma.cargo.create).not.toHaveBeenCalled();
  });

  it('a verified company publishes normally', async () => {
    const prisma: any = {
      point: { findFirstOrThrow: jest.fn().mockResolvedValue({ id: 'p1' }) },
      cargo: { create: jest.fn().mockResolvedValue(baseCargo()) },
      deal: { count: jest.fn().mockResolvedValue(0) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new CargosService(prisma, {} as any);

    await service.create('c1', 'u1', true, { readyDate: '2026-01-01', destinationCountryId: 'kz', bodyTypeId: 'bt1', price: 100, currency: 'USD' } as any);

    expect(prisma.cargo.create).toHaveBeenCalled();
  });
});

describe('CargosService.assertCanEdit — логист редактирует только свой груз, владелец — любой (задача 012, п.6)', () => {
  it('the OWNER can edit a cargo published by a colleague', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'owner-1', 'OWNER')).resolves.toBeDefined();
  });

  it('a LOGIST cannot edit a colleague\'s cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'logist-2', 'LOGIST')).rejects.toThrow(ForbiddenException);
  });

  it('a LOGIST can edit their own cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'logist-1', 'LOGIST')).resolves.toBeDefined();
  });
});
