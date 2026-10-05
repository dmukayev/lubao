import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { AdminService } from './admin.service';

function fakeUploads() {
  return {
    presignDocumentUrl: jest.fn(async (key: string) => `https://signed.example/${key}`),
    getDocumentStream: jest.fn(async (key: string) => ({ stream: `stream:${key}`, contentType: 'image/jpeg' })),
  };
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

describe('AdminService.driverDetail / companyDetail — document links go through the CORS proxy (задача 029, п.15)', () => {
  it('driverDetail throws NotFoundException for an unknown id', async () => {
    const prisma: any = { driver: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.driverDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('driverDetail returns the backend proxy path for every document, never a presigned MinIO URL directly', async () => {
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

    // Задача 029, п.15 — карточка водителя грузила presigned MinIO URL
    // напрямую (CORS), а не через /admin/documents/:id/file, как уже было
    // исправлено на экране проверки.
    expect(uploads.presignDocumentUrl).not.toHaveBeenCalled();
    expect(result.documents[0].fileUrl).toBe('/admin/documents/doc1/file');
  });

  it('companyDetail throws NotFoundException for an unknown id', async () => {
    const prisma: any = { company: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.companyDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('companyDetail returns the backend proxy path for every document too (задача 029, п.15)', async () => {
    const company = {
      id: 'c1',
      name: { ru: 'Acme' },
      nameRu: 'Acme',
      countryId: 'kz',
      country: { name: { ru: 'Казахстан' } },
      city: 'Алматы',
      legalAddress: null,
      taxId: '123',
      isVerified: false,
      isBlocked: false,
      ratingAvg: 0,
      ratingCount: 0,
    };
    const prisma: any = {
      company: { findUnique: jest.fn().mockResolvedValue(company) },
      verificationDocument: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'doc1', type: 'COMPANY_REGISTRATION', fileUrl: 'raw-object-key.jpg', status: 'PENDING', rejectReason: null, reviewedBy: null, reviewedAt: null, createdAt: new Date() },
        ]),
      },
      companyMember: { findMany: jest.fn().mockResolvedValue([]) },
      companyInvite: { findMany: jest.fn().mockResolvedValue([]) },
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { findMany: jest.fn().mockResolvedValue([]) },
      review: { findMany: jest.fn().mockResolvedValue([]) },
      complaint: { count: jest.fn().mockResolvedValue(0) },
      auditLog: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const uploads = fakeUploads();
    const service = new AdminService(prisma, {} as any, uploads as any);

    const result = await service.companyDetail('c1');

    expect(uploads.presignDocumentUrl).not.toHaveBeenCalled();
    expect(result.documents[0].fileUrl).toBe('/admin/documents/doc1/file');
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

  it('crossChecks (сверка профиля с документами) is written to audit_log, not just kept in screen state (задача 029, п.16)', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }), update: jest.fn().mockResolvedValue({ id: 'd1', isVerified: true }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.setDriverVerified('d1', 'admin-1', {
      isVerified: true,
      reason: 'проверил лично',
      force: true,
      crossChecks: { name: true, photo: true, plate: false },
    });

    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ metadata: expect.objectContaining({ crossChecks: { name: true, photo: true, plate: false } }) }),
      }),
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

  it('setDriverVerified(true) sends VERIFICATION_APPROVED to the driver (задача 011)', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1', userId: 'user-d1' }), update: jest.fn().mockResolvedValue({ id: 'd1', isVerified: true }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.setDriverVerified('d1', 'admin-1', { isVerified: true, reason: 'проверил лично', force: true });

    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['user-d1'] }, 'VERIFICATION_APPROVED', {});
  });

  it('setDriverVerified(false) does not notify', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1', userId: 'user-d1' }), update: jest.fn().mockResolvedValue({ id: 'd1', isVerified: false }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.setDriverVerified('d1', 'admin-1', { isVerified: false, reason: 'нарушение' });

    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('setCompanyVerified(true, force) sends VERIFICATION_APPROVED to the owner (задача 011)', async () => {
    const prisma: any = {
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1' }), update: jest.fn().mockResolvedValue({ id: 'c1', isVerified: true }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.setCompanyVerified('c1', 'admin-1', { isVerified: true, reason: 'x', force: true });

    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['owner-1'] }, 'VERIFICATION_APPROVED', {});
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

describe('AdminService.stats — growth and on-site counters (задача 028, п.2)', () => {
  it('counts growth within the requested period and defaults to today when no period is given', async () => {
    const countMock = jest.fn().mockResolvedValue(0);
    const prisma: any = {
      driver: { count: countMock },
      company: { count: countMock },
      cargo: { count: countMock },
      deal: { count: countMock },
      verificationDocument: { count: countMock },
      complaint: { count: countMock },
      arrival: { count: countMock },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.stats();
    expect(result.period).toBe('today');

    const result7d = await service.stats('7d');
    expect(result7d.period).toBe('7d');
  });

  it('computes the share of cargos closed outside the app (задача 017, п.7)', async () => {
    const prisma: any = {
      driver: { count: jest.fn().mockResolvedValue(0) },
      company: { count: jest.fn().mockResolvedValue(0) },
      cargo: { count: jest.fn().mockResolvedValueOnce(0).mockResolvedValueOnce(0).mockResolvedValueOnce(10).mockResolvedValueOnce(4) },
      deal: { count: jest.fn().mockResolvedValue(0) },
      verificationDocument: { count: jest.fn().mockResolvedValue(0) },
      complaint: { count: jest.fn().mockResolvedValue(0) },
      arrival: { count: jest.fn().mockResolvedValue(0) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.stats();

    expect(result.cargosClosedTotal).toBe(10);
    expect(result.cargosClosedOutside).toBe(4);
    expect(result.cargosClosedOutsideSharePct).toBe(40);
  });

  it('returns null share (not NaN/Infinity) when nothing was closed yet', async () => {
    const countZero = jest.fn().mockResolvedValue(0);
    const prisma: any = {
      driver: { count: countZero },
      company: { count: countZero },
      cargo: { count: countZero },
      deal: { count: countZero },
      verificationDocument: { count: countZero },
      complaint: { count: countZero },
      arrival: { count: countZero },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.stats();
    expect(result.cargosClosedOutsideSharePct).toBeNull();
  });
});

describe('AdminService.attention (задача 028, п.4)', () => {
  it('counts distinct people (not documents) waiting on verification, and the oldest pending age', async () => {
    const oldest = new Date(Date.now() - 5 * 60 * 60 * 1000); // 5h ago
    const prisma: any = {
      verificationDocument: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ driverId: 'd1' }, { driverId: 'd2' }]) // pending drivers
          .mockResolvedValueOnce([{ companyId: 'c1' }]), // pending companies
        findFirst: jest.fn().mockResolvedValue({ createdAt: oldest }),
      },
      complaint: { count: jest.fn().mockResolvedValue(2) },
      deal: { count: jest.fn().mockResolvedValue(1) },
      company: { count: jest.fn().mockResolvedValue(3) },
      city: { count: jest.fn().mockResolvedValue(0) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.attention();

    expect(result.pendingVerification.count).toBe(3);
    expect(result.pendingVerification.oldestAgeHours).toBe(5);
    expect(result.openComplaints).toBe(2);
    expect(result.staleDeals).toBe(1);
    expect(result.unverifiedCompanies).toBe(3);
  });
});

describe('AdminService.search — grouped results (задача 028, п.6)', () => {
  it('returns empty groups for a blank query without hitting the database', async () => {
    const prisma: any = { driver: { findMany: jest.fn() } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.search('   ');

    expect(result).toEqual({ drivers: [], companies: [], cargos: [], deals: [] });
    expect(prisma.driver.findMany).not.toHaveBeenCalled();
  });

  it('searches drivers by name/phone/plate and companies by name/taxId/member email', async () => {
    const prisma: any = {
      driver: { findMany: jest.fn().mockResolvedValue([{ id: 'd1', fullName: 'Ерлан' }]) },
      company: { findMany: jest.fn().mockResolvedValue([]) },
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.search('Ерлан');

    expect(result.drivers).toEqual([{ id: 'd1', title: 'Ерлан' }]);
    const driverWhere = prisma.driver.findMany.mock.calls[0][0].where;
    expect(driverWhere.OR).toHaveLength(3);
  });
});

describe('AdminService.searchCargos / searchDeals (задача 028, п.14/16)', () => {
  it('searchCargos filters by status/company/destination and paginates', async () => {
    const prisma: any = {
      cargo: {
        count: jest.fn().mockResolvedValue(1),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'cargo1',
            point: { name: { ru: 'Хоргос' } },
            destinationCountry: { name: { ru: 'Казахстан' } },
            destinationCity: null,
            bodyType: { name: { ru: 'Тент' } },
            weightKg: 5000,
            price: 1000,
            currency: 'USD',
            company: { id: 'c1', name: 'Acme' },
            _count: { responses: 2 },
            status: 'PUBLISHED',
            publishedAt: new Date(),
          },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.searchCargos({ status: 'PUBLISHED', companyId: 'c1' });

    expect(prisma.cargo.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ status: 'PUBLISHED', companyId: 'c1' }) }),
    );
    expect(result.items[0]).toEqual(
      expect.objectContaining({ id: 'cargo1', companyId: 'c1', responseCount: 2 }),
    );
  });

  it('searchDeals: status=active maps to notIn DELIVERED/CANCELLED, and stale adds the updatedAt cutoff', async () => {
    const prisma: any = {
      deal: {
        count: jest.fn().mockResolvedValue(0),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.searchDeals({ status: 'active' });
    expect(prisma.deal.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ status: { notIn: ['DELIVERED', 'CANCELLED'] } }) }),
    );

    await service.searchDeals({ stale: true });
    const staleWhere = prisma.deal.findMany.mock.calls[1][0].where;
    expect(staleWhere.status).toEqual({ notIn: ['DELIVERED', 'CANCELLED'] });
    expect(staleWhere.updatedAt.lt).toBeInstanceOf(Date);
  });

  it('searchDeals computes staleDays from updatedAt for active deals, and 0 for delivered/cancelled', async () => {
    const fourDaysAgo = new Date(Date.now() - 4 * 24 * 60 * 60 * 1000);
    const prisma: any = {
      deal: {
        count: jest.fn().mockResolvedValue(1),
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'deal1',
            cargo: { point: { name: {} }, destinationCountry: { name: {} }, price: 100, currency: 'USD' },
            driver: { id: 'd1', fullName: 'Ерлан' },
            company: { id: 'c1', name: 'Acme' },
            status: 'LOADED',
            updatedAt: fourDaysAgo,
            createdAt: fourDaysAgo,
          },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.searchDeals({});
    expect(result.items[0].staleDays).toBe(4);
  });
});

describe('AdminService.documentFileSource — proxy instead of presigned link (задача 028, п.12)', () => {
  it('throws NotFoundException for an unknown document', async () => {
    const prisma: any = { verificationDocument: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.documentFileSource('missing')).rejects.toThrow(NotFoundException);
  });

  it('returns a redirect for legacy http(s) fileUrl without touching MinIO', async () => {
    const uploads = fakeUploads();
    const prisma: any = {
      verificationDocument: { findUnique: jest.fn().mockResolvedValue({ id: 'doc1', fileUrl: 'https://legacy.example/a.jpg' }) },
    };
    const service = new AdminService(prisma, {} as any, uploads as any);

    const result = await service.documentFileSource('doc1');

    expect(result).toEqual({ redirectUrl: 'https://legacy.example/a.jpg' });
    expect(uploads.getDocumentStream).not.toHaveBeenCalled();
  });

  it('streams from MinIO for an object-key fileUrl', async () => {
    const uploads = fakeUploads();
    const prisma: any = {
      verificationDocument: { findUnique: jest.fn().mockResolvedValue({ id: 'doc1', fileUrl: 'abc123.jpg' }) },
    };
    const service = new AdminService(prisma, {} as any, uploads as any);

    const result = await service.documentFileSource('doc1');

    expect(uploads.getDocumentStream).toHaveBeenCalledWith('abc123.jpg');
    expect(result).toEqual({ stream: 'stream:abc123.jpg', contentType: 'image/jpeg' });
  });
});

describe('AdminService.verificationQueue — by subject, not by document (задача 028, п.7)', () => {
  it('returns one row per driver, sorted by oldest-pending first, with a NEW reason for a first-time submission', async () => {
    const t0 = new Date(Date.now() - 2 * 60 * 60 * 1000);
    const t1 = new Date(Date.now() - 1 * 60 * 60 * 1000);
    const prisma: any = {
      verificationDocument: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([
            { driverId: 'd1', type: 'SELFIE', status: 'PENDING', createdAt: t1 },
            { driverId: 'd2', type: 'SELFIE', status: 'PENDING', createdAt: t0 },
          ])
          .mockResolvedValueOnce([
            { driverId: 'd1', type: 'SELFIE', status: 'PENDING', createdAt: t1 },
            { driverId: 'd2', type: 'SELFIE', status: 'PENDING', createdAt: t0 },
          ]),
      },
      driver: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'd1', fullName: 'Ерлан', isVerified: false },
          { id: 'd2', fullName: 'Нурлан', isVerified: false },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.verificationQueue('driver');

    expect(result.map((r: any) => r.subjectId)).toEqual(['d2', 'd1']); // d2 waits longer
    expect(result[0].reason).toBe('NEW');
  });

  it('labels a verified driver with a new vehicle-document submission as VEHICLE_CHANGED', async () => {
    const now = new Date();
    const prisma: any = {
      verificationDocument: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ driverId: 'd1', type: 'VEHICLE_PASSPORT', status: 'PENDING', createdAt: now }])
          .mockResolvedValueOnce([{ driverId: 'd1', type: 'VEHICLE_PASSPORT', status: 'PENDING', createdAt: now }]),
      },
      driver: { findMany: jest.fn().mockResolvedValue([{ id: 'd1', fullName: 'Ерлан', isVerified: true }]) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.verificationQueue('driver');

    expect(result[0].reason).toBe('VEHICLE_CHANGED');
  });

  it('labels a resubmission (same doc type previously rejected) as RESUBMITTED', async () => {
    const now = new Date();
    const prisma: any = {
      verificationDocument: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ driverId: 'd1', type: 'DRIVER_LICENSE', status: 'PENDING', createdAt: now }])
          .mockResolvedValueOnce([
            { driverId: 'd1', type: 'DRIVER_LICENSE', status: 'REJECTED', createdAt: now },
            { driverId: 'd1', type: 'DRIVER_LICENSE', status: 'PENDING', createdAt: now },
          ]),
      },
      driver: { findMany: jest.fn().mockResolvedValue([{ id: 'd1', fullName: 'Ерлан', isVerified: false }]) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.verificationQueue('driver');

    expect(result[0].reason).toBe('RESUBMITTED');
    expect(result[0].resubmittedType).toBe('DRIVER_LICENSE');
  });

  it('returns an empty queue when nothing is pending, without querying drivers', async () => {
    const prisma: any = { verificationDocument: { findMany: jest.fn().mockResolvedValue([]) }, driver: { findMany: jest.fn() } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.verificationQueue('driver');

    expect(result).toEqual([]);
    expect(prisma.driver.findMany).not.toHaveBeenCalled();
  });

  it('companies branch groups by companyId the same way', async () => {
    const now = new Date();
    const prisma: any = {
      verificationDocument: {
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ companyId: 'c1', type: 'COMPANY_REGISTRATION', status: 'PENDING', createdAt: now }])
          .mockResolvedValueOnce([{ companyId: 'c1', type: 'COMPANY_REGISTRATION', status: 'PENDING', createdAt: now }]),
      },
      company: { findMany: jest.fn().mockResolvedValue([{ id: 'c1', name: 'Acme', isVerified: false }]) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.verificationQueue('company');

    expect(result).toEqual([
      expect.objectContaining({ subjectId: 'c1', subjectName: 'Acme', reason: 'NEW' }),
    ]);
  });
});

