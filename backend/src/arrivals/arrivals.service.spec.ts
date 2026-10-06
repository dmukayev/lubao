import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ArrivalsService } from './arrivals.service';

function makeTxPrisma() {
  const arrival = {
    create: jest.fn(),
    update: jest.fn(),
  };
  const arrivalDirection = {
    deleteMany: jest.fn().mockResolvedValue(undefined),
    createMany: jest.fn().mockResolvedValue(undefined),
  };
  return { arrival, arrivalDirection };
}

function makePrisma() {
  const tx = makeTxPrisma();
  const prisma: any = {
    driver: { findUnique: jest.fn() },
    point: { findUnique: jest.fn(), findFirst: jest.fn() },
    arrival: {
      findFirst: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
      updateMany: jest.fn().mockResolvedValue({ count: 0 }),
      create: jest.fn(),
      update: jest.fn(),
    },
    arrivalDirection: {
      findMany: jest.fn().mockResolvedValue([]),
      deleteMany: jest.fn().mockResolvedValue(undefined),
      createMany: jest.fn().mockResolvedValue(undefined),
    },
    arrivalView: {
      count: jest.fn().mockResolvedValue(0),
      createMany: jest.fn().mockResolvedValue(undefined),
    },
    vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
    // Задача 037, п.7 — «Уже везёт…» в «Кто будет на точке».
    deal: { findMany: jest.fn().mockResolvedValue([]), groupBy: jest.fn().mockResolvedValue([]) },
    driverDirection: { findMany: jest.fn().mockResolvedValue([]) },
    $transaction: jest.fn(async (fn: any) => fn(tx)),
    __tx: tx,
  };
  return prisma;
}

describe('ArrivalsService.announce', () => {
  let prisma: ReturnType<typeof makePrisma>;
  let service: ArrivalsService;

  beforeEach(() => {
    prisma = makePrisma();
    service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
    prisma.point.findUnique.mockResolvedValue({ id: 'point-1', isActive: true });
  });

  it('rejects plannedAt more than 14 days in the future', async () => {
    prisma.arrival.findFirst.mockResolvedValue(null);
    const farFuture = new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString();

    await expect(
      service.announce('user-1', { pointId: 'point-1', plannedAt: farFuture }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects an unknown or inactive point', async () => {
    prisma.point.findUnique.mockResolvedValue(null);
    await expect(
      service.announce('user-1', { pointId: 'missing', plannedAt: new Date().toISOString() }),
    ).rejects.toThrow(NotFoundException);
  });

  it('creates a new PLANNED arrival with trip-specific directions when none is active', async () => {
    prisma.arrival.findFirst.mockResolvedValue(null);
    prisma.__tx.arrival.create.mockResolvedValue({
      id: 'arrival-1',
      pointId: 'point-1',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: null,
      waitDays: 2,
      anyCountry: false,
      status: 'PLANNED',
    });

    await service.announce('user-1', {
      pointId: 'point-1',
      plannedAt: new Date().toISOString(),
      countryIds: ['kz', 'uz'],
      waitDays: 3,
    });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ driverId: 'driver-1', status: 'PLANNED', waitDays: 3 }) }),
    );
    expect(prisma.__tx.arrivalDirection.createMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: [
          { arrivalId: 'arrival-1', countryId: 'kz' },
          { arrivalId: 'arrival-1', countryId: 'uz' },
        ],
      }),
    );
  });

  it('replaces the existing PLANNED arrival instead of creating a duplicate', async () => {
    prisma.arrival.findFirst.mockResolvedValue({ id: 'arrival-1', status: 'PLANNED' });
    prisma.__tx.arrival.update.mockResolvedValue({
      id: 'arrival-1',
      pointId: 'point-2',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: null,
      waitDays: 2,
      anyCountry: false,
      status: 'PLANNED',
    });

    await service.announce('user-1', { pointId: 'point-2', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).not.toHaveBeenCalled();
    expect(prisma.__tx.arrival.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'arrival-1' }, data: expect.objectContaining({ pointId: 'point-2' }) }),
    );
  });

  it('does not move an ON_SITE arrival back to PLANNED or change its point — only trip details', async () => {
    prisma.arrival.findFirst.mockResolvedValue({ id: 'arrival-1', status: 'ON_SITE' });
    prisma.__tx.arrival.update.mockResolvedValue({
      id: 'arrival-1',
      pointId: 'point-1',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: new Date(),
      waitDays: 1,
      anyCountry: true,
      status: 'ON_SITE',
    });

    await service.announce('user-1', { pointId: 'point-99', plannedAt: new Date().toISOString(), anyCountry: true, waitDays: 1 });

    const call = prisma.__tx.arrival.update.mock.calls[0][0];
    expect(call.data.status).toBeUndefined();
    expect(call.data.pointId).toBeUndefined();
    expect(call.data).toEqual({ anyCountry: true, waitDays: 1 });
  });
});

