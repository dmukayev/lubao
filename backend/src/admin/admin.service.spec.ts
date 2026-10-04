import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AdminService } from './admin.service';

function fakeUploads() {
  return { presignDocumentUrl: jest.fn(async (key: string) => `https://signed.example/${key}`) };
}

describe('AdminService — city moderation (task 021)', () => {
  let prisma: any;
  let service: AdminService;

  beforeEach(() => {
    const tx = {
      driver: { updateMany: jest.fn() },
      cargo: { updateMany: jest.fn() },
      point: { updateMany: jest.fn() },
      city: { delete: jest.fn() },
    };
    prisma = {
      city: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
      __tx: tx,
    };
    service = new AdminService(prisma, { revokeAllForUser: jest.fn() } as any, fakeUploads() as any);
  });

  it('pendingCities filters by PENDING status', async () => {
    prisma.city.findMany.mockResolvedValue([]);
    await service.pendingCities();
    expect(prisma.city.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { cityStatus: 'PENDING' } }),
    );
  });

  describe('moderateCity', () => {
    it('throws NotFoundException for an unknown city id', async () => {
      prisma.city.findUnique.mockResolvedValue(null);
      await expect(service.moderateCity('missing', 'admin-1', { action: 'APPROVE' } as any)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('APPROVE requires a name and writes translated name + APPROVED status', async () => {
      prisma.city.findUnique.mockResolvedValue({ id: 'city-1' });

      await expect(service.moderateCity('city-1', 'admin-1', { action: 'APPROVE' } as any)).rejects.toThrow(
        BadRequestException,
      );

      prisma.city.update.mockResolvedValue({ id: 'city-1' });
      await service.moderateCity('city-1', 'admin-1', {
        action: 'APPROVE',
        name: { kk: 'А', ru: 'Б', zh: 'В' },
      } as any);

      expect(prisma.city.update).toHaveBeenCalledWith({
        where: { id: 'city-1' },
        data: expect.objectContaining({
          name: { kk: 'А', ru: 'Б', zh: 'В' },
          cityStatus: 'APPROVED',
          reviewedByUserId: 'admin-1',
        }),
      });
    });

    it('MERGE reassigns drivers/cargo/points to the target city and deletes the source, in a transaction', async () => {
      prisma.city.findUnique
        .mockResolvedValueOnce({ id: 'city-1' }) // the city being moderated
        .mockResolvedValueOnce({ id: 'city-2' }); // the merge target

      const result = await service.moderateCity('city-1', 'admin-1', {
        action: 'MERGE',
        mergeIntoCityId: 'city-2',
      } as any);

      expect(prisma.__tx.driver.updateMany).toHaveBeenCalledWith({
        where: { homeCityId: 'city-1' },
        data: { homeCityId: 'city-2' },
      });
      expect(prisma.__tx.cargo.updateMany).toHaveBeenCalledWith({
        where: { destinationCityId: 'city-1' },
        data: { destinationCityId: 'city-2' },
      });
      expect(prisma.__tx.point.updateMany).toHaveBeenCalledWith({
        where: { cityId: 'city-1' },
        data: { cityId: 'city-2' },
      });
      expect(prisma.__tx.city.delete).toHaveBeenCalledWith({ where: { id: 'city-1' } });
      expect(result).toEqual({ id: 'city-2' });
    });

    it('MERGE throws NotFoundException for an unknown target city', async () => {
      prisma.city.findUnique.mockResolvedValueOnce({ id: 'city-1' }).mockResolvedValueOnce(null);
      await expect(
        service.moderateCity('city-1', 'admin-1', { action: 'MERGE', mergeIntoCityId: 'missing' } as any),
      ).rejects.toThrow(NotFoundException);
    });

    it('REJECT sets status and reviewer without touching Driver rows', async () => {
      prisma.city.findUnique.mockResolvedValue({ id: 'city-1' });
      prisma.city.update.mockResolvedValue({ id: 'city-1', cityStatus: 'REJECTED' });

      await service.moderateCity('city-1', 'admin-1', { action: 'REJECT', rejectReason: 'дубликат' } as any);

      expect(prisma.city.update).toHaveBeenCalledWith({
        where: { id: 'city-1' },
        data: expect.objectContaining({ cityStatus: 'REJECTED', rejectReason: 'дубликат', reviewedByUserId: 'admin-1' }),
      });
      expect(prisma.__tx.driver.updateMany).not.toHaveBeenCalled();
    });
  });
});

describe('AdminService.searchDrivers (задача 026, п.1)', () => {
  it('paginates (default page/pageSize) and maps row fields from the nested includes', async () => {
    const prisma: any = {
      driver: {
        count: jest.fn().mockResolvedValue(42),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'd1',
            fullName: 'Ерлан',
            isVerified: true,
            ratingAvg: 4.5,
            ratingCount: 3,
            user: { phone: '+7700', isBlocked: false, createdAt: new Date('2026-01-01') },
            homeCity: { name: { ru: 'Алматы' } },
            vehicles: [{ bodyType: { name: { ru: 'Тент' } }, capacityTons: 20 }],
            verificationDocuments: [{ id: 'doc1' }],
            arrivals: [{ status: 'PLANNED', plannedAt: new Date(), arrivedAt: null }],
            _count: { deals: 7 },
          },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.searchDrivers({});

    expect(prisma.driver.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ skip: 0, take: 50 }),
    );
    expect(result.total).toBe(42);
    expect(result.items[0]).toEqual(
      expect.objectContaining({ id: 'd1', fullName: 'Ерлан', pendingDocsCount: 1, completedDeals: 7, isBlocked: false }),
    );
  });

  it('builds a case-insensitive OR search across name/phone/plate, and applies verified/blocked filters', async () => {
    const prisma: any = { driver: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.searchDrivers({ q: 'erlan', verified: true, blocked: false, page: 2, pageSize: 10 });

    const where = prisma.driver.findMany.mock.calls[0][0].where;
    expect(where.isVerified).toBe(true);
    expect(where.user).toEqual({ isBlocked: false });
    expect(where.OR).toEqual(
      expect.arrayContaining([
        { fullName: { contains: 'erlan', mode: 'insensitive' } },
        { user: { phone: { contains: 'erlan', mode: 'insensitive' } } },
      ]),
    );
    expect(prisma.driver.findMany).toHaveBeenCalledWith(expect.objectContaining({ skip: 10, take: 10 }));
  });
});

describe('AdminService.driverDetail / companyDetail — presigned document links (задача 026, п.6)', () => {
  it('driverDetail throws NotFoundException for an unknown id', async () => {
    const prisma: any = { driver: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.driverDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('driverDetail presigns every document fileUrl instead of returning the raw object key', async () => {
    const driver = {
      id: 'd1',
      userId: 'u1',
      fullName: 'Ерлан',
      anyCountry: false,
      ratingAvg: 4.2,
      ratingCount: 5,
      user: { phone: '+7700', locale: 'ru', createdAt: new Date(), isBlocked: false },
      homeCity: { name: { ru: 'Алматы' } },
      directions: [],
      permits: [],
      vehicles: [],
    };
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(driver) },
      verificationDocument: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'doc1', type: 'SELFIE', fileUrl: 'raw-object-key.jpg', status: 'PENDING', rejectReason: null, reviewedBy: null, reviewedAt: null, createdAt: new Date() },
        ]),
      },
      session: { findFirst: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]) },
      deal: { groupBy: jest.fn().mockResolvedValue([]), count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      review: { findMany: jest.fn().mockResolvedValue([]) },
      contactEvent: { count: jest.fn().mockResolvedValue(0) },
      complaint: { count: jest.fn().mockResolvedValue(0) },
      arrival: { findMany: jest.fn().mockResolvedValue([]) },
      auditLog: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const uploads = fakeUploads();
    const service = new AdminService(prisma, {} as any, uploads as any);

    const result = await service.driverDetail('d1');

    expect(uploads.presignDocumentUrl).toHaveBeenCalledWith('raw-object-key.jpg');
    expect(result.documents[0].fileUrl).toBe('https://signed.example/raw-object-key.jpg');
  });

  it('companyDetail throws NotFoundException for an unknown id', async () => {
    const prisma: any = { company: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.companyDetail('missing')).rejects.toThrow(NotFoundException);
  });
});

