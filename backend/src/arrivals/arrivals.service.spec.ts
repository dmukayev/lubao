import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ArrivalsService } from './arrivals.service';

function makeTxPrisma() {
  const arrival = {
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn().mockResolvedValue({ count: 0 }),
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

  const todayDay = () => new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00.000Z');
  const savedRow = (over: Record<string, unknown> = {}) => ({
    id: 'arrival-1',
    pointId: 'point-1',
    plannedAt: new Date(),
    plannedDay: todayDay(),
    arrivedAt: null,
    waitDays: 2,
    anyCountry: false,
    status: 'PLANNED',
    ...over,
  });

  it('040: повторный анонс на тот же город и день обновляет существующий, а не плодит дубль', async () => {
    prisma.arrival.findMany.mockResolvedValue([{ id: 'arrival-1', status: 'PLANNED', pointId: 'point-2', plannedDay: todayDay() }]);
    prisma.point.findUnique.mockResolvedValue({ id: 'point-2', isActive: true });
    prisma.__tx.arrival.update.mockResolvedValue(savedRow({ pointId: 'point-2' }));

    await service.announce('user-1', { pointId: 'point-2', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).not.toHaveBeenCalled();
    expect(prisma.__tx.arrival.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'arrival-1' }, data: expect.objectContaining({ pointId: 'point-2' }) }),
    );
  });

  it('040: анонс на другой город создаётся рядом с существующим (несколько анонсов подряд)', async () => {
    prisma.arrival.findMany.mockResolvedValue([{ id: 'arrival-1', status: 'PLANNED', pointId: 'point-1', plannedDay: todayDay() }]);
    prisma.point.findUnique.mockResolvedValue({ id: 'point-2', isActive: true });
    prisma.__tx.arrival.create.mockResolvedValue(savedRow({ id: 'arrival-2', pointId: 'point-2' }));

    await service.announce('user-1', { pointId: 'point-2', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.update).not.toHaveBeenCalled();
    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ pointId: 'point-2' }) }));
  });

  it('040: больше пяти активных анонсов не заводится', async () => {
    prisma.arrival.findMany.mockResolvedValue(
      Array.from({ length: 5 }, (_, i) => ({ id: `a${i}`, status: 'PLANNED', pointId: `p${i}`, plannedDay: todayDay() })),
    );
    await expect(service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() })).rejects.toThrow('TOO_MANY_ARRIVALS');
  });

  it('040: правка по arrivalId меняет город и день и сбрасывает вопрос «Доехали?»', async () => {
    prisma.arrival.findMany.mockResolvedValue([{ id: 'arrival-7', status: 'PLANNED', pointId: 'point-1', plannedDay: todayDay() }]);
    prisma.__tx.arrival.update.mockResolvedValue(savedRow({ id: 'arrival-7' }));

    await service.announce('user-1', { arrivalId: 'arrival-7', pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'arrival-7' }, data: expect.objectContaining({ dayAskedAt: null }) }),
    );
  });

  it('040: arrivalId чужого/угасшего анонса — 404', async () => {
    prisma.arrival.findMany.mockResolvedValue([]);
    await expect(service.announce('user-1', { arrivalId: 'nope', pointId: 'point-1', plannedAt: new Date().toISOString() })).rejects.toThrow(NotFoundException);
  });

  it('does not move an ON_SITE arrival back to PLANNED or change its point — only trip details', async () => {
    prisma.arrival.findMany.mockResolvedValue([{ id: 'arrival-1', status: 'ON_SITE', pointId: 'point-1', plannedDay: new Date() }]);
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

    await service.announce('user-1', { arrivalId: 'arrival-1', pointId: 'point-99', plannedAt: new Date().toISOString(), anyCountry: true, waitDays: 1 });

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

  const row = (over: Record<string, unknown> = {}) => ({
    id: 'arrival-1',
    pointId: 'point-1',
    plannedAt: new Date(),
    plannedDay: new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00.000Z'),
    arrivedAt: null,
    waitDays: 2,
    anyCountry: false,
    status: 'PLANNED',
    ...over,
  });

  it('transitions an existing PLANNED arrival to ON_SITE and records the confirmation', async () => {
    prisma.arrival.findMany.mockResolvedValue([row()]);
    prisma.__tx.arrival.update.mockResolvedValue(row({ status: 'ON_SITE', arrivedAt: new Date() }));

    const result = await service.checkIn('user-1');
    expect(prisma.__tx.arrival.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'arrival-1' }, data: expect.objectContaining({ status: 'ON_SITE', lastConfirmedAt: expect.any(Date) }) }),
    );
    expect(result.status).toBe('ON_SITE');
  });

  it('040: одновременно «на месте» только один анонс — прежний гаснет, когда водитель переехал', async () => {
    prisma.arrival.findMany.mockResolvedValue([
      row({ id: 'old', status: 'ON_SITE', arrivedAt: new Date() }),
      row({ id: 'astana', pointId: 'point-2' }),
    ]);
    prisma.__tx.arrival.update.mockResolvedValue(row({ id: 'astana', pointId: 'point-2', status: 'ON_SITE', arrivedAt: new Date() }));

    await service.checkIn('user-1', 'astana');

    expect(prisma.__tx.arrival.updateMany).toHaveBeenCalledWith({
      where: { driverId: 'driver-1', status: 'ON_SITE', id: { not: 'astana' } },
      data: { status: 'COMPLETED' },
    });
    expect(prisma.__tx.arrival.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'astana' } }));
  });

  it('040: arrivalId чужого анонса — 404', async () => {
    prisma.arrival.findMany.mockResolvedValue([row()]);
    await expect(service.checkIn('user-1', 'someone-elses')).rejects.toThrow(NotFoundException);
  });

  it('creates a fresh ON_SITE arrival when there is none active (quick check-in)', async () => {
    prisma.arrival.findMany.mockResolvedValue([]);
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
  it('040: запланированный анонс, день которого прошёл, гаснет в EXPIRED и не отдаётся', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    const stale = {
      id: 'a-old',
      status: 'PLANNED',
      plannedDay: new Date('2020-01-01T00:00:00.000Z'),
      arrivedAt: null,
      lastConfirmedAt: null,
      dayAskedAt: null,
      staleAskedAt: null,
      waitDays: 2,
      point: { name: {} },
      driver: { userId: 'u1' },
    };
    prisma.arrival.findMany.mockResolvedValueOnce([stale]).mockResolvedValue([]);

    const result = await service.getMine('user-1');

    expect(prisma.arrival.updateMany).toHaveBeenCalledWith({ where: { id: 'a-old', status: 'PLANNED' }, data: { status: 'EXPIRED' } });
    expect(result).toEqual({ arrival: null, arrivals: [] });
  });

  it('040: текущий анонс — тот, где водитель на месте, остальные — по дате', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    const base = { pointId: 'p', plannedAt: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, tractorId: null, trailerId: null, lastConfirmedAt: null, dayAskedAt: null, staleAskedAt: null };
    prisma.arrival.findMany
      .mockResolvedValueOnce([]) // sweep
      .mockResolvedValue([
        { ...base, id: 'planned-soon', status: 'PLANNED', plannedDay: new Date('2999-01-01') },
        { ...base, id: 'here', status: 'ON_SITE', plannedDay: new Date('2999-01-02') },
      ]);

    const result = await service.getMine('user-1');

    expect(result.arrival?.id).toBe('here');
    expect(result.arrivals.map((a) => a.id)).toEqual(['here', 'planned-soon']);
  });
});