describe('ArrivalsService.checkIn', () => {
  let prisma: ReturnType<typeof makePrisma>;
  let service: ArrivalsService;

  beforeEach(() => {
    prisma = makePrisma();
    service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
  });

  it('transitions an existing PLANNED arrival to ON_SITE', async () => {
    prisma.arrival.findFirst.mockResolvedValue({ id: 'arrival-1', status: 'PLANNED' });
    prisma.arrival.update.mockResolvedValue({
      id: 'arrival-1',
      pointId: 'point-1',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: new Date(),
      waitDays: 2,
      anyCountry: false,
      status: 'ON_SITE',
    });

    const result = await service.checkIn('user-1');
    expect(prisma.arrival.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'arrival-1' }, data: expect.objectContaining({ status: 'ON_SITE' }) }),
    );
    expect(result.status).toBe('ON_SITE');
  });

  it('creates a fresh ON_SITE arrival when there is none active (quick check-in)', async () => {
    prisma.arrival.findFirst.mockResolvedValue(null);
    prisma.point.findFirst.mockResolvedValue({ id: 'point-1', isActive: true });
    prisma.__tx.arrival.create.mockResolvedValue({
      id: 'arrival-1',
      pointId: 'point-1',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: new Date(),
      waitDays: 2,
      anyCountry: false,
      status: 'ON_SITE',
    });

    const result = await service.checkIn('user-1');
    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'ON_SITE' }) }),
    );
    expect(result.status).toBe('ON_SITE');
  });
});

describe('ArrivalsService.getMine — lazy expiry', () => {
  it('cancels a stale PLANNED arrival (plannedAt > 24h in the past) and returns null', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    prisma.arrival.findFirst.mockResolvedValue(null);

    const result = await service.getMine('user-1');

    expect(prisma.arrival.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ driverId: 'driver-1', status: 'PLANNED' }),
        data: { status: 'CANCELLED' },
      }),
    );
    expect(result).toEqual({ arrival: null });
  });
});

describe('ArrivalsService.repeat', () => {
  it('throws when there is no previous announcement', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    prisma.arrival.findFirst.mockResolvedValue(null);

    await expect(service.repeat('user-1')).rejects.toThrow(NotFoundException);
  });

  it('re-announces with the same point and countries as the last finished arrival', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
    prisma.point.findUnique.mockResolvedValue({ id: 'point-1', isActive: true });

    // getLastTemplate() call
    prisma.arrival.findFirst.mockResolvedValueOnce({ id: 'old-arrival', pointId: 'point-1', anyCountry: false });
    prisma.arrivalDirection.findMany.mockResolvedValueOnce([{ countryId: 'kz' }]);
    // announce()'s own lookup for an existing active arrival
    prisma.arrival.findFirst.mockResolvedValueOnce(null);
    prisma.__tx.arrival.create.mockResolvedValue({
      id: 'new-arrival',
      pointId: 'point-1',
      plannedAt: new Date(),
      plannedDay: new Date(),
      arrivedAt: null,
      waitDays: 2,
      anyCountry: false,
      status: 'PLANNED',
    });

    await service.repeat('user-1');

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ pointId: 'point-1' }) }),
    );
    expect(prisma.__tx.arrivalDirection.createMany).toHaveBeenCalledWith(
      expect.objectContaining({ data: [{ arrivalId: 'new-arrival', countryId: 'kz' }] }),
    );
  });
});

