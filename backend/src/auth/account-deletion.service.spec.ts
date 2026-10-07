import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { AccountDeletionService, DELETED_NAME } from './account-deletion.service';

// 043 п.1: удаление аккаунта — обезличивание, документы и идентификаторы,
// отзыв сессий; владелец с сотрудниками и активные сделки — отказ.
function setup(user: unknown, { otherMembers = 0, activeDeals = 0, documents = [] as { id: string; fileUrl: string }[] } = {}) {
  const m = () => jest.fn().mockResolvedValue({});
  const prisma: any = {
    user: { findUnique: jest.fn().mockResolvedValue(user), update: m() },
    companyMember: { count: jest.fn().mockResolvedValue(otherMembers), update: m() },
    deal: { count: jest.fn().mockResolvedValue(activeDeals) },
    verificationDocument: { findMany: jest.fn().mockResolvedValue(documents), deleteMany: m() },
    identifier: { deleteMany: m() },
    documentRecognition: { deleteMany: m() },
    deviceToken: { deleteMany: m() },
    session: { updateMany: m() },
    driver: { update: m() },
    vehicle: { updateMany: m() },
    arrival: { updateMany: m() },
    response: { updateMany: m() },
    company: { update: m() },
    cargo: { updateMany: m() },
    auditLog: { create: m() },
  };
  prisma.$transaction = jest.fn((fn: (tx: unknown) => Promise<unknown>) => fn(prisma));
  const uploads: any = { removeDocument: jest.fn().mockResolvedValue(undefined) };
  return { prisma, uploads, service: new AccountDeletionService(prisma, uploads) };
}

const driverUser = {
  id: 'u1',
  role: 'DRIVER',
  deletedAt: null,
  driver: { id: 'd1', vehicles: [{ id: 'v1' }, { id: 'v2' }] },
  companyMember: null,
};

describe('AccountDeletionService', () => {
  it('водитель: ПДн обезличены, сессии отозваны, документы и идентификаторы удалены', async () => {
    const docs = [{ id: 'doc1', fileUrl: '11111111-1111-4111-8111-111111111111.jpg' }];
    const { prisma, uploads, service } = setup(driverUser, { documents: docs });
    await service.deleteAccount('u1');

    const userData = prisma.user.update.mock.calls[0][0].data;
    expect(userData).toMatchObject({ phone: null, email: null, passwordHash: null, name: null, isActive: false });
    expect(userData.deletedAt).toBeInstanceOf(Date);
    expect(prisma.driver.update.mock.calls[0][0].data).toMatchObject({ fullName: DELETED_NAME, isVerified: false, currentLat: null });
    expect(prisma.vehicle.updateMany.mock.calls[0][0].data).toMatchObject({ plateNumber: null, vin: null });
    expect(prisma.session.updateMany.mock.calls[0][0].where).toEqual({ userId: 'u1', revokedAt: null });
    expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith({ where: { userId: 'u1' } });
    expect(prisma.verificationDocument.deleteMany).toHaveBeenCalledWith({ where: { id: { in: ['doc1'] } } });
    const identifierOr = prisma.identifier.deleteMany.mock.calls[0][0].where.OR;
    expect(identifierOr).toEqual(
      expect.arrayContaining([
        { ownerType: 'DRIVER', ownerId: 'd1' },
        { ownerType: 'VEHICLE', ownerId: { in: ['v1', 'v2'] } },
        { sourceDocumentId: { in: ['doc1'] } },
      ]),
    );
    expect(uploads.removeDocument).toHaveBeenCalledWith(docs[0].fileUrl);
    expect(prisma.arrival.updateMany.mock.calls[0][0].data).toEqual({ status: 'CANCELLED' });
    // Журнал — без ПДн.
    expect(JSON.stringify(prisma.auditLog.create.mock.calls[0][0])).not.toMatch(/phone|email|\+7/);
  });

  it('активная сделка — отказ, ничего не меняется', async () => {
    const { prisma, service } = setup(driverUser, { activeDeals: 1 });
    await expect(service.deleteAccount('u1')).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('владелец компании с сотрудниками — сначала передать владение', async () => {
    const owner = { id: 'u2', role: 'COMPANY', deletedAt: null, driver: null, companyMember: { id: 'm1', companyId: 'c1', role: 'OWNER' } };
    const { prisma, service } = setup(owner, { otherMembers: 2 });
    await expect(service.deleteAccount('u2')).rejects.toMatchObject({ response: { code: 'OWNER_HAS_MEMBERS' } });
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('единственный владелец: контакты сотрудника стёрты, вебхук снят, опубликованные грузы закрыты', async () => {
    const owner = { id: 'u2', role: 'COMPANY', deletedAt: null, driver: null, companyMember: { id: 'm1', companyId: 'c1', role: 'OWNER' } };
    const { prisma, service } = setup(owner);
    await service.deleteAccount('u2');
    expect(prisma.companyMember.update.mock.calls[0][0].data).toEqual({ fullName: null, contactPhone: null, wechatId: null });
    expect(prisma.company.update.mock.calls[0][0].data).toEqual({ wecomWebhookUrl: null });
    expect(prisma.cargo.updateMany.mock.calls[0][0]).toMatchObject({ where: { companyId: 'c1', status: 'PUBLISHED' }, data: { status: 'CANCELLED' } });
  });

  it('логист-сотрудник: компания и её грузы не трогаются', async () => {
    const logist = { id: 'u3', role: 'COMPANY', deletedAt: null, driver: null, companyMember: { id: 'm2', companyId: 'c1', role: 'LOGIST' } };
    const { prisma, service } = setup(logist);
    await service.deleteAccount('u3');
    expect(prisma.company.update).not.toHaveBeenCalled();
    expect(prisma.cargo.updateMany).not.toHaveBeenCalled();
    expect(prisma.deal.count).not.toHaveBeenCalled();
  });

  it('админ так не удаляется; повторное удаление — 404', async () => {
    await expect(setup({ id: 'a', role: 'ADMIN', deletedAt: null, driver: null, companyMember: null }).service.deleteAccount('a')).rejects.toBeInstanceOf(ForbiddenException);
    await expect(setup({ ...driverUser, deletedAt: new Date() }).service.deleteAccount('u1')).rejects.toBeInstanceOf(NotFoundException);
  });
});