describe('AdminService.verificationDriverProfile / verificationCompanyProfile (задача 028, п.8/11)', () => {
  it('returns vehicles and ALL documents (including already-approved) with proxy fileUrl, not presigned', async () => {
    const uploads = fakeUploads();
    const prisma: any = {
      driver: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'd1',
          fullName: 'Ерлан',
          isVerified: false,
          vehicles: [{ id: 'v1', plateNumber: 'A123BC', brand: 'Volvo', capacityTons: 20, bodyType: { name: { ru: 'Тент' } } }],
        }),
      },
      verificationDocument: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'doc1', type: 'SELFIE', status: 'APPROVED', rejectReason: null, reviewedBy: null, reviewedAt: null, createdAt: new Date() },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, uploads as any);

    const result = await service.verificationDriverProfile('d1');

    expect(result.vehicles[0]).toEqual(expect.objectContaining({ plateNumber: 'A123BC', bodyTypeName: { ru: 'Тент' } }));
    expect(result.documents[0].fileUrl).toBe('/admin/documents/doc1/file');
    expect(uploads.presignDocumentUrl).not.toHaveBeenCalled();
  });

  it('throws NotFoundException for an unknown driver/company', async () => {
    const prisma: any = { driver: { findUnique: jest.fn().mockResolvedValue(null) }, company: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.verificationDriverProfile('missing')).rejects.toThrow(NotFoundException);
    await expect(service.verificationCompanyProfile('missing')).rejects.toThrow(NotFoundException);
  });
});

