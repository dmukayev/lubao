import { BadRequestException, ConflictException } from '@nestjs/common';
import { ReviewsService } from './reviews.service';

function setup(
  deal: any = { id: 'deal1', status: 'DELIVERED', driverId: 'd1', companyId: 'c1' },
  aggregate = { _sum: { rating: 9 }, _count: { rating: 2 } },
  cancelled: any[] = [],
  weights: string | null = null,
) {
  const tx: any = {
    review: { create: jest.fn().mockResolvedValue({ id: 'rv1', dealId: 'deal1', authorUserId: 'u1', authorRole: 'COMPANY', rating: 5, comment: null, createdAt: new Date() }), aggregate: jest.fn().mockResolvedValue(aggregate) },
    deal: { findMany: jest.fn().mockResolvedValue(cancelled) },
    appSetting: { findUnique: jest.fn().mockResolvedValue(weights == null ? null : { value: weights }) },
    driver: { update: jest.fn() },
    company: { update: jest.fn() },
  };
  const prisma: any = {
    deal: { findUnique: jest.fn().mockResolvedValue(deal) },
    review: { findUnique: jest.fn().mockResolvedValue(null) },
    $transaction: jest.fn(async (cb: any) => cb(tx)),
  };
  return { tx, prisma, service: new ReviewsService(prisma) };
}

describe('ReviewsService.submit — рейтинг (задача 041, п.4)', () => {
  it('отзыв компании пересчитывает ratingAvg/ratingCount ВОДИТЕЛЯ в той же транзакции', async () => {
    const { tx, service } = setup();
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.review.aggregate).toHaveBeenCalledWith(expect.objectContaining({ where: { authorRole: 'COMPANY', deal: { driverId: 'd1' } } }));
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 4.5, ratingCount: 2 } });
    expect(tx.company.update).not.toHaveBeenCalled();
  });

  it('отзыв водителя пересчитывает рейтинг КОМПАНИИ', async () => {
    const { tx, service } = setup();
    await service.submit('deal1', 'u2', 'DRIVER', 4);
    expect(tx.company.update).toHaveBeenCalledWith({ where: { id: 'c1' }, data: { ratingAvg: 4.5, ratingCount: 2 } });
    expect(tx.driver.update).not.toHaveBeenCalled();
  });

  it('отзывов нет → среднее 0, счётчик 0 (клиент рисует «—»)', async () => {
    const { tx, service } = setup(undefined, { _sum: { rating: null as any }, _count: { rating: 0 } });
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 0, ratingCount: 0 } });
  });

  // 046 п.4: отмена по своей вине — «виртуальные» оценки 1★ с весом по этапу.
  const cancel = (cancelStage: string, faultSide: string, cancelledByRole = 'DRIVER', cancelRequestedAt: Date | null = null) => ({ cancelStage, faultSide, cancelledByRole, cancelRequestedAt });

  it('отмена после загрузки по своей вине бьёт сильнее (×3), чем после подтверждения (×1)', async () => {
    const afterLoad = setup(undefined, { _sum: { rating: 10 }, _count: { rating: 2 } }, [cancel('AFTER_LOAD', 'SELF')]);
    await afterLoad.service.submit('deal1', 'u1', 'COMPANY', 5);
    // (10 + 3·1) / (2 + 3) = 2.6
    expect(afterLoad.tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 2.6, ratingCount: 2 } });
    const afterConfirm = setup(undefined, { _sum: { rating: 10 }, _count: { rating: 2 } }, [cancel('AFTER_CONFIRM', 'SELF')]);
    await afterConfirm.service.submit('deal1', 'u1', 'COMPANY', 5);
    // (10 + 1) / 3 = 3.67
    expect(afterConfirm.tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 3.67, ratingCount: 2 } });
  });

  it('отмена из-за другой стороны и нейтральная — рейтинг отменившего не трогают', async () => {
    const { tx, service } = setup(undefined, { _sum: { rating: 10 }, _count: { rating: 2 } }, [cancel('AFTER_LOAD', 'OTHER_PARTY'), cancel('IN_TRANSIT', 'NEUTRAL')]);
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 5, ratingCount: 2 } });
  });

  it('вина второй стороны, установленная запросом (подтвердила/промолчала/админ), бьёт по ней', async () => {
    // Компания отменила «в пути» из-за водителя, сделка прошла через запрос → штраф водителю.
    const { tx, service } = setup(undefined, { _sum: { rating: 10 }, _count: { rating: 2 } }, [cancel('IN_TRANSIT', 'OTHER_PARTY', 'COMPANY', new Date())]);
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 2.6, ratingCount: 2 } });
  });

  it('вес — настройка cancelRatingWeights в app_settings', async () => {
    const { tx, service } = setup(undefined, { _sum: { rating: 10 }, _count: { rating: 2 } }, [cancel('AFTER_LOAD', 'SELF')], JSON.stringify({ AFTER_LOAD: 0 }));
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 5, ratingCount: 2 } });
  });

  it('недоставленная сделка — 400, повторный отзыв — 409', async () => {
    const a = setup({ id: 'deal1', status: 'LOADED', driverId: 'd1', companyId: 'c1' });
    await expect(a.service.submit('deal1', 'u1', 'COMPANY', 5)).rejects.toThrow(BadRequestException);
    const b = setup();
    b.prisma.review.findUnique.mockResolvedValue({ id: 'old' });
    await expect(b.service.submit('deal1', 'u1', 'COMPANY', 5)).rejects.toThrow(ConflictException);
  });
});
