import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { ContactPolicyService } from '../contact-events/contact-policy.service';
import { DriversController } from './drivers.controller';

// 049 п.6: фото машин водителя — только проверенной компании, которой он виден.
describe('DriversController.vehiclePhotos — доступ', () => {
  function setup({ arrival = null as unknown, response = null as unknown, deal = null as unknown } = {}) {
    const prisma: any = {
      arrival: { findFirst: jest.fn().mockResolvedValue(arrival) },
      response: { findFirst: jest.fn().mockResolvedValue(response) },
      deal: { findFirst: jest.fn().mockResolvedValue(deal) },
      verificationDocument: { findMany: jest.fn().mockResolvedValue([]) },
      auditLog: { create: jest.fn() },
    };
    const redis: any = { client: { sadd: jest.fn().mockResolvedValue(1), expire: jest.fn(), scard: jest.fn().mockResolvedValue(1), srem: jest.fn() } };
    const policy = new ContactPolicyService(prisma, redis);
    const controller = new DriversController({} as any, prisma, policy, {} as any, {} as any);
    return { prisma, redis, controller };
  }
  const ctx = (isVerified: boolean) => ({ user: { id: 'logist-1' }, companyMember: { companyId: 'c1', company: { isVerified } } }) as any;

  it('непроверенная компания — 403', async () => {
    await expect(setup({ arrival: { id: 'a' } }).controller.vehiclePhotos(ctx(false), 'd1')).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('водитель компании не виден (нет анонса, отклика, сделки) — 404, перебор id ничего не даёт', async () => {
    await expect(setup().controller.vehiclePhotos(ctx(true), 'd1')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('виден (отклик на её груз) — фото отдаются, лимит считается, открытие в журнале', async () => {
    const { prisma, redis, controller } = setup({ response: { id: 'r1' } });
    await expect(controller.vehiclePhotos(ctx(true), 'd1')).resolves.toEqual([]);
    expect(redis.client.sadd.mock.calls[0][0]).toMatch(/^vehicle-photos:logist-1:/);
    expect(prisma.auditLog.create.mock.calls[0][0].data).toMatchObject({ action: 'VEHICLE_PHOTOS_VIEWED', entityId: 'd1' });
  });
});