describe('AdminService.returnDriverForRework / returnCompanyForRework — one decision per person (задача 028, п.10)', () => {
  it('rejects at least one document, which is required', async () => {
    const prisma: any = { driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.returnDriverForRework('d1', 'admin-1', { decisions: [] } as any)).rejects.toThrow(BadRequestException);
  });

  it('rejects the listed documents, unverifies the driver, logs one decision entry, and notifies the driver for real (задача 011)', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1', userId: 'user-d1' }), update: jest.fn() },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([{ id: 'doc1', driverId: 'd1', type: 'SELFIE' }]), update: jest.fn() },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
      auditLog: { create: jest.fn() },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.returnDriverForRework('d1', 'admin-1', {
      decisions: [{ documentId: 'doc1', rejectReason: 'Нечитаемое фото' }],
      note: 'Переснимите права',
    } as any);

    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { isVerified: false } });
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'DRIVER_RETURNED_FOR_REWORK' }) }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
    // Задача 029, п.7 — push несёт список документов и причин, не только
    // общую заметку (formatVerificationReturnedBody собирает их вместе).
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['user-d1'] },
      'VERIFICATION_RETURNED',
      { note: 'Переснимите права', documents: [{ type: 'SELFIE', reason: 'Нечитаемое фото' }] },
    );
  });

  it('persists crossChecks to audit_log when returning for rework too (задача 029, п.16)', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1', userId: 'user-d1' }), update: jest.fn() },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([{ id: 'doc1', driverId: 'd1', type: 'SELFIE' }]), update: jest.fn() },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, { notify: jest.fn() } as any);

    await service.returnDriverForRework('d1', 'admin-1', {
      decisions: [{ documentId: 'doc1', rejectReason: 'Нечитаемое фото' }],
      crossChecks: { name: false },
    } as any);

    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ metadata: expect.objectContaining({ crossChecks: { name: false } }) }) }),
    );
  });

  it('throws if a listed document does not belong to this driver', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }) },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([]) }, // doc belongs to someone else
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(
      service.returnDriverForRework('d1', 'admin-1', { decisions: [{ documentId: 'doc-other', rejectReason: 'x' }] } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('company branch: rejects documents, unverifies the company, logs one decision entry, and notifies the owner', async () => {
    const prisma: any = {
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1' }), update: jest.fn() },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([{ id: 'doc1', companyId: 'c1', type: 'COMPANY_REGISTRATION' }]), update: jest.fn() },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
      auditLog: { create: jest.fn() },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.returnCompanyForRework('c1', 'admin-1', {
      decisions: [{ documentId: 'doc1', rejectReason: 'Документ просрочен' }],
    } as any);

    expect(prisma.company.update).toHaveBeenCalledWith({ where: { id: 'c1' }, data: { isVerified: false } });
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['owner-1'] },
      'VERIFICATION_RETURNED',
      { note: undefined, documents: [{ type: 'COMPANY_REGISTRATION', reason: 'Документ просрочен' }] },
    );
  });
});

