import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ReferenceDataService } from './reference-data.service';

describe('ReferenceDataService#submitCity', () => {
  let prisma: { region: { findUnique: jest.Mock }; city: { create: jest.Mock; count: jest.Mock } };
  let service: ReferenceDataService;

  beforeEach(() => {
    prisma = {
      region: { findUnique: jest.fn() },
      city: { create: jest.fn(), count: jest.fn().mockResolvedValue(0) },
    };
    service = new ReferenceDataService(prisma as any, { get: jest.fn() } as any);
  });

  it('creates a PENDING city linked to the region, its country, and the submitting user', async () => {
    prisma.region.findUnique.mockResolvedValue({ id: 'region-1', countryId: 'country-1' });
    prisma.city.create.mockResolvedValue({ id: 'city-1' });

    await service.submitCity('user-1', { settlementName: 'Новый посёлок', regionId: 'region-1' });

    expect(prisma.city.create).toHaveBeenCalledWith({
      data: {
        name: { ru: 'Новый посёлок' },
        countryId: 'country-1',
        regionId: 'region-1',
        cityStatus: 'PENDING',
        submittedByUserId: 'user-1',
      },
    });
  });

  it('throws NotFoundException for an unknown regionId', async () => {
    prisma.region.findUnique.mockResolvedValue(null);

    await expect(service.submitCity('user-1', { settlementName: 'X', regionId: 'bad' })).rejects.toThrow(
      NotFoundException,
    );
    expect(prisma.city.create).not.toHaveBeenCalled();
  });

  it('rejects a 4th city submission within 24 hours from the same user (024 п.6)', async () => {
    prisma.city.count.mockResolvedValue(3);

    await expect(
      service.submitCity('user-1', { settlementName: 'X', regionId: 'region-1' }),
    ).rejects.toThrow(BadRequestException);
    expect(prisma.region.findUnique).not.toHaveBeenCalled();
    expect(prisma.city.create).not.toHaveBeenCalled();
  });
});

describe('ReferenceDataService#getAll (видимость городов, 024 п.6)', () => {
  let prisma: { city: { findMany: jest.Mock }; [key: string]: any };
  let service: ReferenceDataService;

  beforeEach(() => {
    prisma = {
      country: { findMany: jest.fn().mockResolvedValue([]) },
      region: { findMany: jest.fn().mockResolvedValue([]) },
      city: { findMany: jest.fn().mockResolvedValue([]) },
      bodyType: { findMany: jest.fn().mockResolvedValue([]) },
      permit: { findMany: jest.fn().mockResolvedValue([]) },
      point: { findMany: jest.fn().mockResolvedValue([]) },
      exchangeRate: { findMany: jest.fn().mockResolvedValue([]) },
    };
    service = new ReferenceDataService(prisma as any, { get: jest.fn().mockResolvedValue(null) } as any);
  });

  it('without a requesting user only asks for APPROVED cities', async () => {
    await service.getAll(undefined);
    expect(prisma.city.findMany).toHaveBeenCalledWith({ where: { OR: [{ cityStatus: 'APPROVED' }] } });
  });

  it('with a requesting user also includes their own PENDING cities, not anyone else’s', async () => {
    await service.getAll('user-1');
    expect(prisma.city.findMany).toHaveBeenCalledWith({
      where: { OR: [{ cityStatus: 'APPROVED' }, { cityStatus: 'PENDING', submittedByUserId: 'user-1' }] },
    });
  });
});
