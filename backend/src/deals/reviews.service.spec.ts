import { BadRequestException, ConflictException } from '@nestjs/common';
import { ReviewsService } from './reviews.service';

function setup(deal: any = { id: 'deal1', status: 'DELIVERED', driverId: 'd1', companyId: 'c1' }, aggregate = { _avg: { rating: 4.5 }, _count: { rating: 2 } }) {
  const tx: any = {
    review: { create: jest.fn().mockResolvedValue({ id: 'rv1', dealId: 'deal1', authorUserId: 'u1', authorRole: 'COMPANY', rating: 5, comment: null, createdAt: new Date() }), aggregate: jest.fn().mockResolvedValue(aggregate) },
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
    const { tx, service } = setup(undefined, { _avg: { rating: null as any }, _count: { rating: 0 } });
    await service.submit('deal1', 'u1', 'COMPANY', 5);
    expect(tx.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { ratingAvg: 0, ratingCount: 0 } });
  });

  it('недоставленная сделка — 400, повторный отзыв — 409', async () => {
    const a = setup({ id: 'deal1', status: 'LOADED', driverId: 'd1', companyId: 'c1' });
    await expect(a.service.submit('deal1', 'u1', 'COMPANY', 5)).rejects.toThrow(BadRequestException);
    const b = setup();
    b.prisma.review.findUnique.mockResolvedValue({ id: 'old' });
    await expect(b.service.submit('deal1', 'u1', 'COMPANY', 5)).rejects.toThrow(ConflictException);
  });
});