describe('AdminService.cargoDetail / updateCargo / unpublishCargo (задача 028, п.15)', () => {
  function baseCargo(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'cargo1',
      companyId: 'c1',
      destinationCountryId: 'country1',
      destinationCityId: null,
      bodyTypeId: 'bt1',
      weightKg: null,
      volumeM3: null,
      photoUrls: [],
      price: 100,
      currency: 'USD',
      readyDate: new Date('2026-10-01T00:00:00Z'),
      description: null,
      status: 'PUBLISHED',
      publishedAt: new Date(),
      expiresAt: new Date(),
      archivedAt: null,
      createdAt: new Date(),
      point: { name: { ru: 'Хоргос' } },
      destinationCountry: { name: { ru: 'Казахстан' } },
      destinationCity: null,
      bodyType: { name: { ru: 'Тент' } },
      company: { id: 'c1', name: 'Acme' },
      responses: [],
      deals: [],
      ...overrides,
    };
  }

  it('cargoDetail throws NotFoundException for an unknown cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.cargoDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('cargoDetail converts price to KZT using the latest exchange rate, and includes responses/deal/audit', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ deals: [{ id: 'deal1', status: 'SELECTED', driverId: 'd1', driver: { fullName: 'Ерлан' } }] })) },
      auditLog: { findMany: jest.fn().mockResolvedValue([]) },
      exchangeRate: { findFirst: jest.fn().mockResolvedValue({ rateToKzt: 450 }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.cargoDetail('cargo1');

    expect(result.priceInKzt).toBe(100 * 450);
    expect(result.deal).toEqual({ id: 'deal1', status: 'SELECTED', driverName: 'Ерлан' });
  });

  it('cargoDetail returns priceInKzt null when there is no rate for the currency', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()) },
      auditLog: { findMany: jest.fn().mockResolvedValue([]) },
      exchangeRate: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.cargoDetail('cargo1');
    expect(result.priceInKzt).toBeNull();
  });

  it('updateCargo records old/new only for changed fields, with the reason, and recomputes expiresAt when readyDate changes', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn().mockResolvedValue({ id: 'cargo1' }) },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.updateCargo('cargo1', 'admin-1', { price: 200, reason: 'Опечатка в цене' } as any);

    expect(prisma.cargo.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'cargo1' }, data: expect.objectContaining({ price: 200 }) }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'CARGO_UPDATED',
          metadata: expect.objectContaining({ reason: 'Опечатка в цене', changes: { price: { old: 100, new: 200 } } }),
        }),
      }),
    );
  });

  it('unpublishCargo sets ARCHIVED with archivedAt, logs one decision entry, and notifies the publisher (задача 029, п.7)', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
      auditLog: { create: jest.fn() },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.unpublishCargo('cargo1', 'admin-1', 'Груз больше не актуален');

    expect(prisma.cargo.update).toHaveBeenCalledWith({ where: { id: 'cargo1' }, data: { status: 'ARCHIVED', archivedAt: expect.any(Date) } });
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['owner-1'] }, 'CARGO_UNPUBLISHED', { cargoId: 'cargo1', reason: 'Груз больше не актуален' });
  });

  it('unpublishCargo throws NotFoundException for an unknown cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.unpublishCargo('missing', 'admin-1', 'x')).rejects.toThrow(NotFoundException);
  });
});

