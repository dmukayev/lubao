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

describe('DriversService — гараж (задача 031, этап B)', () => {
  let prisma: any;
  let service: DriversService;

  beforeEach(() => {
    prisma = { vehicle: { findMany: jest.fn(), create: jest.fn(), findUnique: jest.fn(), update: jest.fn() } };
    service = new DriversService(prisma);
  });

  it('listVehicles only returns non-archived vehicles for this driver', async () => {
    prisma.vehicle.findMany.mockResolvedValue([
      { id: 'v1', kind: 'TRACTOR', bodyTypeId: null, plateNumber: 'A1', vin: null, brand: 'Volvo', capacityTons: null, lengthM: null, isOwner: true, isVerified: true, isArchived: false, createdAt: new Date() },
    ]);

    const result = await service.listVehicles('d1');

    expect(prisma.vehicle.findMany).toHaveBeenCalledWith({ where: { driverId: 'd1', isArchived: false }, orderBy: { createdAt: 'asc' } });
    expect(result).toEqual([
      expect.objectContaining({ id: 'v1', kind: 'TRACTOR', plateNumber: 'A1', isVerified: true }),
    ]);
  });

  it('createVehicle clears body/tonnage/length for a TRACTOR (those belong to TRAILER/RIGID)', async () => {
    prisma.vehicle.create.mockResolvedValue({
      id: 'v2', kind: 'TRACTOR', bodyTypeId: null, plateNumber: 'B2', vin: 'VIN123', brand: 'MAN',
      capacityTons: null, lengthM: null, isOwner: true, isVerified: false, isArchived: false, createdAt: new Date(),
    });

    await service.createVehicle('d1', { kind: 'TRACTOR', bodyTypeId: 'bt1', plateNumber: 'B2', vin: 'VIN123', brand: 'MAN', capacityTons: 20, lengthM: 13.6 } as any);

    expect(prisma.vehicle.create).toHaveBeenCalledWith({
      data: { driverId: 'd1', kind: 'TRACTOR', bodyTypeId: null, plateNumber: 'B2', vin: 'VIN123', brand: 'MAN', capacityTons: null, lengthM: null },
    });
  });

  it('archiveVehicle refuses to archive another driver\'s vehicle', async () => {
    prisma.vehicle.findUnique.mockResolvedValue({ id: 'v3', driverId: 'someone-else' });

    await expect(service.archiveVehicle('d1', 'v3')).rejects.toThrow('Vehicle not found');
    expect(prisma.vehicle.update).not.toHaveBeenCalled();
  });
});