describe('AdminService — block/unblock (задача 026, п.5)', () => {
  it('blockUser sets isBlocked, revokes all sessions, and writes an audit_log entry with the reason', async () => {
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1' }), update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const sessions = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    const result = await service.blockUser('u1', 'admin-1', { reason: 'мошенник' });

    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'u1' }, data: { isBlocked: true } });
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'USER_BLOCKED', actorUserId: 'admin-1', entityId: 'u1', metadata: { reason: 'мошенник' } }) }),
    );
    expect(result).toEqual({ id: 'u1', isBlocked: true });
  });

  it('blockUser throws NotFoundException for an unknown user', async () => {
    const prisma: any = { user: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.blockUser('missing', 'admin-1', { reason: 'x' })).rejects.toThrow(NotFoundException);
  });

  it('unblockUser clears isBlocked and writes an audit_log entry, without touching sessions', async () => {
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1' }), update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const sessions = { revokeAllForUser: jest.fn() };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    await service.unblockUser('u1', 'admin-1', { reason: 'ошибка' });

    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'u1' }, data: { isBlocked: false } });
    expect(sessions.revokeAllForUser).not.toHaveBeenCalled();
  });

  it('blockCompany blocks the company AND every member, revoking each member\'s sessions', async () => {
    const prisma: any = {
      company: {
        findUnique: jest.fn().mockResolvedValue({ id: 'c1', members: [{ userId: 'u1' }, { userId: 'u2' }] }),
        update: jest.fn(),
      },
      user: { updateMany: jest.fn() },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const sessions = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    await service.blockCompany('c1', 'admin-1', { reason: 'жалобы' });

    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u2');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'COMPANY_BLOCKED', entityId: 'c1' }) }),
    );
  });

  it('revokeSessions revokes and logs, without touching isBlocked', async () => {
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1' }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const sessions = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    const result = await service.revokeSessions('u1', 'admin-1');

    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'SESSIONS_REVOKED' }) }),
    );
    expect(result).toEqual({ success: true });
  });
});

