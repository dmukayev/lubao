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
    prisma = { vehicle: { findMany: jest.fn(), create: jest.fn(), findUnique: jest.fn(), update: jest.fn() }, verificationDocument: { findMany: jest.fn().mockResolvedValue([]) } };
    // 032 п.12 (038) — машина+документ создаются одной транзакцией.
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
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

    await service.createVehicle('u1', 'd1', { kind: 'TRACTOR', bodyTypeId: 'bt1', plateNumber: 'B2', vin: 'VIN123', brand: 'MAN', capacityTons: 20, lengthM: 13.6 } as any);

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

describe('DriversService#updateProfile — подтверждение телефона при регистрации (задача 031, этап C, п.15)', () => {
  it('confirms the PHONE identifier for a brand-new driver, not for an existing one being edited', async () => {
    const identifiers = { confirmIdentifier: jest.fn() };
    const prisma: any = {
      city: { findUnique: jest.fn().mockResolvedValue({ id: 'city-1' }) },
      driver: {
        findUnique: jest.fn().mockResolvedValue(null), // no existing profile — this is a new registration
        findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'd1' }),
      },
      driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
      driverPermit: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      verificationDocument: { findFirst: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'user-1', phone: '+77011234501' }) },
      $transaction: jest.fn(async (cb: any) =>
        cb({
          driver: { create: jest.fn().mockResolvedValue({ id: 'd1' }), update: jest.fn() },
          driverDirection: { deleteMany: jest.fn(), createMany: jest.fn() },
          driverPermit: { deleteMany: jest.fn(), createMany: jest.fn() },
      bodyType: { findUnique: jest.fn().mockResolvedValue(null) },
          vehicle: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'v1' }) },
        }),
      ),
    };
    const service = new DriversService(prisma, identifiers as any);

    await service.updateProfile('user-1', {
      fullName: 'Ерлан Қасымов',
      homeCityId: 'city-1',
      anyCountry: true,
      directionCountryIds: [],
      permitIds: [],
      bodyTypeId: 'body-1',
    } as any);

    expect(identifiers.confirmIdentifier).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'PHONE', rawValue: '+77011234501', ownerType: 'DRIVER', ownerId: 'd1' }),
    );
  });

  it('does not re-confirm the phone when editing an already-registered profile', async () => {
    const identifiers = { confirmIdentifier: jest.fn() };
    const prisma: any = {
      city: { findUnique: jest.fn().mockResolvedValue({ id: 'city-1' }) },
      driver: {
        findUnique: jest.fn().mockResolvedValue({ id: 'd1' }), // already has a profile
        findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'd1' }),
      },
      driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
      driverPermit: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      verificationDocument: { findFirst: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn() },
      $transaction: jest.fn(async (cb: any) =>
        cb({
          driver: { update: jest.fn().mockResolvedValue({ id: 'd1' }), create: jest.fn() },
          driverDirection: { deleteMany: jest.fn(), createMany: jest.fn() },
          driverPermit: { deleteMany: jest.fn(), createMany: jest.fn() },
      bodyType: { findUnique: jest.fn().mockResolvedValue(null) },
          vehicle: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn().mockResolvedValue({ id: 'v1' }) },
        }),
      ),
    };
    const service = new DriversService(prisma, identifiers as any);

    await service.updateProfile('user-1', {
      fullName: 'Ерлан Қасымов',
      homeCityId: 'city-1',
      anyCountry: true,
      directionCountryIds: [],
      permitIds: [],
      bodyTypeId: 'body-1',
    } as any);

    expect(identifiers.confirmIdentifier).not.toHaveBeenCalled();
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });
});

