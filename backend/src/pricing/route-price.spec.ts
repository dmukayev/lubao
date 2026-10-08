import { bucketForCountry, dedupPoints, pricePerKm, routeStats, tonnageClass } from './route-price';

describe('route-price (047)', () => {
  it('₸/км: цена / км, без расстояния — null', () => {
    expect(pricePerKm(850000, 1230)).toBe(691.06);
    expect(pricePerKm(850000, null)).toBeNull();
    expect(pricePerKm(850000, 0)).toBeNull();
  });

  it('корзина по стране назначения', () => {
    expect(bucketForCountry('KZ')).toBe('KZ');
    expect(bucketForCountry('KG')).toBe('CIS');
    expect(bucketForCountry('RU')).toBe('CIS');
    expect(bucketForCountry('CN')).toBe('CN_FAR');
    expect(bucketForCountry(null)).toBe('CN_FAR');
  });

  it('класс тоннажа 5/10/20', () => {
    expect(tonnageClass(3000)).toBe(5);
    expect(tonnageClass(5000)).toBe(5);
    expect(tonnageClass(8000)).toBe(10);
    expect(tonnageClass(20000)).toBe(20);
    expect(tonnageClass(null)).toBe(20);
  });

  it('медиана и квартили; меньше 5 точек — мало данных', () => {
    expect(routeStats([600, 650, 700, 720, 800])).toEqual({ median: 700, p25: 650, p75: 720, points: 5 });
    expect(routeStats([600, 650, 700, 720])).toBeNull();
    expect(routeStats([1, 2, 3, 4, 5, 6])?.median).toBe(3.5);
  });

  it('дедуп: пара водитель–компания по маршруту — одна точка (последняя)', () => {
    const base = { companyId: 'c1', fromCityId: 'a', toCityId: 'b' };
    const out = dedupPoints([
      { ...base, driverId: 'd1', createdAt: new Date('2030-01-01'), v: 1 },
      { ...base, driverId: 'd1', createdAt: new Date('2030-01-05'), v: 2 },
      { ...base, driverId: 'd2', createdAt: new Date('2030-01-02'), v: 3 },
    ]);
    expect(out.map((p) => p.v).sort()).toEqual([2, 3]);
  });
});