describe('AdminService.setDriverVerified / setCompanyVerified — force gate (задача 026, п.5)', () => {
  it('setting isVerified=true without force throws 400 when a required document is missing', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }) },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([{ type: 'SELFIE' }]) }, // missing the other 3 required types
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.setDriverVerified('d1', 'admin-1', { isVerified: true, reason: 'проверил' })).rejects.toThrow(
      BadRequestException,
    );
  });

  it('force:true bypasses the document check and writes the reason + force flag to audit_log', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }), update: jest.fn().mockResolvedValue({ id: 'd1', isVerified: true }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.setDriverVerified('d1', 'admin-1', { isVerified: true, reason: 'проверил лично', force: true });

    expect(result).toEqual({ id: 'd1', isVerified: true });
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'DRIVER_VERIFIED', metadata: { reason: 'проверил лично', force: true } }) }),
    );
  });

  it('un-verifying (isVerified=false) never requires documents', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }), update: jest.fn().mockResolvedValue({ id: 'd1', isVerified: false }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(
      service.setDriverVerified('d1', 'admin-1', { isVerified: false, reason: 'нарушение' }),
    ).resolves.toEqual({ id: 'd1', isVerified: false });
  });

  it('setCompanyVerified without force throws 400 when COMPANY_REGISTRATION is not approved', async () => {
    const prisma: any = {
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1' }) },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.setCompanyVerified('c1', 'admin-1', { isVerified: true, reason: 'x' })).rejects.toThrow(
      BadRequestException,
    );
  });
});

describe('AdminService.resetCompanyPassword — audit log (задача 026, п.5)', () => {
  it('generates a temp password, revokes sessions, and writes an audit_log entry', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
      user: { update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const sessions = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    const result = await service.resetCompanyPassword('c1', 'admin-1');

    expect(result.tempPassword).toBeTruthy();
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('owner-1');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'COMPANY_PASSWORD_RESET', entityId: 'c1' }) }),
    );
  });

  it('throws NotFoundException when the company has no owner', async () => {
    const prisma: any = { companyMember: { findFirst: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.resetCompanyPassword('c1', 'admin-1')).rejects.toThrow(NotFoundException);
  });
});

describe('AdminService.complaints — select not include, and resolved target (задача 026, п.7/п.8)', () => {
  it('queries with select (not include:true) so passwordHash can never leak', async () => {
    const prisma: any = {
      complaint: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'cp1', reporterUserId: 'u1', reporter: { id: 'u1', phone: '+7700', email: null }, targetType: 'COMPANY', targetId: 'c1', reason: 'spam', description: null, status: 'OPEN', createdAt: new Date() },
        ]),
      },
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1', name: 'Acme' }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', name: null, phone: '+7700', email: null, driver: null, companyMember: null }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.complaints();

    const call = prisma.complaint.findMany.mock.calls[0][0];
    expect(call.select).toBeDefined();
    expect(call.include).toBeUndefined();
    expect(JSON.stringify(call.select)).not.toMatch(/passwordHash/);
    expect(result[0].target).toEqual({ type: 'COMPANY', id: 'c1', title: 'Acme', companyId: 'c1' });
  });

  it('resolves a DEAL complaint target to the driver on that deal, for navigation from complaint -> driver card', async () => {
    const prisma: any = {
      complaint: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'cp1', reporterUserId: 'u1', reporter: { id: 'u1', phone: '+7700', email: null }, targetType: 'DEAL', targetId: 'deal1', reason: 'no-show', description: null, status: 'OPEN', createdAt: new Date() },
        ]),
      },
      deal: { findUnique: jest.fn().mockResolvedValue({ id: 'deal1', driverId: 'd1', companyId: 'c1', driver: { fullName: 'Ерлан' } }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', name: null, phone: '+7700', email: null, driver: null, companyMember: null }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.complaints();

    expect(result[0].target).toEqual({ type: 'DEAL', id: 'deal1', title: 'Ерлан', driverId: 'd1', companyId: 'c1' });
  });
});