describe('AdminService.dealDetail / dealChat / advanceDealStatusByAdmin / cancelDealByAdmin (задача 028, п.17)', () => {
  function baseDeal(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'deal1',
      cargoId: 'cargo1',
      driverId: 'd1',
      companyId: 'c1',
      status: 'LOADED',
      cancelReason: null,
      cancelledByRole: null,
      confirmedAt: new Date('2026-10-01T00:00:00Z'),
      loadedAt: new Date('2026-10-02T00:00:00Z'),
      inTransitAt: null,
      deliveredAt: null,
      createdAt: new Date('2026-09-30T00:00:00Z'),
      updatedAt: new Date('2026-10-02T00:00:00Z'),
      cargo: { currency: 'USD', price: 100, point: { name: { ru: 'Хоргос' } }, destinationCountry: { name: { ru: 'Казахстан' } } },
      driver: { id: 'd1', fullName: 'Ерлан' },
      company: { id: 'c1', name: 'Acme' },
      contactEvents: [],
      ...overrides,
    };
  }

  it('dealDetail throws NotFoundException for an unknown deal', async () => {
    const prisma: any = { deal: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.dealDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('dealDetail builds a status history only from timestamps that are set', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(baseDeal()) },
      auditLog: { findMany: jest.fn().mockResolvedValue([]) },
      exchangeRate: { findFirst: jest.fn().mockResolvedValue({ rateToKzt: 450 }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.dealDetail('deal1');

    expect(result.statusHistory.map((h: any) => h.status)).toEqual(['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED']);
    expect(result.priceInKzt).toBe(100 * 450);
  });

  it('dealChat returns the messages of the deal-linked chat and logs exactly one ADMIN_VIEWED_CHAT entry', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue({ id: 'deal1' }) },
      chat: { findFirst: jest.fn().mockResolvedValue({ id: 'chat1' }) },
      message: { findMany: jest.fn().mockResolvedValue([{ id: 'm1', senderUserId: 'u1', originalText: 'Привет', originalLang: 'ru', translations: null, createdAt: new Date() }]) },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const messages = await service.dealChat('deal1', 'admin-1');

    expect(messages).toHaveLength(1);
    expect(prisma.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ action: 'ADMIN_VIEWED_CHAT' }) }));
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
  });

  it('dealChat returns an empty list when there is no chat yet, without crashing', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue({ id: 'deal1' }) },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    expect(await service.dealChat('deal1', 'admin-1')).toEqual([]);
  });

  function dealNotificationMocks() {
    return {
      driver: { findUnique: jest.fn().mockResolvedValue({ userId: 'u-driver' }) },
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1', publishedByUserId: 'logist-1' }) },
    };
  }

  it('advanceDealStatusByAdmin allows moving one step forward, sets the new timestamp, and notifies both sides (задача 029, п.7)', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(baseDeal({ status: 'CONFIRMED_BY_DRIVER' })), update: jest.fn() },
      auditLog: { create: jest.fn() },
      ...dealNotificationMocks(),
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.advanceDealStatusByAdmin('deal1', 'admin-1', { status: 'LOADED', reason: 'Водитель уже погрузился' } as any);

    expect(prisma.deal.update).toHaveBeenCalledWith({ where: { id: 'deal1' }, data: { status: 'LOADED', loadedAt: expect.any(Date) } });
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['u-driver', 'logist-1'], companyId: 'c1' },
      'DEAL_STATUS',
      expect.objectContaining({ dealId: 'deal1', status: 'LOADED' }),
    );
  });

  it('advanceDealStatusByAdmin allows moving one step backward and clears the timestamp being undone', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(baseDeal({ status: 'LOADED' })), update: jest.fn() },
      auditLog: { create: jest.fn() },
      ...dealNotificationMocks(),
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.advanceDealStatusByAdmin('deal1', 'admin-1', { status: 'CONFIRMED_BY_DRIVER', reason: 'Ошиблись статусом' } as any);

    expect(prisma.deal.update).toHaveBeenCalledWith({ where: { id: 'deal1' }, data: { status: 'CONFIRMED_BY_DRIVER', loadedAt: null } });
  });

  it('advanceDealStatusByAdmin rejects a jump of more than one step', async () => {
    const prisma: any = { deal: { findUnique: jest.fn().mockResolvedValue(baseDeal({ status: 'SELECTED' })) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(
      service.advanceDealStatusByAdmin('deal1', 'admin-1', { status: 'DELIVERED', reason: 'x' } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('cancelDealByAdmin sets CANCELLED with cancelledByRole=ADMIN', async () => {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(baseDeal({ status: 'LOADED' })), update: jest.fn() },
      auditLog: { create: jest.fn() },
      ...dealNotificationMocks(),
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.cancelDealByAdmin('deal1', 'admin-1', 'Груз утрачен');

    expect(prisma.deal.update).toHaveBeenCalledWith({
      where: { id: 'deal1' },
      data: { status: 'CANCELLED', cancelReason: 'Груз утрачен', cancelledByRole: 'ADMIN' },
    });
  });

  it('cancelDealByAdmin refuses to cancel an already DELIVERED or CANCELLED deal', async () => {
    const prisma: any = { deal: { findUnique: jest.fn().mockResolvedValue(baseDeal({ status: 'DELIVERED' })) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.cancelDealByAdmin('deal1', 'admin-1', 'x')).rejects.toThrow(BadRequestException);
  });
});

describe('AdminService.updateDriver — общая панель редактирования (задача 028, п.18/19)', () => {
  function baseDriver(overrides: Partial<Record<string, unknown>> = {}) {
    return {
      id: 'd1',
      userId: 'u1',
      fullName: 'Ерлан',
      homeCityId: 'city1',
      anyCountry: false,
      user: { phone: '+77001112233' },
      vehicles: [{ id: 'v1', bodyTypeId: 'bt1', plateNumber: 'A1', capacityTons: null, lengthM: null, brand: null, createdAt: new Date() }],
      directions: [],
      permits: [],
      ...overrides,
    };
  }

  function txMock() {
    return {
      driver: { update: jest.fn() },
      user: { update: jest.fn() },
      driverDirection: { deleteMany: jest.fn(), createMany: jest.fn() },
      driverPermit: { deleteMany: jest.fn(), createMany: jest.fn() },
      vehicle: { update: jest.fn() },
      verificationDocument: { updateMany: jest.fn() },
    };
  }

  it('throws NotFoundException for an unknown driver', async () => {
    const prisma: any = { driver: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.updateDriver('missing', 'admin-1', { reason: 'x' } as any)).rejects.toThrow(NotFoundException);
  });

  it('changing phone checks uniqueness, revokes sessions, and logs phoneChanged', async () => {
    const tx = txMock();
    const sessions = { revokeAllForUser: jest.fn() };
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(baseDriver()) },
      user: { findFirst: jest.fn().mockResolvedValue(null) },
      city: { findUnique: jest.fn() },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    const result = await service.updateDriver('d1', 'admin-1', { phone: '+77009998877', reason: 'Сменил номер' } as any);

    expect(result.phoneChanged).toBe(true);
    expect(tx.user.update).toHaveBeenCalledWith({ where: { id: 'u1' }, data: { phone: '+77009998877' } });
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ metadata: expect.objectContaining({ phoneChanged: true }) }) }),
    );
  });

  it('refuses a phone already used by another user', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(baseDriver()) },
      user: { findFirst: jest.fn().mockResolvedValue({ id: 'other-user' }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.updateDriver('d1', 'admin-1', { phone: '+77009998877', reason: 'x' } as any)).rejects.toThrow(ConflictException);
  });

  it('changing the tractor plate resubmits VEHICLE_PASSPORT/TRAILER_PASSPORT and unverifies the driver', async () => {
    const tx = txMock();
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(baseDriver()) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.updateDriver('d1', 'admin-1', { vehicle: { plateNumber: 'NEW999' }, reason: 'Сменил номер машины' } as any);

    expect(result.vehicleIdentityChanged).toBe(true);
    expect(tx.driver.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ isVerified: false }) }));
    expect(tx.verificationDocument.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ driverId: 'd1', type: { in: ['VEHICLE_PASSPORT', 'TRAILER_PASSPORT'] } }) }),
    );
  });

  it('changing only capacityTons does not trigger document resubmission', async () => {
    const tx = txMock();
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(baseDriver()) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.updateDriver('d1', 'admin-1', { vehicle: { capacityTons: 25 }, reason: 'Уточнили тоннаж' } as any);

    expect(result.vehicleIdentityChanged).toBe(false);
    expect(tx.verificationDocument.updateMany).not.toHaveBeenCalled();
  });

  it('rejects an unknown homeCityId', async () => {
    const prisma: any = {
      driver: { findUnique: jest.fn().mockResolvedValue(baseDriver()) },
      city: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.updateDriver('d1', 'admin-1', { homeCityId: 'missing', reason: 'x' } as any)).rejects.toThrow(NotFoundException);
  });
});

