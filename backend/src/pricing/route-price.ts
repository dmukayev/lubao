/// Цена за км и статистика цен по маршрутам (047 п.3–4, decisions.md
/// 2026-10-07 «Расстояние и цена за км у груза; статистика цен по маршрутам»).

/// Корзина по стране назначения: внутри РК, СНГ, Китай/дальнее.
export type PriceBucket = 'KZ' | 'CIS' | 'CN_FAR';
const CIS = new Set(['RU', 'KG', 'UZ', 'TJ', 'TM', 'BY', 'AM', 'AZ', 'MD', 'GE']);

export function bucketForCountry(code: string | null | undefined): PriceBucket {
  if (code === 'KZ') return 'KZ';
  if (code && CIS.has(code)) return 'CIS';
  return 'CN_FAR';
}

/// Класс тоннажа: ≤5 т → 5, ≤10 т → 10, больше или неизвестно → 20.
export function tonnageClass(weightKg: number | null | undefined): 5 | 10 | 20 {
  if (weightKg == null || weightKg <= 0) return 20;
  if (weightKg <= 5000) return 5;
  if (weightKg <= 10000) return 10;
  return 20;
}

/// Цена за км в валюте груза (2 знака). Нет расстояния — `null` («—»).
export function pricePerKm(price: number, km: number | null | undefined): number | null {
  if (km == null || km <= 0 || !Number.isFinite(price)) return null;
  return Math.round((price / km) * 100) / 100;
}

/// Квантиль по отсортированному массиву (линейная интерполяция, как в Excel/numpy).
function quantile(sorted: number[], q: number): number {
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

export const MIN_POINTS_FOR_STATS = 5;

export type RouteStats = { median: number; p25: number; p75: number; points: number };

/// Медиана и P25–P75; меньше 5 точек — «мало данных» (`null`).
export function routeStats(values: number[]): RouteStats | null {
  const clean = values.filter((v) => Number.isFinite(v) && v > 0).sort((a, b) => a - b);
  if (clean.length < MIN_POINTS_FOR_STATS) return null;
  const r = (v: number) => Math.round(v * 100) / 100;
  return { median: r(quantile(clean, 0.5)), p25: r(quantile(clean, 0.25)), p75: r(quantile(clean, 0.75)), points: clean.length };
}

export const PRICE_POINT_DEDUP_DAYS = 30;

/// Дедуп точек: одна пара водитель–компания по маршруту за 30 дней = одна
/// точка (последняя). Объявления без водителя (LISTED) — по компании.
export type PricePointLike = { driverId: string | null; companyId: string; fromCityId: string; toCityId: string; createdAt: Date };
export function dedupKey(p: Pick<PricePointLike, 'driverId' | 'companyId' | 'fromCityId' | 'toCityId'>): string {
  return [p.driverId ?? '-', p.companyId, p.fromCityId, p.toCityId].join('|');
}
export function dedupPoints<T extends PricePointLike>(points: T[]): T[] {
  const latest = new Map<string, T>();
  for (const p of points) {
    const key = dedupKey(p);
    const prev = latest.get(key);
    if (!prev || prev.createdAt < p.createdAt) latest.set(key, p);
  }
  return [...latest.values()];
}