describe('ArrivalsService.sweep — правило свежести (задача 040, п.4)', () => {
  const base = { arrivedAt: null, lastConfirmedAt: null, dayAskedAt: null, staleAskedAt: null, waitDays: 3, point: { name: { ru: 'Алматы' } }, driver: { userId: 'u1' } };
  const notifications = { notify: jest.fn().mockResolvedValue(undefined) };
  beforeEach(() => {
    notifications.notify.mockClear();
  });

  it('в день приезда шлёт один «Доехали?» и помечает dayAskedAt (повторный тик молчит)', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma, notifications as any);
    const now = new Date('2026-10-08T07:00:00.000Z'); // 12:00 по Алматы
    prisma.arrival.findMany.mockResolvedValue([{ ...base, id: 'a1', status: 'PLANNED', plannedDay: new Date('2026-10-08T00:00:00.000Z') }]);
    prisma.arrival.updateMany.mockResolvedValueOnce({ count: 1 });

    const res = await service.sweep({ now, notify: true });

    expect(res).toEqual({ expired: 0, asked: 1 });
    expect(prisma.arrival.updateMany).toHaveBeenCalledWith({ where: { id: 'a1', status: 'PLANNED', dayAskedAt: null }, data: { dayAskedAt: now } });
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['u1'] }, 'ARRIVAL_DAY_CHECK', { pointName: { ru: 'Алматы' } });
  });

  it('второй инстанс/тик, проигравший условный апдейт, push не шлёт', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma, notifications as any);
    prisma.arrival.findMany.mockResolvedValue([{ ...base, id: 'a1', status: 'PLANNED', plannedDay: new Date('2026-10-08T00:00:00.000Z') }]);
    prisma.arrival.updateMany.mockResolvedValue({ count: 0 });

    const res = await service.sweep({ now: new Date('2026-10-08T07:00:00.000Z'), notify: true });

    expect(res.asked).toBe(0);
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('ленивая проверка при чтении (notify=false) гасит, но push не шлёт', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma, notifications as any);
    prisma.arrival.findMany.mockResolvedValue([
      { ...base, id: 'late', status: 'PLANNED', plannedDay: new Date('2026-10-07T00:00:00.000Z') },
      { ...base, id: 'today', status: 'PLANNED', plannedDay: new Date('2026-10-08T00:00:00.000Z') },
    ]);
    prisma.arrival.updateMany.mockResolvedValue({ count: 1 });

    const res = await service.sweep({ now: new Date('2026-10-08T07:00:00.000Z'), notify: false });

    expect(res).toEqual({ expired: 1, asked: 0 });
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('на месте 12 ч без ответа — «Ещё ищете груз?»', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma, notifications as any);
    const now = new Date('2026-10-08T12:00:00.000Z');
    prisma.arrival.findMany.mockResolvedValue([
      { ...base, id: 'a1', status: 'ON_SITE', plannedDay: new Date('2026-10-08T00:00:00.000Z'), arrivedAt: new Date('2026-10-07T23:00:00.000Z') },
    ]);
    prisma.arrival.updateMany.mockResolvedValue({ count: 1 });

    const res = await service.sweep({ now, notify: true });

    expect(res.asked).toBe(1);
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['u1'] }, 'ARRIVAL_STILL_LOOKING', { pointName: { ru: 'Алматы' } });
  });
});