describe('AdminService.updateCompany / member management (задача 028, п.18/20)', () => {
  it('updateCompany logs only changed fields', async () => {
    const prisma: any = {
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1', name: 'Acme', nameRu: null, countryId: 'kz', city: null, legalAddress: null, taxId: null }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.updateCompany('c1', 'admin-1', { taxId: '123456', reason: 'Уточнили БИН' } as any);

    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ metadata: expect.objectContaining({ changes: { taxId: { old: null, new: '123456' } } }) }) }),
    );
  });

  it('setMemberRole refuses to demote the last owner', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', role: 'OWNER' }), count: jest.fn().mockResolvedValue(1) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.setMemberRole('c1', 'u1', 'admin-1', { role: 'LOGIST', reason: 'x' } as any)).rejects.toThrow(BadRequestException);
  });

  it('setMemberRole allows promoting a logist to owner (transfer of ownership)', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', role: 'LOGIST' }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.setMemberRole('c1', 'u1', 'admin-1', { role: 'OWNER', reason: 'Передача владения' } as any);
    expect(prisma.companyMember.update).toHaveBeenCalledWith({ where: { id: 'm1' }, data: { role: 'OWNER' } });
  });

  it('removeMember refuses to remove the last owner', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', role: 'OWNER' }), count: jest.fn().mockResolvedValue(1) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(service.removeMember('c1', 'u1', 'admin-1', 'x')).rejects.toThrow(BadRequestException);
  });

  it('removeMember deletes a non-owner member', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', role: 'LOGIST' }), delete: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.removeMember('c1', 'u1', 'admin-1', 'Больше не работает');
    expect(prisma.companyMember.delete).toHaveBeenCalledWith({ where: { id: 'm1' } });
  });

  it('changeMemberEmail checks uniqueness and revokes sessions', async () => {
    const sessions = { revokeAllForUser: jest.fn() };
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', user: { email: 'old@example.com' } }) },
      user: { findFirst: jest.fn().mockResolvedValue(null), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    await service.changeMemberEmail('c1', 'u1', 'admin-1', { email: 'new@example.com', reason: 'Сменил почту' } as any);

    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'u1' }, data: { email: 'new@example.com' } });
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
  });

  it('changeMemberEmail refuses an email already in use', async () => {
    const prisma: any = {
      companyMember: { findFirst: jest.fn().mockResolvedValue({ id: 'm1', user: { email: 'old@example.com' } }) },
      user: { findFirst: jest.fn().mockResolvedValue({ id: 'other' }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(
      service.changeMemberEmail('c1', 'u1', 'admin-1', { email: 'taken@example.com', reason: 'x' } as any),
    ).rejects.toThrow(ConflictException);
  });
});

describe('AdminService reference-data edits (задача 028, п.21)', () => {
  it('updateBodyType logs isActive/sortOrder changes and writes 4-language name', async () => {
    const prisma: any = {
      bodyType: {
        findUnique: jest.fn().mockResolvedValue({ name: { ru: 'Тент' }, isActive: true, sortOrder: 0 }),
        update: jest.fn(),
      },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.updateBodyType('bt1', 'admin-1', { isActive: false, reason: 'Больше не используется' } as any);

    expect(prisma.bodyType.update).toHaveBeenCalledWith({ where: { id: 'bt1' }, data: { name: undefined, isActive: false, sortOrder: undefined } });
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'BODYTYPE_UPDATED', metadata: expect.objectContaining({ changes: { isActive: { old: true, new: false } } }) }) }),
    );
  });

  it('updateBodyType throws NotFoundException for an unknown id', async () => {
    const prisma: any = { bodyType: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.updateBodyType('missing', 'admin-1', { reason: 'x' } as any)).rejects.toThrow(NotFoundException);
  });

  it('updatePoint writes coordinates and city change', async () => {
    const prisma: any = {
      point: { findUnique: jest.fn().mockResolvedValue({ name: {}, cityId: 'city1', isActive: true, lat: null, lng: null }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.updatePoint('p1', 'admin-1', { lat: 44.2, lng: 80.4, reason: 'Уточнили координаты' } as any);

    expect(prisma.point.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ lat: 44.2, lng: 80.4 }) }));
  });

  it('updateCity writes region/coordinates for an already-approved city (not the PENDING queue)', async () => {
    const prisma: any = {
      city: { findUnique: jest.fn().mockResolvedValue({ name: {}, regionId: null, lat: null, lng: null }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.updateCity('city1', 'admin-1', { regionId: 'region1', reason: 'Для «Близко к дому»' } as any);

    expect(prisma.city.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ regionId: 'region1' }) }));
  });
});

describe('AdminService.setAppSetting (задача 028, п.22)', () => {
  it('reads the old value, writes the new one, and logs both', async () => {
    const appSettings = { get: jest.fn().mockResolvedValue('200'), set: jest.fn() };
    const prisma: any = { auditLog: { create: jest.fn() } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, appSettings as any);

    await service.setAppSetting('admin-1', 'homeRadiusKm', '250', 'Расширили радиус');

    expect(appSettings.set).toHaveBeenCalledWith('homeRadiusKm', '250');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'SETTING_CHANGED', metadata: expect.objectContaining({ old: '200', new: '250' }) }) }),
    );
  });
});

