import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AdminGoodsDto, AdminHsChapterDto, AdminHsNameDto } from './admin-goods.dto';
import { goodsSearchText } from './goods-text';

/// 075 п.10–11: справочники «Товары», «Коды HS», «Главы → категории» и
/// «Новые слова» (свои варианты логистов) — каждое изменение в журнал.
@Injectable()
export class AdminGoodsService {
  constructor(private readonly prisma: PrismaService) {}

  private audit(actorUserId: string, action: string, entityType: string, entityId: string, metadata: object) {
    return this.prisma.auditLog.create({ data: { actorUserId, action, entityType, entityId, metadata } });
  }

  async listGoods(q?: string) {
    const query = q?.trim().toLowerCase();
    return this.prisma.goods.findMany({
      where: query ? { OR: [{ searchText: { contains: query } }, { hsCode: { startsWith: query } }, { slug: { contains: query } }] } : {},
      orderBy: [{ sortOrder: 'asc' }, { slug: 'asc' }],
      take: 500,
    });
  }

  async createGoods(actorUserId: string, dto: AdminGoodsDto) {
    if (!dto.slug || !dto.name?.ru || !dto.categoryId) throw new BadRequestException({ code: 'VALIDATION_FAILED', message: ['slug, name.ru and categoryId are required'] });
    await this.assertRefs(dto);
    try {
      const created = await this.prisma.goods.create({
        data: {
          slug: dto.slug,
          name: dto.name,
          synonyms: dto.synonyms ?? {},
          hsCode: dto.hsCode || null,
          categoryId: dto.categoryId,
          suggestedBodyTypeId: dto.suggestedBodyTypeId ?? null,
          isDangerous: dto.isDangerous ?? false,
          sortOrder: dto.sortOrder ?? 10000,
          isActive: dto.isActive ?? true,
          searchText: goodsSearchText(dto.name, dto.synonyms),
        },
      });
      await this.audit(actorUserId, 'GOODS_CREATED', 'Goods', created.id, { slug: created.slug, reason: dto.reason });
      return created;
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') throw new ConflictException({ code: 'CONFLICT', message: 'Slug already exists' });
      throw e;
    }
  }

  async updateGoods(actorUserId: string, id: string, dto: AdminGoodsDto) {
    const goods = await this.prisma.goods.findUnique({ where: { id } });
    if (!goods) throw new NotFoundException('Goods not found');
    await this.assertRefs(dto);
    const name = (dto.name ?? goods.name) as Record<string, unknown>;
    const synonyms = (dto.synonyms ?? goods.synonyms) as Record<string, unknown>;
    const updated = await this.prisma.goods.update({
      where: { id },
      data: {
        name: dto.name,
        synonyms: dto.synonyms,
        hsCode: dto.hsCode === undefined ? undefined : dto.hsCode || null,
        categoryId: dto.categoryId,
        suggestedBodyTypeId: dto.suggestedBodyTypeId === undefined ? undefined : dto.suggestedBodyTypeId,
        isDangerous: dto.isDangerous,
        sortOrder: dto.sortOrder,
        isActive: dto.isActive,
        searchText: goodsSearchText(name, synonyms),
      },
    });
    await this.audit(actorUserId, 'GOODS_UPDATED', 'Goods', id, { reason: dto.reason });
    return updated;
  }

  private async assertRefs(dto: AdminGoodsDto) {
    if (dto.hsCode && !(await this.prisma.hsCode.findUnique({ where: { code: dto.hsCode } }))) throw new BadRequestException({ code: 'HS_CODE_NOT_FOUND', message: 'Unknown HS code' });
    if (dto.categoryId && !(await this.prisma.cargoCategory.findUnique({ where: { id: dto.categoryId } }))) throw new BadRequestException({ code: 'CATEGORY_REQUIRED', message: 'Unknown category' });
    if (dto.suggestedBodyTypeId && !(await this.prisma.bodyType.findUnique({ where: { id: dto.suggestedBodyTypeId } }))) throw new BadRequestException({ code: 'BODY_TYPE_REQUIRED', message: 'Unknown body type' });
  }

  async listHs(q?: string, page = 1) {
    const query = q?.trim().toLowerCase();
    const where: Prisma.HsCodeWhereInput = query ? (/^\d+$/.test(query) ? { code: { startsWith: query } } : { searchText: { contains: query } }) : {};
    const [items, total] = await Promise.all([
      this.prisma.hsCode.findMany({ where, orderBy: { code: 'asc' }, skip: (Math.max(page, 1) - 1) * 50, take: 50 }),
      this.prisma.hsCode.count({ where }),
    ]);
    return { items, total };
  }

  async updateHsName(actorUserId: string, code: string, dto: AdminHsNameDto) {
    const hs = await this.prisma.hsCode.findUnique({ where: { code } });
    if (!hs) throw new NotFoundException('HS code not found');
    const name = { ...(hs.name as Record<string, string>), ...dto.name };
    const updated = await this.prisma.hsCode.update({ where: { code }, data: { name, searchText: goodsSearchText(name) } });
    await this.audit(actorUserId, 'HS_CODE_RENAMED', 'HsCode', code, { reason: dto.reason });
    return updated;
  }

  listChapters() {
    return this.prisma.hsChapter.findMany({ orderBy: { chapter: 'asc' } });
  }

  async updateChapter(actorUserId: string, chapter: string, dto: AdminHsChapterDto) {
    if (!(await this.prisma.cargoCategory.findUnique({ where: { id: dto.categoryId } }))) throw new BadRequestException({ code: 'CATEGORY_REQUIRED', message: 'Unknown category' });
    const updated = await this.prisma.hsChapter.upsert({ where: { chapter }, update: { categoryId: dto.categoryId }, create: { chapter, categoryId: dto.categoryId } });
    await this.audit(actorUserId, 'HS_CHAPTER_CATEGORY', 'HsChapter', chapter, { categoryId: dto.categoryId, reason: dto.reason });
    return updated;
  }

  /// «Новые слова» — свои варианты логистов (без товара), сколько раз встречались.
  async newWords() {
    const rows = await this.prisma.$queryRaw<Array<{ text: string; count: bigint; last: Date }>>`
      SELECT lower(trim("goodsText")) AS text, COUNT(*)::bigint AS count, MAX("createdAt") AS last
      FROM cargos WHERE "goodsText" IS NOT NULL AND "goodsId" IS NULL
      GROUP BY lower(trim("goodsText")) ORDER BY count DESC, last DESC LIMIT 200`;
    return rows.map((r) => ({ text: r.text, count: Number(r.count), last: r.last }));
  }
}
