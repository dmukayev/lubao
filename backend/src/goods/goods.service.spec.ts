import { GoodsService } from './goods.service';
import { goodsSearchText } from './goods-text';

/// 075: поиск товара по коду и названию, категория из главы, свой вариант.
describe('GoodsService', () => {
  const tile = { id: 'g1', slug: 'ceramic_tile', hsCode: '690721', name: { ru: 'Плитка керамическая', zh: '瓷砖' }, categoryId: 'cat-constr', suggestedBodyTypeId: 'bt-tent', isDangerous: false };
  const setup = (over: Record<string, any> = {}) => {
    const prisma: any = {
      hsChapter: { findMany: jest.fn().mockResolvedValue([{ chapter: '69', categoryId: 'cat-constr' }, { chapter: '84', categoryId: 'cat-equip' }]) },
      goods: { findMany: jest.fn().mockResolvedValue([tile]), findUnique: jest.fn().mockResolvedValue(tile) },
      hsCode: { findMany: jest.fn().mockResolvedValue([{ code: '690722', name: { ru: 'Плитки…' } }]), findUnique: jest.fn().mockResolvedValue({ code: '690721' }), findFirst: jest.fn().mockResolvedValue({ code: '690721' }) },
      $queryRaw: jest.fn().mockResolvedValue([]),
      ...over,
    };
    return { prisma, service: new GoodsService(prisma) };
  };

  it('цифры — по началу кода: сначала популярные, потом официальные; категория — из главы', async () => {
    const { prisma, service } = setup();
    const hits = await service.search('6907');
    expect(prisma.goods.findMany.mock.calls[0][0].where).toEqual({ isActive: true, hsCode: { startsWith: '6907' } });
    expect(prisma.hsCode.findMany.mock.calls[0][0].where).toEqual({ code: { startsWith: '6907' } });
    expect(hits.map((h) => [h.type, h.hsCode, h.categoryId])).toEqual([
      ['goods', '690721', 'cat-constr'],
      ['hs', '690722', 'cat-constr'],
    ]);
  });

  it('название на любом языке — только товары по названиям и синонимам, без официальных названий HS (077)', async () => {
    const { prisma, service } = setup();
    prisma.$queryRaw.mockResolvedValueOnce([{ id: 'g1' }]);
    const hits = await service.search('瓷砖');
    expect(hits).toHaveLength(1);
    expect(hits[0]).toMatchObject({ type: 'goods', goodsId: 'g1', suggestedBodyTypeId: 'bt-tent' });
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
    // Поиск без учёта регистра — строка запроса в нижнем регистре.
    await service.search('ПЛИТКА');
    expect(prisma.$queryRaw.mock.calls[1].slice(1)).toContain('%плитка%');
  });

  it('по буквам ничего среди товаров — пусто (в приложении остаётся «Добавить»)', async () => {
    const { prisma, service } = setup();
    prisma.$queryRaw.mockResolvedValueOnce([]);
    expect(await service.search('несуществующее')).toEqual([]);
    expect(prisma.hsCode.findMany).not.toHaveBeenCalled();
  });

  it('код товара — 4 знака (позиция) принимается, если позиция есть в HS; иначе ошибка', async () => {
    const { prisma, service } = setup();
    expect(await service.resolveForCargo({ hsCode: '6907' })).toEqual({ goodsId: null, hsCode: '6907' });
    expect(prisma.hsCode.findFirst).toHaveBeenCalledWith({ where: { heading: '6907' }, select: { code: true } });
    prisma.hsCode.findFirst.mockResolvedValueOnce(null);
    await expect(service.resolveForCargo({ hsCode: '0000' })).rejects.toMatchObject({ response: { code: 'HS_CODE_NOT_FOUND' } });
  });

  it('строка поиска собирает названия и синонимы всех языков', () => {
    expect(goodsSearchText({ ru: 'Плитка', zh: '瓷砖', en: 'Tiles' }, { ru: ['Кафель'], kk: [] })).toBe('плитка | 瓷砖 | tiles | кафель');
  });

  it('груз: товар — его код по умолчанию; свой вариант — без товара и кода; неизвестный код — ошибка', async () => {
    const { prisma, service } = setup();
    expect(await service.resolveForCargo({ goodsId: 'g1' })).toEqual({ goodsId: 'g1', hsCode: '690721' });
    expect(await service.resolveForCargo({})).toEqual({ goodsId: null, hsCode: null });
    prisma.hsCode.findUnique.mockResolvedValueOnce(null);
    await expect(service.resolveForCargo({ hsCode: '000000' })).rejects.toMatchObject({ response: { code: 'HS_CODE_NOT_FOUND' } });
    prisma.goods.findUnique.mockResolvedValueOnce(null);
    await expect(service.resolveForCargo({ goodsId: 'nope' })).rejects.toMatchObject({ response: { code: 'GOODS_NOT_FOUND' } });
  });
});