describe('AdminService.complaints tabs/counts/assignment (задача 028, п.24a/24e)', () => {
  it('tab=NEW maps to status OPEN, tab=CLOSED maps to RESOLVED+REJECTED', async () => {
    const prisma: any = { complaint: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.complaints({ tab: 'NEW' });
    expect(prisma.complaint.findMany.mock.calls[0][0].where).toEqual({ status: 'OPEN' });

    await service.complaints({ tab: 'CLOSED' });
    expect(prisma.complaint.findMany.mock.calls[1][0].where).toEqual({ status: { in: ['RESOLVED', 'REJECTED'] } });
  });

  it('mine filters by assignedToUserId', async () => {
    const prisma: any = { complaint: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.complaints({ mine: 'admin-1' });
    expect(prisma.complaint.findMany.mock.calls[0][0].where).toEqual({ assignedToUserId: 'admin-1' });
  });

  it('complaintCounts groups OPEN as new, IN_REVIEW as in-review, RESOLVED+REJECTED as closed', async () => {
    const prisma: any = { complaint: { count: jest.fn().mockResolvedValueOnce(3).mockResolvedValueOnce(2).mockResolvedValueOnce(5) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.complaintCounts();
    expect(result).toEqual({ newCount: 3, inReviewCount: 2, closedCount: 5 });
  });

  it('assignComplaint sets assignedToUserId/takenAt and moves to IN_REVIEW', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue({ id: 'cp1' }), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {}, }) },
      auditLog: { create: jest.fn() },
      user: { findUnique: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.assignComplaint('cp1', 'admin-1');

    expect(prisma.complaint.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'cp1' }, data: expect.objectContaining({ assignedToUserId: 'admin-1', status: 'IN_REVIEW' }) }),
    );
  });

  it('unassignComplaint clears assignment and returns to OPEN', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue({ id: 'cp1' }), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      auditLog: { create: jest.fn() },
      user: { findUnique: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.unassignComplaint('cp1', 'admin-1');

    expect(prisma.complaint.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'cp1' }, data: { assignedToUserId: null, takenAt: null, status: 'OPEN' } }),
    );
  });
});

describe('AdminService.complaintDetail — context + violator history (задача 028, п.24c)', () => {
  it('throws NotFoundException for an unknown complaint', async () => {
    const prisma: any = { complaint: { findUnique: jest.fn().mockResolvedValue(null) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);
    await expect(service.complaintDetail('missing')).rejects.toThrow(NotFoundException);
  });

  it('CARGO target: includes cargo context (with price) and counts other complaints on the same target in the last 30 days', async () => {
    const prisma: any = {
      complaint: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'cp1', reporterUserId: 'u1', reporter: { id: 'u1', phone: '+7700', email: null },
          targetType: 'CARGO', targetId: 'cargo1', reason: 'Фейковый груз', description: null, status: 'OPEN',
          assignedToUserId: null, assignedTo: null, takenAt: null, resolution: null, resolutionNote: null,
          resolvedByUserId: null, resolvedBy: null, resolvedAt: null, createdAt: new Date(),
        }),
        count: jest.fn().mockResolvedValue(2),
      },
      cargo: { findUnique: jest.fn().mockResolvedValue({ id: 'cargo1', price: 500, currency: 'USD', point: { name: { ru: 'Хоргос' } }, company: { name: 'Acme' } }) },
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1', name: 'Acme' }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', name: null, phone: '+7700', email: null, driver: null, companyMember: null }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.complaintDetail('cp1');

    expect(result.violatorComplaintsLastMonth).toBe(2);
    expect(result.context.cargo).toEqual(expect.objectContaining({ id: 'cargo1', price: 500, currency: 'USD', companyName: 'Acme' }));
    expect(prisma.complaint.count).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ id: { not: 'cp1' } }) }),
    );
  });

  it('CHAT_MESSAGE target: includes the message with original text and translations', async () => {
    const prisma: any = {
      complaint: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'cp1', reporterUserId: 'u1', reporter: { id: 'u1', phone: '+7700', email: null },
          targetType: 'CHAT_MESSAGE', targetId: 'msg1', reason: 'Оскорбления', description: null, status: 'OPEN',
          assignedToUserId: null, assignedTo: null, takenAt: null, resolution: null, resolutionNote: null,
          resolvedByUserId: null, resolvedBy: null, resolvedAt: null, createdAt: new Date(),
        }),
        count: jest.fn().mockResolvedValue(0),
      },
      message: {
        findUnique: jest
          .fn()
          .mockResolvedValueOnce({ id: 'msg1', originalText: 'плохое слово', originalLang: 'ru', translations: { kk: '...' } })
          .mockResolvedValueOnce({ id: 'msg1', originalText: 'плохое слово', originalLang: 'ru', translations: { kk: '...' }, sender: { name: null, phone: '+7700', email: null, driver: null, companyMember: null } }),
      },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', name: null, phone: '+7700', email: null, driver: null, companyMember: null }) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    const result = await service.complaintDetail('cp1');

    expect(result.context.message).toEqual(expect.objectContaining({ id: 'msg1', originalText: 'плохое слово', originalLang: 'ru' }));
  });
});

