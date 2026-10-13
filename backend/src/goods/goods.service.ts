import { BadRequestException, Injectable, Logger, Optional } from '@nestjs/common';
import { Locale, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { TranslationService } from '../translation/translation.service';

export type GoodsHit = {
  type: 'goods' | 'hs';
  goodsId: string | null;
  hsCode: string | null;
  name: Prisma.JsonValue;
  categoryId: string | null;
  suggestedBodyTypeId: string | null;
  isDangerous: boolean;
};

const MAX_HITS = 20;

/// 077: код товара — субпозиция (6 знаков) или позиция (4): есть ли он в HS.
export async function hsCodeExists(prisma: PrismaService, code: string): Promise<boolean> {
  if (/^\d{6}$/.test(code)) return !!(await prisma.hsCode.findUnique({ where: { code }, select: { code: true } }));
  if (/^\d{4}$/.test(code)) return !!(await prisma.hsCode.findFirst({ where: { heading: code }, select: { code: true } }));
  return false;
}
const LOCALES: Locale[] = ['ru', 'kk', 'zh', 'en'];

/// 075 (decisions.md «„Что везёте?“ — поиск по названию и коду ТН ВЭД»):
/// популярные товары и официальные коды HS-6; категория выводится из главы.
@Injectable()
export class GoodsService {
  private readonly logger = new Logger(GoodsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly translation?: TranslationService,
  ) {}

  /// Цифры (2–6) — по началу кода (товары, затем коды HS); иначе — только
  /// товары по названиям и синонимам на всех языках (077). Сначала популярные.
  async search(q: string): Promise<GoodsHit[]> {
    const query = q.trim().toLowerCase();
    if (!query) return [];
    const chapters = await this.chapterCategories();
    const hsHit = (h: { code: string; name: Prisma.JsonValue }): GoodsHit => ({
      type: 'hs', goodsId: null, hsCode: h.code, name: h.name, categoryId: chapters.get(h.code.slice(0, 2)) ?? null, suggestedBodyTypeId: null, isDangerous: false,
    });
    if (/^\d{2,6}$/.test(query)) {
      const goods = await this.prisma.goods.findMany({ where: { isActive: true, hsCode: { startsWith: query } }, orderBy: { sortOrder: 'asc' }, take: MAX_HITS });
      const hs = await this.prisma.hsCode.findMany({ where: { code: { startsWith: query } }, orderBy: { code: 'asc' }, take: MAX_HITS - goods.length });
      return [...goods.map((g) => this.goodsHit(g)), ...hs.map(hsHit)];
    }
    const like = `%${query.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
    const prefix = query.replace(/[\\%_]/g, (c) => `\\${c}`);
    // Начало слова или фразы — выше; затем порядок справочника.
    const goodsIds = await this.prisma.$queryRaw<Array<{ id: string }>>`
      SELECT id FROM goods
      WHERE "isActive" AND "searchText" ILIKE ${like}
      ORDER BY (CASE WHEN "searchText" ILIKE ${prefix + '%'} OR "searchText" ILIKE ${'% ' + prefix + '%'} OR "searchText" ILIKE ${'%|' + prefix + '%'} THEN 0 ELSE 1 END), "sortOrder"
      LIMIT ${MAX_HITS}`;
    const goods = goodsIds.length ? await this.prisma.goods.findMany({ where: { id: { in: goodsIds.map((g) => g.id) } } }) : [];
    const byId = new Map(goods.map((g) => [g.id, g]));
    const ordered = goodsIds.map((g) => byId.get(g.id)).filter((g): g is NonNullable<typeof g> => !!g);
    // 077: по буквам — только товары простыми словами; официальные названия
    // ТН ВЭД длинные и путают (коды ищутся только цифрами).
    return ordered.map((g) => this.goodsHit(g));
  }

  /// Последние 10 разных товаров компании — до ввода.
  async recent(companyId: string): Promise<GoodsHit[]> {
    const rows = await this.prisma.cargo.findMany({
      where: { companyId, goodsId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { goodsId: true },
      take: 100,
    });
    const ids = [...new Set(rows.map((r) => r.goodsId!))].slice(0, 10);
    if (!ids.length) return [];
    const goods = await this.prisma.goods.findMany({ where: { id: { in: ids }, isActive: true } });
    const byId = new Map(goods.map((g) => [g.id, g]));
    return ids.map((id) => byId.get(id)).filter((g): g is NonNullable<typeof g> => !!g).map((g) => this.goodsHit(g));
  }

  /// Груз: товар из справочника и/или код HS — проверить; код товара по умолчанию.
  async resolveForCargo(input: { goodsId?: string | null; hsCode?: string | null }): Promise<{ goodsId: string | null; hsCode: string | null }> {
    let hsCode = input.hsCode ?? null;
    let goodsId: string | null = null;
    if (input.goodsId) {
      const goods = await this.prisma.goods.findUnique({ where: { id: input.goodsId }, select: { id: true, hsCode: true } });
      if (!goods) throw new BadRequestException({ code: 'GOODS_NOT_FOUND', message: 'Goods not found' });
      goodsId = goods.id;
      hsCode = hsCode ?? goods.hsCode;
    }
    if (hsCode && !(await hsCodeExists(this.prisma, hsCode))) {
      throw new BadRequestException({ code: 'HS_CODE_NOT_FOUND', message: 'Unknown HS code' });
    }
    return { goodsId, hsCode };
  }

  /// Свой текст логиста переводится на остальные языки — как сообщения чата
  /// (провайдер не настроен — без перевода, показывается оригинал).
  async translateGoodsText(cargoId: string, text: string, from: Locale, userId: string): Promise<void> {
    if (!this.translation) return;
    const translations: Record<string, string> = {};
    for (const to of LOCALES) {
      if (to === from) continue;
      try {
        const res = await this.translation.translateMessage(userId, text, from, to);
        Object.assign(translations, res.translations);
      } catch (e) {
        this.logger.warn(`Перевод товара груза ${cargoId}: ${(e as Error).message}`);
      }
    }
    if (Object.keys(translations).length) {
      await this.prisma.cargo.update({ where: { id: cargoId }, data: { goodsTextTranslations: translations } });
    }
  }

  async chapterCategories(): Promise<Map<string, string>> {
    const rows = await this.prisma.hsChapter.findMany();
    return new Map(rows.map((r) => [r.chapter, r.categoryId]));
  }

  private goodsHit(g: { id: string; hsCode: string | null; name: Prisma.JsonValue; categoryId: string; suggestedBodyTypeId: string | null; isDangerous: boolean }): GoodsHit {
    return { type: 'goods', goodsId: g.id, hsCode: g.hsCode, name: g.name, categoryId: g.categoryId, suggestedBodyTypeId: g.suggestedBodyTypeId, isDangerous: g.isDangerous };
  }
}