describe('ArrivalsService.confirmStillLooking / cancel', () => {
  it('«Да, ещё ищу» обновляет lastConfirmedAt у анонса «на месте»', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    prisma.arrival.findFirst.mockResolvedValue({ id: 'a1', status: 'ON_SITE' });
    prisma.arrival.update.mockResolvedValue({ id: 'a1', pointId: 'p', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: new Date(), waitDays: 2, anyCountry: false, status: 'ON_SITE' });

    await service.confirmStillLooking('user-1');

    expect(prisma.arrival.update).toHaveBeenCalledWith({ where: { id: 'a1' }, data: { lastConfirmedAt: expect.any(Date) } });
  });

  it('без анонса «на месте» — 404', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    prisma.arrival.findFirst.mockResolvedValue(null);
    await expect(service.confirmStillLooking('user-1')).rejects.toThrow(NotFoundException);
  });

  it('отмена по arrivalId гасит именно его: запланированный — CANCELLED, «на месте» — COMPLETED', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1' });
    const plannedDay = new Date('2999-01-01');
    prisma.arrival.findMany.mockResolvedValue([
      { id: 'here', status: 'ON_SITE', plannedDay },
      { id: 'later', status: 'PLANNED', plannedDay },
    ]);
    prisma.arrival.update.mockResolvedValue({ id: 'later', pointId: 'p', plannedAt: new Date(), plannedDay, arrivedAt: null, waitDays: 2, anyCountry: false, status: 'CANCELLED' });

    await service.cancel('user-1', 'later');

    expect(prisma.arrival.update).toHaveBeenCalledWith({ where: { id: 'later' }, data: { status: 'CANCELLED' } });
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

    prisma.arrival.findMany.mockResolvedValueOnce([]).mockResolvedValue([
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
    prisma.arrival.findMany.mockResolvedValueOnce([]).mockResolvedValue([{ plannedDay: new Date(tomorrow.toISOString().slice(0, 10) + 'T00:00:00.000Z'), status: 'ON_SITE' }]);

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
    prisma.arrival.findFirst.mockResolvedValueOnce({ tractorId: 'old-tractor', trailerId: 'old-trailer' }); // last with combo
    // 038: прошлая связка проверяется на архивность — обе машины живы.
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'old-tractor', kind: 'TRACTOR' }, { id: 'old-trailer', kind: 'TRAILER' }]);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'old-tractor', trailerId: 'old-trailer' }) }),
    );
  });

  it('039 п.5: у прошлой связки RIGID прицеп не подставляется, прицеп вместо тягача отбрасывается', async () => {
    prisma.arrival.findFirst.mockResolvedValueOnce({ tractorId: 'old-rigid', trailerId: 'old-trailer' });
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'old-rigid', kind: 'RIGID' }, { id: 'old-trailer', kind: 'TRAILER' }]);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'arrival-1', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.announce('user-1', { pointId: 'point-1', plannedAt: new Date().toISOString() });

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ tractorId: 'old-rigid', trailerId: null }) }),
    );
  });

  it('039 п.5: тягач прошлой связки в архиве — её прицеп не подставляется, берём из гаража', async () => {
    prisma.arrival.findFirst.mockResolvedValueOnce({ tractorId: 'old-tractor', trailerId: 'old-trailer' });
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

describe('ArrivalsService — «сегодня» от клиента (041, п.13)', () => {
  const NOW = new Date('2026-10-07T19:30:00.000Z'); // сервер в Алматы: уже 8 октября, 00:30

  it('resolveToday берёт календарь клиента (водитель в UTC+5 и логист в UTC+8 видят свой день)', () => {
    expect(ArrivalsService.resolveToday('2026-10-07', NOW)).toBe('2026-10-07');
    expect(ArrivalsService.resolveToday('2026-10-08', NOW)).toBe('2026-10-08');
  });

  it('нет значения, мусор или дальше ±2 суток — серверное «сегодня» по Алматы', () => {
    expect(ArrivalsService.resolveToday(undefined, NOW)).toBe('2026-10-08');
    expect(ArrivalsService.resolveToday('вчера', NOW)).toBe('2026-10-08');
    expect(ArrivalsService.resolveToday('2020-01-01', NOW)).toBe('2026-10-08');
    expect(ArrivalsService.resolveToday('2026-10-20', NOW)).toBe('2026-10-08');
  });

  it('repeat(): анонс создаётся на день клиента, а не на серверную дату', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: false });
    prisma.point.findUnique.mockResolvedValue({ id: 'point-1', isActive: true });
    prisma.arrival.findFirst.mockResolvedValueOnce({ id: 'old', pointId: 'point-1', anyCountry: false });
    prisma.arrival.findFirst.mockResolvedValueOnce(null);
    const clientDay = new Date();
    clientDay.setDate(clientDay.getDate() + 1);
    const clientToday = clientDay.toISOString().slice(0, 10);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'new', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: null, waitDays: 2, anyCountry: false, status: 'PLANNED' });

    await service.repeat('user-1', clientToday);

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ plannedDay: new Date(`${clientToday}T00:00:00.000Z`) }) }),
    );
  });

  it('checkIn() без анонса: ON_SITE на календарный день клиента', async () => {
    const prisma = makePrisma();
    const service = new ArrivalsService(prisma);
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', anyCountry: true, homeCityId: 'c1' });
    prisma.point.findFirst.mockResolvedValue({ id: 'point-1', isActive: true });
    const clientDay = new Date();
    clientDay.setDate(clientDay.getDate() - 1);
    const clientToday = clientDay.toISOString().slice(0, 10);
    prisma.__tx.arrival.create.mockResolvedValue({ id: 'a', pointId: 'point-1', plannedAt: new Date(), plannedDay: new Date(), arrivedAt: new Date(), waitDays: 2, anyCountry: true, status: 'ON_SITE' });

    await service.checkIn('user-1', undefined, undefined, clientToday);

    expect(prisma.__tx.arrival.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ plannedDay: new Date(`${clientToday}T00:00:00.000Z`), status: 'ON_SITE' }) }),
    );
  });
});