describe('ArrivalsService.listForCompany', () => {
  let prisma: ReturnType<typeof makePrisma>;
  let service: ArrivalsService;
  const today = new Date();
  const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
  const dayOf = (d: Date) => new Date(d.toISOString().slice(0, 10) + 'T00:00:00.000Z');

  function driverRow(overrides: Record<string, unknown>) {
    return {
      id: 'arrival-x',
      pointId: 'point-1',
      status: 'PLANNED',
      plannedAt: today,
      plannedDay: dayOf(today),
      anyCountry: false,
      directions: [],
      driver: { id: 'driver-1', fullName: 'Ерлан', isVerified: true, ratingAvg: 0, ratingCount: 0, user: { phone: '+7' } },
      ...overrides,
    };
  }

  beforeEach(() => {
    prisma = makePrisma();
    service = new ArrivalsService(prisma);
  });

  it('filters by the trip-specific directions on the Arrival, not the driver profile', async () => {
    prisma.arrival.findMany.mockResolvedValue([
      driverRow({ id: 'a1', anyCountry: false, directions: [{ countryId: 'uz' }] }),
      driverRow({ id: 'a2', anyCountry: false, directions: [{ countryId: 'kz' }] }),
    ]);

    const result = await service.listForCompany('company-1', { countryId: 'uz' });
    expect(result).toHaveLength(1);
    expect(result[0].directionCountryIds).toEqual(['uz']);
  });

  it('for "today" includes ON_SITE regardless of plannedAt, and PLANNED only if planned for today', async () => {
    prisma.arrival.findMany.mockResolvedValue([
      driverRow({ id: 'on-site', status: 'ON_SITE', plannedAt: new Date('2000-01-01') }),
      driverRow({ id: 'planned-today', status: 'PLANNED', plannedAt: today, plannedDay: dayOf(today) }),
      driverRow({ id: 'planned-tomorrow', status: 'PLANNED', plannedAt: tomorrow, plannedDay: dayOf(tomorrow) }),
    ]);

    const result = await service.listForCompany('company-1', {});
    const ids = result.map((r) => r.arrivalId);
    expect(ids).toEqual(expect.arrayContaining(['on-site', 'planned-today']));
    expect(ids).not.toContain('planned-tomorrow');
  });

  it('for a future day only returns PLANNED arrivals for that exact day', async () => {
    prisma.arrival.findMany.mockResolvedValue([
      driverRow({ id: 'planned-tomorrow', status: 'PLANNED', plannedAt: tomorrow, plannedDay: dayOf(tomorrow) }),
      driverRow({ id: 'planned-today', status: 'PLANNED', plannedAt: today, plannedDay: dayOf(today) }),
    ]);

    const result = await service.listForCompany('company-1', { date: tomorrow.toISOString().slice(0, 10), today: today.toISOString().slice(0, 10) });
    expect(result.map((r) => r.arrivalId)).toEqual(['planned-tomorrow']);
  });

  it('041, п.5: вторник из Урумчи (UTC+8) и Алматы (UTC+5) — один день, сервер без пересчёта часовых поясов', async () => {
    const tuesday = new Date('2026-10-06T00:00:00.000Z'); // колонка DATE
    prisma.arrival.findMany.mockResolvedValue([
      // 00:30 вторника по Урумчи = 16:30 понедельника UTC; 23:30 вторника по Алматы = 18:30 UTC
      driverRow({ id: 'urumqi', status: 'PLANNED', plannedAt: new Date('2026-10-05T16:30:00.000Z'), plannedDay: tuesday }),
      driverRow({ id: 'almaty', status: 'PLANNED', plannedAt: new Date('2026-10-06T18:30:00.000Z'), plannedDay: tuesday }),
      driverRow({ id: 'wednesday', status: 'PLANNED', plannedAt: new Date('2026-10-06T19:30:00.000Z'), plannedDay: new Date('2026-10-07T00:00:00.000Z') }),
    ]);

    const result = await service.listForCompany('company-1', { date: '2026-10-06', today: '2026-10-05' });

    expect(result.map((r) => r.arrivalId).sort()).toEqual(['almaty', 'urumqi']);
  });

  it('records a view (unique per arrival+company) for every arrival returned', async () => {
    prisma.arrival.findMany.mockResolvedValue([driverRow({ id: 'a1' })]);
    await service.listForCompany('company-9', {});
    expect(prisma.arrivalView.createMany).toHaveBeenCalledWith({
      data: [{ arrivalId: 'a1', companyId: 'company-9' }],
      skipDuplicates: true,
    });
  });
});

describe('ArrivalsService.summary', () => {
  it('counts ON_SITE + today-PLANNED for day 0, and only same-day PLANNED for later days', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    const today = new Date();
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    prisma.arrival.findMany.mockResolvedValue([
      { plannedAt: new Date('2000-01-01'), status: 'ON_SITE' },
      { plannedDay: new Date(today.toISOString().slice(0, 10) + 'T00:00:00.000Z'), status: 'PLANNED' },
      { plannedDay: new Date(tomorrow.toISOString().slice(0, 10) + 'T00:00:00.000Z'), status: 'PLANNED' },
    ]);

    const result = await service.summary(2);
    expect(result[0].count).toBe(2);
    expect(result[1].count).toBe(1);
  });

  it('does not double-count an ON_SITE arrival under a future day just because plannedAt lands there', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    const today = new Date();
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);

    // Собирался завтра, но уже на месте сегодня (приехал раньше).
    prisma.arrival.findMany.mockResolvedValue([{ plannedDay: new Date(tomorrow.toISOString().slice(0, 10) + 'T00:00:00.000Z'), status: 'ON_SITE' }]);

    const result = await service.summary(2);
    expect(result[0].count).toBe(1);
    expect(result[1].count).toBe(0);
  });
});

