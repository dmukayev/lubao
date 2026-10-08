import { DistanceService } from './distance.service';
import { PricingService } from './pricing.service';

describe('DistanceService (047 п.2)', () => {
  const cities = [
    { id: 'a', lat: 43.25, lng: 76.92 },
    { id: 'b', lat: 51.16, lng: 71.47 },
  ];
  function setup(cached: unknown = null) {
    const prisma: any = {
      cityDistance: { findUnique: jest.fn().mockResolvedValue(cached), upsert: jest.fn() },
      city: { findMany: jest.fn().mockResolvedValue(cities) },
    };
    const svc = new DistanceService(prisma);
    return { prisma, svc };
  }
  beforeEach(() => (process.env.OSRM_URL = 'http://osrm:5000'));
  afterEach(() => delete process.env.OSRM_URL);

  it('пара из кэша — без OSRM; ключ пары упорядочен', async () => {
    const { prisma, svc } = setup({ km: 1230 });
    svc.fetchFn = jest.fn();
    expect(await svc.roadKm('b', 'a')).toBe(1230);
    expect(prisma.cityDistance.findUnique).toHaveBeenCalledWith({ where: { fromCityId_toCityId: { fromCityId: 'a', toCityId: 'b' } } });
    expect(svc.fetchFn).not.toHaveBeenCalled();
  });

  it('OSRM: метры → км, сохраняет пару', async () => {
    const { prisma, svc } = setup();
    svc.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ code: 'Ok', routes: [{ distance: 1229600 }] }) });
    expect(await svc.roadKm('a', 'b')).toBe(1230);
    expect((svc.fetchFn as jest.Mock).mock.calls[0][0]).toBe('http://osrm:5000/route/v1/driving/76.92,43.25;71.47,51.16?overview=false');
    expect(prisma.cityDistance.upsert).toHaveBeenCalledWith(expect.objectContaining({ create: expect.objectContaining({ km: 1230 }) }));
  });

  it('OSRM недоступен — null («—»), ничего не пишет', async () => {
    const { prisma, svc } = setup();
    svc.fetchFn = jest.fn().mockRejectedValue(new Error('ECONNREFUSED'));
    expect(await svc.roadKm('a', 'b')).toBeNull();
    expect(prisma.cityDistance.upsert).not.toHaveBeenCalled();
  });

  it('нет города назначения — null', async () => {
    expect(await setup().svc.roadKm('a', null)).toBeNull();
  });
});

describe('PricingService (047 п.4)', () => {
  it('точка цены: ₸/км по курсу, корзина и тоннаж', async () => {
    const prisma: any = {
      exchangeRate: { findFirst: jest.fn().mockResolvedValue({ rateToKzt: 480 }) },
      pricePoint: { create: jest.fn() },
    };
    const svc = new PricingService(prisma, {} as any);
    await svc.recordPoint('LISTED', { id: 'c', companyId: 'co', price: 1000, currency: 'USD', weightKg: 8000, destinationCityId: 'b', point: { cityId: 'a' }, destinationCountry: { code: 'KG' }, distanceKm: 800 });
    expect(prisma.pricePoint.create).toHaveBeenCalledWith({ data: expect.objectContaining({ kind: 'LISTED', bucket: 'CIS', tonnageClass: 10, pricePerKmKzt: 600 }) });
  });

  it('пересчёт: ≥5 точек после дедупа — строка, меньше — удаляется', async () => {
    const mk = (i: number, driverId: string, v: number) => ({ fromCityId: 'a', toCityId: 'b', bucket: 'KZ', tonnageClass: 20, driverId, companyId: 'co', kind: 'DEAL', pricePerKmKzt: v, createdAt: new Date(2030, 0, i) });
    const points = [mk(1, 'd1', 600), mk(2, 'd2', 650), mk(3, 'd3', 700), mk(4, 'd4', 720), mk(5, 'd5', 800), mk(6, 'd5', 810)];
    const prisma: any = {
      pricePoint: { findMany: jest.fn().mockResolvedValue(points) },
      routePriceStat: {
        upsert: jest.fn(),
        findMany: jest.fn().mockResolvedValue([{ fromCityId: 'x', toCityId: 'y', bucket: 'KZ', tonnageClass: 5 }]),
        delete: jest.fn(),
      },
    };
    const svc = new PricingService(prisma, {} as any);
    expect(await svc.recomputeStats(new Date(2030, 0, 10))).toEqual({ routes: 1 });
    // d5 — одна точка (последняя, 810).
    expect(prisma.routePriceStat.upsert.mock.calls[0][0].create).toMatchObject({ median: 700, p25: 650, p75: 720, points: 5, dealPoints: 5 });
    expect(prisma.routePriceStat.delete).toHaveBeenCalledWith({ where: { fromCityId_toCityId_bucket_tonnageClass: { fromCityId: 'x', toCityId: 'y', bucket: 'KZ', tonnageClass: 5 } } });
  });
});

describe('PricingService — точка объявления (049 п.11)', () => {
  const cargo = { id: 'c', companyId: 'co', price: 1000, currency: 'KZT', weightKg: 20000, destinationCityId: 'b', point: { cityId: 'a' }, destinationCountry: { code: 'KZ' } };

  it('сменилась цена — существующая LISTED-точка обновляется, новая не создаётся', async () => {
    const prisma: any = { pricePoint: { findFirst: jest.fn().mockResolvedValue({ id: 'p1' }), update: jest.fn(), create: jest.fn() }, exchangeRate: { findFirst: jest.fn() } };
    await new PricingService(prisma, {} as any).upsertListedPoint({ ...cargo, price: 1500, distanceKm: 1 });
    expect(prisma.pricePoint.update).toHaveBeenCalledWith({ where: { id: 'p1' }, data: expect.objectContaining({ pricePerKmKzt: 1500 }) });
    expect(prisma.pricePoint.create).not.toHaveBeenCalled();
  });

  it('OSRM досчитал км — у груза проверенной компании появляется точка', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([{ ...cargo, company: { isVerified: true } }]), update: jest.fn() },
      pricePoint: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn() },
      exchangeRate: { findFirst: jest.fn() },
    };
    const distance: any = { roadKm: jest.fn().mockResolvedValue(500) };
    expect(await new PricingService(prisma, distance).fillMissingDistances()).toEqual({ filled: 1 });
    expect(prisma.pricePoint.create).toHaveBeenCalledWith({ data: expect.objectContaining({ kind: 'LISTED', cargoId: 'c', pricePerKmKzt: 2 }) });
  });
});