describe('AdminService.resolveComplaint — 4 resolutions, required note (задача 028, п.24d)', () => {
  function baseComplaint(overrides: Partial<Record<string, unknown>> = {}) {
    return { id: 'cp1', reporterUserId: 'u1', targetType: 'USER', targetId: 'violator-1', reason: 'Грубость по телефону', ...overrides };
  }

  it('DISMISSED closes as REJECTED, with no side effect', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint()), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      user: { findUnique: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'DISMISSED', resolutionNote: 'Не подтвердилось' } as any);

    expect(prisma.complaint.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'REJECTED', resolution: 'DISMISSED', resolutionNote: 'Не подтвердилось' }) }),
    );
  });

  it('BLOCKED on a USER target blocks that user (reusing blockUser) with the complaint reason', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint()), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'violator-1' }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const sessions = { revokeAllForUser: jest.fn() };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'BLOCKED', resolutionNote: 'Подтвердилось, заблокирован' } as any);

    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'violator-1' }, data: { isBlocked: true } });
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('violator-1');
  });

  it('BLOCKED on a CARGO target blocks the owning company, not a user', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint({ targetType: 'CARGO', targetId: 'cargo1' })), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1' }) },
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1', members: [{ userId: 'owner-1' }] }), update: jest.fn() },
      user: { updateMany: jest.fn(), findUnique: jest.fn().mockResolvedValue({ id: 'u1' }) },
      auditLog: { create: jest.fn() },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
    };
    const sessions = { revokeAllForUser: jest.fn() };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'BLOCKED', resolutionNote: 'Компания заблокирована' } as any);

    expect(prisma.company.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'c1' }, data: { isBlocked: true } }));
  });

  it('BLOCKED on a DEAL target blocks the DRIVER when the reporter is a company member — not always the company (задача 029, п.17)', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint({ targetType: 'DEAL', targetId: 'deal1', reporterUserId: 'u-logist' })), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      deal: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1', cargoId: 'cargo1', driver: { userId: 'u-driver' } }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u-driver' }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    const sessions = { revokeAllForUser: jest.fn() };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    // Жалобу подал логист (u-logist) на водителя этой сделки — раньше
    // BLOCKED всегда бил company (deal.companyId), даже когда жалоба была
    // именно на водителя, а не на компанию.
    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'BLOCKED', resolutionNote: 'Водитель заблокирован' } as any);

    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'u-driver' }, data: { isBlocked: true } });
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u-driver');
  });

  it('BLOCKED on a DEAL target blocks the COMPANY when the reporter is the deal\'s own driver (unchanged behavior)', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint({ targetType: 'DEAL', targetId: 'deal1', reporterUserId: 'u-driver' })), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      deal: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1', cargoId: 'cargo1', driver: { userId: 'u-driver' } }) },
      company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1', members: [{ userId: 'owner-1' }] }), update: jest.fn() },
      user: { updateMany: jest.fn(), findUnique: jest.fn().mockResolvedValue({ id: 'u1' }) },
      auditLog: { create: jest.fn() },
      $transaction: jest.fn(async (ops: any[]) => Promise.all(ops)),
    };
    const sessions = { revokeAllForUser: jest.fn() };
    const service = new AdminService(prisma, sessions as any, fakeUploads() as any);

    // Жалобу подал сам водитель этой сделки (u-driver) — значит, жаловался
    // на компанию, и блокировать нужно именно её, как и раньше.
    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'BLOCKED', resolutionNote: 'Компания заблокирована' } as any);

    expect(prisma.company.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'c1' }, data: { isBlocked: true } }));
  });

  it('CARGO_UNPUBLISHED on a CARGO target unpublishes that cargo (reusing unpublishCargo)', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint({ targetType: 'CARGO', targetId: 'cargo1' })), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      cargo: { findUnique: jest.fn().mockResolvedValue({ companyId: 'c1', id: 'cargo1' }), update: jest.fn() },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1' }) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ userId: 'owner-1' }) },
      auditLog: { create: jest.fn() },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'CARGO_UNPUBLISHED', resolutionNote: 'Груз снят' } as any);

    expect(prisma.cargo.update).toHaveBeenCalledWith({ where: { id: 'cargo1' }, data: { status: 'ARCHIVED', archivedAt: expect.any(Date) } });
  });

  it('CARGO_UNPUBLISHED on a target with no cargo throws BadRequestException', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint({ targetType: 'USER', targetId: 'u2' })) },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any);

    await expect(
      service.resolveComplaint('cp1', 'admin-1', { resolution: 'CARGO_UNPUBLISHED', resolutionNote: 'x' } as any),
    ).rejects.toThrow(BadRequestException);
  });

  it('WARNED notifies both the reporter and the violator (задача 029, п.7 — заменяет NOTIFICATION_QUEUED)', async () => {
    const prisma: any = {
      complaint: { findUnique: jest.fn().mockResolvedValue(baseComplaint()), update: jest.fn().mockResolvedValue({ id: 'cp1', reporter: {} }) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'violator-1' }) },
      auditLog: { create: jest.fn() },
    };
    const notifications = { notify: jest.fn() };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, undefined, notifications as any);

    await service.resolveComplaint('cp1', 'admin-1', { resolution: 'WARNED', resolutionNote: 'Предупреждён' } as any);

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: [baseComplaint().reporterUserId] },
      'COMPLAINT_RESOLVED',
      { complaintId: 'cp1', resolutionNote: 'Предупреждён' },
    );
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['violator-1'] }, 'COMPLAINT_WARNED', expect.objectContaining({ reason: expect.any(String) }));
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1); // только COMPLAINT_RESOLVED — уведомления больше не заглушка в audit_log
  });
});

describe('AdminService.translationStats — «Настройки → Перевод» (задача 010, п.8)', () => {
  it('reports enabled=true when the AppSetting row is absent (default on)', async () => {
    const appSettings = { get: jest.fn().mockResolvedValue(null) };
    const prisma: any = { translationLog: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, appSettings as any);

    const result = await service.translationStats();

    expect(result.enabled).toBe(true);
    expect(result.requests7d).toBe(0);
  });

  it('reports enabled=false when the AppSetting row is explicitly "false"', async () => {
    const appSettings = { get: jest.fn().mockResolvedValue('false') };
    const prisma: any = { translationLog: { findMany: jest.fn().mockResolvedValue([]) } };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, appSettings as any);

    const result = await service.translationStats();

    expect(result.enabled).toBe(false);
  });

  it('sums tokens and counts successes over the last 7 days only (findMany already filtered by the query)', async () => {
    const appSettings = { get: jest.fn().mockResolvedValue(null) };
    const prisma: any = {
      translationLog: {
        findMany: jest.fn().mockResolvedValue([
          { success: true, tokensUsed: 100 },
          { success: true, tokensUsed: 50 },
          { success: false, tokensUsed: null },
        ]),
      },
    };
    const service = new AdminService(prisma, {} as any, fakeUploads() as any, appSettings as any);

    const result = await service.translationStats();

    expect(result).toEqual(
      expect.objectContaining({ requests7d: 3, successRequests7d: 2, tokensUsed7d: 150 }),
    );
    expect(prisma.translationLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { createdAt: { gte: expect.any(Date) } } }),
    );
  });
});