describe('DriversService#documentRecognition — блок «Распознано» на мобильной проверке (задача 031, п.25)', () => {
  it('returns fields without any blacklist/duplicate info — that belongs only to the admin view', async () => {
    const prisma: any = {
      verificationDocument: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'doc1',
          driverId: 'd1',
          recognition: { status: 'DONE', fields: { iin: { value: '850712345611', confidence: 0.95, checksumOk: true, needsReview: false } } },
        }),
      },
    };
    const service = new DriversService(prisma);

    const result = await service.documentRecognition('d1', 'doc1');

    expect(result).toEqual({ status: 'DONE', fields: { iin: { value: '850712345611', confidence: 0.95, checksumOk: true, needsReview: false } } });
  });

  it('отдаёт маску вместо valueMasked/valueEncrypted — шифртекст водителю не нужен и клиенту нужен `value`', async () => {
    const prisma: any = {
      verificationDocument: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'doc1',
          driverId: 'd1',
          recognition: {
            status: 'DONE',
            fields: { iin: { valueMasked: '9503••••2008', valueEncrypted: 'SECRET', confidence: 0.95, checksumOk: true, needsReview: false } },
          },
        }),
      },
    };
    const service = new DriversService(prisma);

    const result: any = await service.documentRecognition('d1', 'doc1');

    expect(result.fields.iin).toEqual({ value: '9503••••2008', confidence: 0.95, checksumOk: true, needsReview: false });
    expect(JSON.stringify(result)).not.toContain('SECRET');
  });

  it('returns PENDING with empty fields when no DocumentRecognition row exists yet', async () => {
    const prisma: any = {
      verificationDocument: { findUnique: jest.fn().mockResolvedValue({ id: 'doc1', driverId: 'd1', recognition: null }) },
    };
    const service = new DriversService(prisma);

    expect(await service.documentRecognition('d1', 'doc1')).toEqual({ status: 'PENDING', fields: {} });
  });

  it('refuses to return another driver\'s document recognition', async () => {
    const prisma: any = {
      verificationDocument: { findUnique: jest.fn().mockResolvedValue({ id: 'doc1', driverId: 'someone-else', recognition: null }) },
    };
    const service = new DriversService(prisma);

    await expect(service.documentRecognition('d1', 'doc1')).rejects.toThrow('Document not found');
  });
});

describe('DriversService.applyPhoneBlacklist — ⛔ по телефону при входе/регистрации (задача 039, п.2)', () => {
  function setup(blocked: boolean, isVerified: boolean) {
    const prisma: any = {
      driver: {
        findUnique: jest.fn().mockResolvedValue({ id: 'd1', isVerified, user: { phone: '+77010000009' } }),
        update: jest.fn(),
      },
    };
    const identifiers: any = {
      checkMatches: jest.fn().mockResolvedValue({ blocked: blocked ? { reason: 'мошенничество', blockedAt: new Date() } : null, duplicateOwner: null }),
      confirmIdentifier: jest.fn(),
    };
    return { prisma, identifiers, service: new DriversService(prisma, identifiers) };
  }

  it('номер в чёрном списке: заводит PHONE-идентификатор и снимает «Проверен»', async () => {
    const { prisma, identifiers, service } = setup(true, true);
    expect(await service.applyPhoneBlacklist('u1')).toBe(true);
    expect(identifiers.confirmIdentifier).toHaveBeenCalledWith(expect.objectContaining({ type: 'PHONE', ownerType: 'DRIVER', ownerId: 'd1' }));
    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { isVerified: false } });
  });

  it('чистый номер: ничего не меняет', async () => {
    const { prisma, identifiers, service } = setup(false, true);
    expect(await service.applyPhoneBlacklist('u1')).toBe(false);
    expect(identifiers.confirmIdentifier).not.toHaveBeenCalled();
    expect(prisma.driver.update).not.toHaveBeenCalled();
  });

  it('нет анкеты водителя (только что вошёл по SMS) — тихо false', async () => {
    const { prisma, service } = setup(true, false);
    prisma.driver.findUnique.mockResolvedValue(null);
    expect(await service.applyPhoneBlacklist('u1')).toBe(false);
  });
});

