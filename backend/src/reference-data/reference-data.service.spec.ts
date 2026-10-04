import { NotFoundException } from '@nestjs/common';
import { ReferenceDataService } from './reference-data.service';

describe('ReferenceDataService#submitCity', () => {
  let prisma: { region: { findUnique: jest.Mock }; city: { create: jest.Mock } };
  let service: ReferenceDataService;

  beforeEach(() => {
    prisma = {
      region: { findUnique: jest.fn() },
      city: { create: jest.fn() },
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
});
