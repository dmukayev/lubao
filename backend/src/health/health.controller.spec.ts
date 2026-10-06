import { ServiceUnavailableException } from '@nestjs/common';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  function setup(over: { prisma?: jest.Mock; redis?: jest.Mock; minio?: jest.Mock } = {}) {
    const prisma = { $queryRaw: over.prisma ?? jest.fn().mockResolvedValue([{ '?column?': 1 }]) };
    const redis = { client: { ping: over.redis ?? jest.fn().mockResolvedValue('PONG') } };
    const uploads = { ping: over.minio ?? jest.fn().mockResolvedValue(undefined) };
    return { controller: new HealthController(prisma as any, redis as any, uploads as any), prisma, redis, uploads };
  }

  it('returns ok for liveness check', () => {
    expect(setup().controller.check()).toEqual({ status: 'ok' });
  });

  it('returns ok when the database responds', async () => {
    const { controller, prisma } = setup();
    await expect(controller.checkDb()).resolves.toEqual({ status: 'ok' });
    expect(prisma.$queryRaw).toHaveBeenCalled();
  });

  describe('/health/ready (задача 043, п.6)', () => {
    it('всё отвечает — ok по каждой зависимости', async () => {
      await expect(setup().controller.ready()).resolves.toEqual({ status: 'ok', checks: { postgres: 'ok', redis: 'ok', minio: 'ok' } });
    });

    it.each([
      ['Postgres', { prisma: jest.fn().mockRejectedValue(new Error('conn refused')) }, { postgres: 'down', redis: 'ok', minio: 'ok' }],
      ['Redis', { redis: jest.fn().mockRejectedValue(new Error('ECONNREFUSED')) }, { postgres: 'ok', redis: 'down', minio: 'ok' }],
      ['MinIO', { minio: jest.fn().mockRejectedValue(new Error('bucket missing')) }, { postgres: 'ok', redis: 'ok', minio: 'down' }],
    ])('%s не отвечает — 503 и понятно какая зависимость', async (_name, over, checks) => {
      const { controller } = setup(over as never);
      const error = await controller.ready().catch((e) => e);
      expect(error).toBeInstanceOf(ServiceUnavailableException);
      expect(error.getResponse()).toEqual({ status: 'degraded', checks });
    });

    it('текст ошибки зависимости наружу не уходит', async () => {
      const { controller } = setup({ prisma: jest.fn().mockRejectedValue(new Error('password authentication failed for user "lubao"')) });
      const error = await controller.ready().catch((e) => e);
      expect(JSON.stringify(error.getResponse())).not.toContain('password');
    });
  });
});