describe('DriversService.submitVerificationDocument — машина (039, п.5)', () => {
  const dto = (type: string) => ({ type, fileUrl: 'k', vehicleId: 'v1' }) as any;
  const make = (vehicle: any) => {
    const prisma: any = { vehicle: { findUnique: jest.fn().mockResolvedValue(vehicle) }, verificationDocument: { create: jest.fn() } };
    return new DriversService(prisma);
  };

  it('отклоняет техпаспорт для архивной машины', async () => {
    const service = make({ driverId: 'd1', isArchived: true, kind: 'TRACTOR' });
    await expect(service.submitVerificationDocument('u1', 'd1', dto('VEHICLE_PASSPORT'))).rejects.toThrow('archived');
  });

  it('отклоняет паспорт тягача для прицепа', async () => {
    const service = make({ driverId: 'd1', isArchived: false, kind: 'TRAILER' });
    await expect(service.submitVerificationDocument('u1', 'd1', dto('VEHICLE_PASSPORT'))).rejects.toThrow('does not match');
  });
});

describe('DriversService.updateProfile — машины при регистрации не создаются (045 п.5)', () => {
  function setup(existingDriver: any) {
    const tx = {
      driver: { create: jest.fn().mockResolvedValue({ id: 'd1' }), update: jest.fn().mockResolvedValue({ id: 'd1' }) },
      driverDirection: { deleteMany: jest.fn(), createMany: jest.fn() },
      driverPermit: { deleteMany: jest.fn(), createMany: jest.fn() },
      bodyType: { findUnique: jest.fn().mockResolvedValue(null) },
      vehicle: { findFirst: jest.fn(), create: jest.fn(), update: jest.fn() },
      region: { findMany: jest.fn().mockResolvedValue([{ id: 'r-almaty', countryId: 'kz' }, { id: 'r-osh', countryId: 'kg' }]) },
    };
    const prisma: any = {
      city: { findUnique: jest.fn().mockResolvedValue({ id: 'city-1' }) },
      driver: { findUnique: jest.fn().mockResolvedValue(existingDriver), findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'd1', userId: 'u1', isVerified: false, ratingAvg: 0, ratingCount: 0 }) },
      driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
      driverPermit: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      verificationDocument: { findFirst: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn().mockResolvedValue({ phone: null }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    return { tx, service: new DriversService(prisma) };
  }
  const input: any = { fullName: 'Ерлан Қасымов', homeCityId: 'city-1', anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId: 'b1', plateNumber: '123ABC02', capacityTons: 20 };

  it('регистрация: кузов и тоннаж — в предпочтение водителя, машин-заглушек нет', async () => {
    const { tx, service } = setup(null);
    await service.updateProfile('u1', input);
    expect(tx.vehicle.create).not.toHaveBeenCalled();
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: expect.objectContaining({ preferredBodyTypeId: 'b1', preferredCapacityTons: 20 }) });
  });

  it('045 п.7: области раскладываются по своим странам, у страны без областей — вся страна', async () => {
    const { tx, service } = setup(null);
    await service.updateProfile('u1', { ...input, anyCountry: false, directionCountryIds: ['kz', 'uz'], directionRegionIds: ['r-almaty', 'r-osh'] });
    expect(tx.driverDirection.createMany).toHaveBeenCalledWith({
      data: [
        { driverId: 'd1', countryId: 'kz', regionIds: ['r-almaty'] },
        { driverId: 'd1', countryId: 'uz', regionIds: [] },
      ],
    });
  });

  it('регистрация без кузова — 400', async () => {
    const { service } = setup(null);
    await expect(service.updateProfile('u1', { ...input, bodyTypeId: undefined })).rejects.toThrow('bodyTypeId is required');
  });

  it('правка профиля существующего водителя НЕ трогает машины гаража', async () => {
    const { tx, service } = setup({ id: 'd1', userId: 'u1' });
    await service.updateProfile('u1', input);
    expect(tx.vehicle.create).not.toHaveBeenCalled();
    expect(tx.vehicle.update).not.toHaveBeenCalled();
  });
});

