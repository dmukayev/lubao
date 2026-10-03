import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { PrismaService } from '../prisma/prisma.service';

describe('HealthController', () => {
  let controller: HealthController;
  const prismaMock = { $queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]) };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [{ provide: PrismaService, useValue: prismaMock }],
    }).compile();

    controller = module.get<HealthController>(HealthController);
  });

  it('returns ok for liveness check', () => {
    expect(controller.check()).toEqual({ status: 'ok' });
  });

  it('returns ok when the database responds', async () => {
    await expect(controller.checkDb()).resolves.toEqual({ status: 'ok' });
    expect(prismaMock.$queryRaw).toHaveBeenCalled();
  });
});
