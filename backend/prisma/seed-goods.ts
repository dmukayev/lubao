import { PrismaClient } from '@prisma/client';
import { readFileSync } from 'fs';
import { join } from 'path';
import { goodsSearchText } from '../src/goods/goods-text';

/// 075: справочники «Что везёте?» из prisma/data (не из сети): коды HS-6,
/// главы → категории, популярные товары. Существующие записи не перезаписываем —
/// их правят в админке; досоздаём недостающие.
export async function seedGoods(prisma: PrismaClient) {
  const dir = join(__dirname, 'data');
  const read = <T>(file: string): T => JSON.parse(readFileSync(join(dir, file), 'utf8')) as T;
  const categories = new Map((await prisma.cargoCategory.findMany({ select: { id: true, code: true } })).map((c) => [c.code, c.id]));
  const bodyTypes = new Map((await prisma.bodyType.findMany({ select: { id: true, code: true } })).map((b) => [b.code, b.id]));

  const hs = read<Array<{ code: string; name: Record<string, string> }>>('hs_codes.json');
  for (let i = 0; i < hs.length; i += 1000) {
    await prisma.hsCode.createMany({
      data: hs.slice(i, i + 1000).map((h) => ({ code: h.code, chapter: h.code.slice(0, 2), heading: h.code.slice(0, 4), name: h.name, searchText: goodsSearchText(h.name) })),
      skipDuplicates: true,
    });
  }

  const chapters = read<Array<{ chapter: string; category: string }>>('hs_chapters.json');
  await prisma.hsChapter.createMany({
    data: chapters.filter((c) => categories.has(c.category)).map((c) => ({ chapter: c.chapter, categoryId: categories.get(c.category)! })),
    skipDuplicates: true,
  });

  type GoodsRow = { slug: string; hsCode: string | null; category: string; bodyType: string | null; isDangerous: boolean; sortOrder: number; name: Record<string, string>; synonyms: Record<string, string[]> };
  const goods = read<GoodsRow[]>('goods.json');
  await prisma.goods.createMany({
    data: goods
      .filter((g) => categories.has(g.category))
      .map((g) => ({
        slug: g.slug,
        name: g.name,
        synonyms: g.synonyms,
        hsCode: g.hsCode,
        categoryId: categories.get(g.category)!,
        suggestedBodyTypeId: g.bodyType ? bodyTypes.get(g.bodyType) ?? null : null,
        isDangerous: g.isDangerous,
        sortOrder: g.sortOrder,
        searchText: goodsSearchText(g.name, g.synonyms),
      })),
    skipDuplicates: true,
  });
  console.log(`seed-goods: ${hs.length} кодов HS, ${chapters.length} глав, ${goods.length} товаров`);
}