describe('DriversService.acceptLicenseName (045 п.10)', () => {
  it('подставляет ФИО из прав в профиль; без ФИО из прав — 400', async () => {
    const prisma: any = {
      driver: {
        findUnique: jest.fn().mockResolvedValue({ id: 'd1', userId: 'u1', fullName: 'Ерлан', licenseFullName: 'Тестов Ерлан Серикович' }),
        update: jest.fn().mockResolvedValue({ id: 'd1', userId: 'u1', fullName: 'Тестов Ерлан Серикович', licenseFullName: 'Тестов Ерлан Серикович', isVerified: true, ratingAvg: 0, ratingCount: 0 }),
      },
      driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
      driverPermit: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      verificationDocument: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new DriversService(prisma);
    await service.acceptLicenseName('u1');
    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { fullName: 'Тестов Ерлан Серикович' } });
    prisma.driver.findUnique.mockResolvedValue({ id: 'd1', userId: 'u1', fullName: 'Ерлан', licenseFullName: null });
    await expect(service.acceptLicenseName('u1')).rejects.toThrow('No full name from the licence');
  });
});

describe('DriversService.updateProfile — «основа» кузова по профилю (048 п.7)', () => {
  const { BODY_TYPE_PROFILES } = require('../../prisma/body-type-profiles');
  function setup(fields: unknown) {
    const tx: any = {
      driver: { create: jest.fn().mockResolvedValue({ id: 'd1', preferredBodyTypeId: null }), update: jest.fn().mockResolvedValue({ id: 'd1' }) },
      driverDirection: { deleteMany: jest.fn(), createMany: jest.fn() },
      driverPermit: { deleteMany: jest.fn(), createMany: jest.fn() },
      bodyType: { findUnique: jest.fn().mockResolvedValue({ fields }) },
      region: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const prisma: any = {
      city: { findUnique: jest.fn().mockResolvedValue({ id: 'city-1' }) },
      driver: { findUnique: jest.fn().mockResolvedValue(null), findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'd1', userId: 'u1', isVerified: false, ratingAvg: 0, ratingCount: 0 }) },
      driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
      driverPermit: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      verificationDocument: { findFirst: jest.fn().mockResolvedValue(null) },
      user: { findUnique: jest.fn().mockResolvedValue({ phone: null }) },
      $transaction: jest.fn(async (cb: any) => cb(tx)),
    };
    return { tx, service: new DriversService(prisma) };
  }
  const input: any = { fullName: 'Ерлан', homeCityId: 'city-1', anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId: 'bt' };

  it('автовоз: места под машины в preferredSpecs, тоннаж не хранится', async () => {
    const { tx, service } = setup(BODY_TYPE_PROFILES.CARCARRIER.fields);
    await service.updateProfile('u1', { ...input, capacityTons: 20, preferredSpecs: { carSlots: 8 } });
    expect(tx.driver.update.mock.calls[0][0].data).toMatchObject({ preferredCapacityTons: null, preferredSpecs: { carSlots: 8 } });
  });

  it('цистерна: литры и продукт; тент — тоннаж', async () => {
    const tank = setup(BODY_TYPE_PROFILES.TANK.fields);
    await tank.service.updateProfile('u1', { ...input, preferredSpecs: { liters: 30000, product: 'FUEL' } });
    expect(tank.tx.driver.update.mock.calls[0][0].data.preferredSpecs).toEqual({ liters: 30000, product: 'FUEL' });
    const tent = setup(BODY_TYPE_PROFILES.TENT.fields);
    await tent.service.updateProfile('u1', { ...input, capacityTons: 20 });
    expect(tent.tx.driver.update.mock.calls[0][0].data).toMatchObject({ preferredCapacityTons: 20, preferredSpecs: { capacityTons: 20 } });
  });
});