describe('ArrivalsService.announce — связка «на чём еду» (задача 031, этап B, п.9)', () => {
  let prisma: ReturnType<typeof makePrisma>;
  let service: ArrivalsService;

  beforeEach(() => {
    prisma = makePrisma();
    service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
    prisma.point.findUnique.mockResolvedValue({ id: 'point-1', isActive: true });
    prisma.vehicle.findMany = jest.fn();
  });

  it('defaults a brand-new arrival to the combo of the last announcement that had one', async () => {
    prisma.arrival.findFirst
      .mockResolvedValueOnce(null) // no active arrival
      .mockResolvedValueOnce({ tractorId: 'old-tractor', trailerId: 'old-trailer' }); // last with combo
    // 038: прошлая связка проверяется на архивность — обе машины живы.
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'old-tractor', kind: 'TRACTOR' }, { id: 'old-trailer', kind: 'TRAILER' }]);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'old-tractor', trailerId: 'old-trailer' }) }),
    );
  });

  it('039 п.5: у прошлой связки RIGID прицеп не подставляется, прицеп вместо тягача отбрасывается', async () => {
    prisma.arrival.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ tractorId: 'old-rigid', trailerId: 'old-trailer' });
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'old-rigid', kind: 'RIGID' }, { id: 'old-trailer', kind: 'TRAILER' }]);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'old-rigid', trailerId: null }) }),
    );
  });

  it('039 п.5: тягач прошлой связки в архиве — её прицеп не подставляется, берём из гаража', async () => {
    prisma.arrival.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ tractorId: 'old-tractor', trailerId: 'old-trailer' });
    // В живых остался только старый прицеп; тягач заархивирован.
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'old-trailer', kind: 'TRAILER' }]);
    prisma.vehicle.findFirst = jest.fn().mockImplementation(async ({ where }: any) =>
      where.kind === 'TRAILER' ? { id: 'garage-trailer', kind: 'TRAILER' } : { id: 'garage-tractor', kind: 'TRACTOR' },
    );
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'garage-tractor', trailerId: 'garage-trailer' }) }),
    );
  });

  it('uses an explicit combo from the dto after validating it belongs to this driver', async () => {
    prisma.arrival.findFirst.mockResolvedValue(null);
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'tractor-9', kind: 'TRACTOR' }, { id: 'trailer-9', kind: 'TRAILER' }]);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString(), tractorId: 'tractor-9', trailerId: 'trailer-9' });

    expect(prisma.vehicle.findMany).toHaveBeenCalledWith({
      where: { id: { in: ['tractor-9', 'trailer-9'] }, driverId: 'driver-1', isArchived: false },
    });
    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'tractor-9', trailerId: 'trailer-9' }) }),
    );
  });

  it('rejects a combo that references a vehicle outside this driver\'s garage', async () => {
    prisma.arrival.findFirst.mockResolvedValue(null);
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'tractor-9' }]); // trailer-9 missing/not owned

    await expect(
      service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString(), tractorId: 'tractor-9', trailerId: 'trailer-9' }),
    ).rejects.toThrow(BadRequestException);
  });
});

describe('ArrivalsService.announce — типы связки (задача 032, п.12 / 038)', () => {
  function setup(vehicles: Array<{ id: string; kind: string }>) {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
    prisma.point.findUnique.mockResolvedValue({ id: 'point-1', isActive: true });
    prisma.arrival.findFirst.mockResolvedValue(null);
    prisma.vehicle.findMany = jest.fn().mockResolvedValue(vehicles);
    return { service };
  }
  const base = { pointId: 'point-1', plannedAt: new Date().toISOString() };

  it('прицеп в поле tractorId отклоняется', async () => {
    const { service } = setup([{ id: 't1', kind: 'TRAILER' }]);
    await expect(service.announce('u1', { ...base, tractorId: 't1' })).rejects.toThrow('tractorId must be');
  });

  it('тягач в поле trailerId отклоняется', async () => {
    const { service } = setup([{ id: 'x1', kind: 'TRACTOR' }]);
    await expect(service.announce('u1', { ...base, trailerId: 'x1' })).rejects.toThrow('trailerId must be a trailer');
  });

  it('у RIGID-одиночки не бывает прицепа', async () => {
    const { service } = setup([{ id: 'r1', kind: 'RIGID' }, { id: 'tr1', kind: 'TRAILER' }]);
    await expect(service.announce('u1', { ...base, tractorId: 'r1', trailerId: 'tr1' })).rejects.toThrow('rigid truck has no trailer');
  });
});
