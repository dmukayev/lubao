import { NotFoundException } from '@nestjs/common';
import { DriversService } from './drivers.service';

describe('DriversService#updateProfile', () => {
  let prisma: any;
  let service: DriversService;

  beforeEach(() => {
    prisma = {
      city: { findUnique: jest.fn() },
      driver: { findUnique: jest.fn() },
    };
    service = new DriversService(prisma);
  });

  it('throws NotFoundException for a non-existent homeCityId, without touching the driver record', async () => {
    prisma.city.findUnique.mockResolvedValue(null);

    await expect(
      service.updateProfile('user-1', {
        fullName: 'Ерлан Қасымов',
        homeCityId: 'missing-city',
        anyCountry: true,
        directionCountryIds: [],
        permitIds: [],
        bodyTypeId: 'body-1',
      } as any),
    ).rejects.toThrow(NotFoundException);

    expect(prisma.driver.findUnique).not.toHaveBeenCalled();
  });
});
