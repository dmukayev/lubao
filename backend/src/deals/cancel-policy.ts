import { CancelStage, DealStatus, FaultSide, Prisma, ReviewAuthorRole } from '@prisma/client';

/// Отмена сделки (046, decisions.md 2026-10-08 «Отмена сделки после загрузки —
/// не запрет, а цена»): причина — из списка, этап — по статусу в момент
/// отмены, сторона вины — по таблице ниже (правится здесь, без миграции).

export const CANCEL_REASON_CODES = [
  'VEHICLE_BREAKDOWN',
  'CARGO_NOT_READY',
  'OTHER_PARTY_UNRESPONSIVE',
  'TERMS_CHANGED',
  'TOOK_OTHER_CARGO',
  'OTHER',
] as const;
export type CancelReasonCode = (typeof CANCEL_REASON_CODES)[number];

/// Причины, доступные только одной роли: «взял другой груз» — признак водителя.
export const DRIVER_ONLY_REASONS: ReadonlySet<CancelReasonCode> = new Set(['TOOK_OTHER_CARGO']);

export type CancelSide = Exclude<ReviewAuthorRole, 'ADMIN'>;

/// Чья вина — относительно того, кто отменяет.
const FAULT: Record<CancelReasonCode, Record<CancelSide, FaultSide>> = {
  VEHICLE_BREAKDOWN: { DRIVER: 'SELF', COMPANY: 'OTHER_PARTY' },
  CARGO_NOT_READY: { DRIVER: 'OTHER_PARTY', COMPANY: 'SELF' },
  OTHER_PARTY_UNRESPONSIVE: { DRIVER: 'OTHER_PARTY', COMPANY: 'OTHER_PARTY' },
  TERMS_CHANGED: { DRIVER: 'NEUTRAL', COMPANY: 'NEUTRAL' },
  TOOK_OTHER_CARGO: { DRIVER: 'SELF', COMPANY: 'SELF' },
  OTHER: { DRIVER: 'NEUTRAL', COMPANY: 'NEUTRAL' },
};

export function faultFor(code: string | null | undefined, by: ReviewAuthorRole): FaultSide {
  if (by === 'ADMIN') return 'NEUTRAL';
  const row = FAULT[(code ?? 'OTHER') as CancelReasonCode] ?? FAULT.OTHER;
  return row[by];
}

/// Этап отмены по статусу сделки в момент отмены. Запрос/спор — это уже «в пути».
export function stageForStatus(status: DealStatus): CancelStage {
  switch (status) {
    case 'SELECTED':
      return 'BEFORE_CONFIRM';
    case 'CONFIRMED_BY_DRIVER':
      return 'AFTER_CONFIRM';
    case 'LOADED':
      return 'AFTER_LOAD';
    default:
      return 'IN_TRANSIT';
  }
}

/// После «В пути» одна сторона не закрывает сделку сама — только запросом.
export function needsCounterpartyConsent(status: DealStatus): boolean {
  return status === 'IN_TRANSIT';
}

export const CANCEL_REQUEST_TIMEOUT_HOURS = 24;

/// Вес отмены по своей вине в рейтинге — «виртуальные» оценки 1★ (046 п.4).
/// Настройка `cancelRatingWeights` в app_settings (JSON), по умолчанию — ниже.
export type CancelRatingWeights = Record<CancelStage, number>;
export const DEFAULT_CANCEL_RATING_WEIGHTS: CancelRatingWeights = {
  BEFORE_CONFIRM: 0,
  AFTER_CONFIRM: 1,
  AFTER_LOAD: 3,
  IN_TRANSIT: 3,
};
export const CANCEL_RATING_WEIGHTS_KEY = 'cancelRatingWeights';

export function parseCancelRatingWeights(raw: string | null | undefined): CancelRatingWeights {
  if (!raw) return DEFAULT_CANCEL_RATING_WEIGHTS;
  try {
    const parsed = JSON.parse(raw) as Partial<Record<CancelStage, unknown>>;
    const out = { ...DEFAULT_CANCEL_RATING_WEIGHTS };
    for (const stage of Object.keys(out) as CancelStage[]) {
      const v = parsed[stage];
      if (typeof v === 'number' && Number.isFinite(v) && v >= 0 && v <= 20) out[stage] = v;
    }
    return out;
  } catch {
    return DEFAULT_CANCEL_RATING_WEIGHTS;
  }
}

/// Средняя оценка с учётом штрафа: каждая единица веса — оценка 1★.
export function penalizedRating(sumStars: number, count: number, penalty: number): number {
  const n = count + penalty;
  if (n <= 0) return 0;
  return Number(((sumStars + penalty) / n).toFixed(2));
}

