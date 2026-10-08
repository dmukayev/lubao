import { cancelStatsFor, faultFor, parseCancelRatingWeights, penalizedRating, pendingPenaltyFor, stageForStatus } from './cancel-policy';

describe('cancel-policy (046)', () => {
  it('этап по статусу в момент отмены', () => {
    expect(stageForStatus('SELECTED')).toBe('BEFORE_CONFIRM');
    expect(stageForStatus('CONFIRMED_BY_DRIVER')).toBe('AFTER_CONFIRM');
    expect(stageForStatus('LOADED')).toBe('AFTER_LOAD');
    expect(stageForStatus('IN_TRANSIT')).toBe('IN_TRANSIT');
    expect(stageForStatus('DISPUTED')).toBe('IN_TRANSIT');
  });

  it('вина — относительно отменившего; админ — нейтрально', () => {
    expect(faultFor('VEHICLE_BREAKDOWN', 'DRIVER')).toBe('SELF');
    expect(faultFor('VEHICLE_BREAKDOWN', 'COMPANY')).toBe('OTHER_PARTY');
    expect(faultFor('CARGO_NOT_READY', 'COMPANY')).toBe('SELF');
    expect(faultFor('UNKNOWN', 'DRIVER')).toBe('NEUTRAL');
    expect(faultFor('TOOK_OTHER_CARGO', 'ADMIN')).toBe('NEUTRAL');
  });

  it('вес из настройки: битый JSON и выход за рамки — по умолчанию', () => {
    expect(parseCancelRatingWeights('{"AFTER_LOAD":5,"AFTER_CONFIRM":-1}')).toEqual({ BEFORE_CONFIRM: 0, AFTER_CONFIRM: 1, AFTER_LOAD: 5, IN_TRANSIT: 3 });
    expect(parseCancelRatingWeights('nope').AFTER_LOAD).toBe(3);
  });

  it('049 п.9: без отзывов среднее 0 — штраф не показывается как «1.0», копится отдельно', () => {
    expect(penalizedRating(0, 0, 3)).toBe(0);
    expect(pendingPenaltyFor(0, 3)).toBe(3);
    expect(penalizedRating(5, 1, 3)).toBe(2);
    expect(pendingPenaltyFor(1, 3)).toBe(0);
  });

  it('«отменил 1 из 3 · после загрузки 1 · по своей вине 1»', async () => {
    const deals = [
      { driverId: 'd1', companyId: 'c1', status: 'DELIVERED', cancelledByRole: null, cancelStage: null, faultSide: null, cancelRequestedAt: null },
      { driverId: 'd1', companyId: 'c1', status: 'CANCELLED', cancelledByRole: 'DRIVER', cancelStage: 'AFTER_LOAD', faultSide: 'SELF', cancelRequestedAt: null },
      // Отменила компания из-за груза — водителю не в счёт.
      { driverId: 'd1', companyId: 'c2', status: 'CANCELLED', cancelledByRole: 'COMPANY', cancelStage: 'AFTER_CONFIRM', faultSide: 'SELF', cancelRequestedAt: null },
    ];
    const prisma: any = { deal: { findMany: jest.fn().mockResolvedValue(deals) } };
    const stats = await cancelStatsFor(prisma, 'DRIVER', ['d1', 'd2']);
    expect(stats.get('d1')).toEqual({ total: 3, cancelled: 1, afterLoad: 1, selfFault: 1 });
    expect(stats.get('d2')).toEqual({ total: 0, cancelled: 0, afterLoad: 0, selfFault: 0 });
  });
});
