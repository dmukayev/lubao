/// 059: фильтры и сортировка ленты водителя (GET /cargos).
export const FEED_SORTS = ['default', 'price_asc', 'price_desc', 'per_km', 'ready', 'distance_asc', 'distance_desc', 'new'] as const;
export type FeedSort = (typeof FEED_SORTS)[number];
export const FEED_READY = ['any', 'today', '3d', 'week'] as const;
export type FeedReady = (typeof FEED_READY)[number];

export interface FeedQuery {
  limit?: number;
  offset?: number;
  /// Откуда: страна / город погрузки (по умолчанию — из статуса водителя).
  fromCountryId?: string;
  fromCityId?: string;
  /// Куда: страна / город выгрузки; `toHome` — чип «Домой».
  toCountryId?: string;
  toCityId?: string;
  toHome?: boolean;
  /// Кузова (профили 048, несколько); пусто — «моя машина» (отсев как раньше).
  bodyTypeIds?: string[];
  weightMinT?: number;
  weightMaxT?: number;
  /// Цена от–до в [priceCurrency] (пересчёт через ₸ по курсу НБ РК).
  priceMin?: number;
  priceMax?: number;
  priceCurrency?: string;
  /// ₸/км от.
  perKmMin?: number;
  ready?: FeedReady;
  withAdvance?: boolean;
  sort?: FeedSort;
  /// «Грузы из других городов» — по умолчанию свёрнуты.
  showOtherCities?: boolean;
}

const num = (v: unknown): number | undefined => {
  if (v === undefined || v === null || v === '') return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
};
/// 057 п.18: limit/offset — только целые неотрицательные.
const int = (v: unknown): number | undefined => (typeof v === 'string' && /^\d+$/.test(v.trim()) ? Number(v) : typeof v === 'number' && Number.isInteger(v) && v >= 0 ? v : undefined);
const bool = (v: unknown): boolean | undefined => (v === undefined || v === '' ? undefined : v === true || v === 'true' || v === '1');
const str = (v: unknown): string | undefined => (typeof v === 'string' && v.trim() ? v.trim() : undefined);

/// Разбор query-строки (всё необязательно; мусор — игнорируется).
export function parseFeedQuery(q: Record<string, unknown>): FeedQuery {
  const sort = str(q.sort);
  const ready = str(q.ready);
  const bodies = str(q.bodyTypeIds);
  return {
    limit: int(q.limit),
    offset: int(q.offset),
    fromCountryId: str(q.fromCountryId),
    fromCityId: str(q.fromCityId),
    toCountryId: str(q.toCountryId),
    toCityId: str(q.toCityId),
    toHome: bool(q.toHome),
    bodyTypeIds: bodies ? bodies.split(',').map((s) => s.trim()).filter(Boolean) : undefined,
    weightMinT: num(q.weightMinT),
    weightMaxT: num(q.weightMaxT),
    priceMin: num(q.priceMin),
    priceMax: num(q.priceMax),
    priceCurrency: str(q.priceCurrency),
    perKmMin: num(q.perKmMin),
    ready: ready && (FEED_READY as readonly string[]).includes(ready) ? (ready as FeedReady) : undefined,
    withAdvance: bool(q.withAdvance),
    sort: sort && (FEED_SORTS as readonly string[]).includes(sort) ? (sort as FeedSort) : undefined,
    showOtherCities: bool(q.showOtherCities),
  };
}