type CancelledDeal = {
  cancelledByRole: ReviewAuthorRole | null;
  cancelStage: CancelStage | null;
  faultSide: FaultSide | null;
  cancelRequestedAt: Date | null;
};

/// Виновата ли сторона `side` в этой отмене. Своя вина — всегда против
/// отменившего. «Из-за другой стороны» бьёт по второй стороне, только если
/// это установлено не со слов отменившего: она подтвердила запрос, промолчала
/// 24 ч или так решил админ (сделка прошла через запрос отмены).
export function isAtFault(deal: CancelledDeal, side: ReviewAuthorRole): boolean {
  if (!deal.cancelledByRole || !deal.faultSide) return false;
  if (deal.faultSide === 'SELF') return deal.cancelledByRole === side;
  if (deal.faultSide === 'OTHER_PARTY') return deal.cancelledByRole !== side && deal.cancelRequestedAt != null;
  return false;
}

export function cancelPenalty(deals: CancelledDeal[], side: ReviewAuthorRole, weights: CancelRatingWeights): number {
  let w = 0;
  for (const d of deals) {
    if (d.cancelStage && isAtFault(d, side)) w += weights[d.cancelStage];
  }
  return w;
}

type Tx = Prisma.TransactionClient;

async function weights(tx: Tx): Promise<CancelRatingWeights> {
  const row = await tx.appSetting.findUnique({ where: { key: CANCEL_RATING_WEIGHTS_KEY } });
  return parseCancelRatingWeights(row?.value);
}

const cancelledSelect = { cancelledByRole: true, cancelStage: true, faultSide: true, cancelRequestedAt: true } as const;

/// Пересчёт рейтинга водителя: отзывы компаний + штраф за отмены по его вине.
export async function recomputeDriverRating(tx: Tx, driverId: string): Promise<void> {
  const [agg, cancelled, w] = await Promise.all([
    tx.review.aggregate({ where: { authorRole: 'COMPANY', deal: { driverId } }, _sum: { rating: true }, _count: { rating: true } }),
    tx.deal.findMany({ where: { driverId, status: 'CANCELLED' }, select: cancelledSelect }),
    weights(tx),
  ]);
  const count = agg._count.rating;
  const ratingAvg = penalizedRating(agg._sum.rating ?? 0, count, cancelPenalty(cancelled, 'DRIVER', w));
  await tx.driver.update({ where: { id: driverId }, data: { ratingAvg, ratingCount: count } });
}

/// То же для компании: отзывы водителей + штраф за отмены по её вине.
export async function recomputeCompanyRating(tx: Tx, companyId: string): Promise<void> {
  const [agg, cancelled, w] = await Promise.all([
    tx.review.aggregate({ where: { authorRole: 'DRIVER', deal: { companyId } }, _sum: { rating: true }, _count: { rating: true } }),
    tx.deal.findMany({ where: { companyId, status: 'CANCELLED' }, select: cancelledSelect }),
    weights(tx),
  ]);
  const count = agg._count.rating;
  const ratingAvg = penalizedRating(agg._sum.rating ?? 0, count, cancelPenalty(cancelled, 'COMPANY', w));
  await tx.company.update({ where: { id: companyId }, data: { ratingAvg, ratingCount: count } });
}

export type CancelStats = { total: number; cancelled: number; afterLoad: number; selfFault: number };
const EMPTY_STATS: CancelStats = { total: 0, cancelled: 0, afterLoad: 0, selfFault: 0 };

/// «Отменил 1 из 15 · после загрузки 1» (046 п.3) — по списку сторон одним запросом.
export async function cancelStatsFor(
  prisma: Pick<Tx, 'deal'>,
  side: ReviewAuthorRole,
  ids: string[],
): Promise<Map<string, CancelStats>> {
  const out = new Map<string, CancelStats>();
  if (ids.length === 0) return out;
  const key = side === 'DRIVER' ? 'driverId' : 'companyId';
  const deals = await prisma.deal.findMany({
    where: { [key]: { in: ids } },
    select: { driverId: true, companyId: true, status: true, ...cancelledSelect },
  });
  for (const id of ids) out.set(id, { ...EMPTY_STATS });
  for (const d of deals) {
    const s = out.get(side === 'DRIVER' ? d.driverId : d.companyId);
    if (!s) continue;
    s.total += 1;
    if (d.status !== 'CANCELLED' || d.cancelledByRole !== side) {
      if (d.status === 'CANCELLED' && isAtFault(d, side)) s.selfFault += 1;
      continue;
    }
    s.cancelled += 1;
    if (d.cancelStage === 'AFTER_LOAD' || d.cancelStage === 'IN_TRANSIT') s.afterLoad += 1;
    if (isAtFault(d, side)) s.selfFault += 1;
  }
  return out;
}
