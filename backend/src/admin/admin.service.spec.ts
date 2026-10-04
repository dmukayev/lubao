import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AdminService } from './admin.service';

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
    service = new AdminService(prisma);
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
