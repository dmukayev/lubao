import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { SubmitCityDto } from './dto/submit-city.dto';

const MAX_CITY_SUBMISSIONS_PER_DAY = 3;

@Injectable()
export class ReferenceDataService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly appSettings: AppSettingsService,
  ) {}

  /// `requestingUserId` — только если роут вызван с валидным токеном (см.
  /// JwtAuthGuard — `/reference-data` публичный, но optional-auth). Нужен,
  /// чтобы показать автору его собственные PENDING-города (024 п.6).
  async getAll(requestingUserId?: string) {
    const [
      countries,
      regions,
      cities,
      bodyTypes,
      bodySizePresets,
      permits,
      cargoCategories,
      points,
      exchangeRates,
      defaultPointCityId,
      supportWhatsapp,
      supportWechat,
      supportEmail,
    ] = await Promise.all([
      this.prisma.country.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.region.findMany(),
      this.visibleCities(requestingUserId),
      this.prisma.bodyType.findMany({ orderBy: { sortOrder: 'asc' } }),
      // Без фильтра isActive — как bodyTypes: админке нужны и выключенные,
      // клиенты показывают водителю только активные.
      this.prisma.bodySizePreset.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.permit.findMany({ orderBy: { sortOrder: 'asc' } }),
      // 047: категории груза — как bodyTypes, без фильтра (клиенты скрывают выключенные).
      this.prisma.cargoCategory.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.point.findMany({ where: { isActive: true } }),
      this.latestExchangeRates(),
      this.appSettings.get('defaultPointCityId'),
      this.appSettings.get('supportWhatsapp'),
      this.appSettings.get('supportWechat'),
      this.appSettings.get('supportEmail'),
    ]);

    return {
      countries,
      regions,
      cities,
      bodyTypes,
      // Prisma Decimal сериализуется строкой — клиенту нужны числа.
      bodySizePresets: bodySizePresets.map((p) => ({
        ...p,
        innerLengthM: p.innerLengthM != null ? Number(p.innerLengthM) : null,
        innerWidthM: p.innerWidthM != null ? Number(p.innerWidthM) : null,
        innerHeightM: p.innerHeightM != null ? Number(p.innerHeightM) : null,
        volumeM3: p.volumeM3 != null ? Number(p.volumeM3) : null,
      })),
      permits,
      cargoCategories,
      // Decimal сериализуется строкой — клиенту нужны числа (задача 040).
      points: points.map((p) => ({ ...p, lat: p.lat != null ? Number(p.lat) : null, lng: p.lng != null ? Number(p.lng) : null })),
      exchangeRates,
      defaultPointCityId,
      supportWhatsapp,
      supportWechat,
      supportEmail,
    };
  }

  /// Чужой непроверенный/мусорный город не должен сразу светиться всем в
  /// поиске (024 п.6) — только подтверждённые видны всем, PENDING видит
  /// только тот, кто его создал, отклонённые не видит никто.
  private async visibleCities(requestingUserId?: string) {
    const cities = await this.prisma.city.findMany({
      where: {
        OR: [{ cityStatus: 'APPROVED' }, ...(requestingUserId ? [{ cityStatus: 'PENDING' as const, submittedByUserId: requestingUserId }] : [])],
      },
    });
    // Decimal сериализуется строкой — клиенту нужны числа (у городов с
    // координатами «рядом со мной» и ≤200 км, задача 040).
    return cities.map((c) => ({ ...c, lat: c.lat != null ? Number(c.lat) : null, lng: c.lng != null ? Number(c.lng) : null }));
  }

  /// Водитель/логист не нашёл свой город в справочнике — создаём его сразу
  /// (cityStatus=PENDING), чтобы регистрация/заполнение профиля не
  /// прерывались; админ позже подтверждает/объединяет/отклоняет (см. 021).
  /// Лимит 3/сутки на пользователя (024 п.6) — иначе один человек может
  /// завалить очередь модерации.
  async submitCity(userId: string, dto: SubmitCityDto) {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const submittedToday = await this.prisma.city.count({
      where: { submittedByUserId: userId, createdAt: { gte: since } },
    });
    if (submittedToday >= MAX_CITY_SUBMISSIONS_PER_DAY) {
      throw new BadRequestException('Слишком много новых городов за сутки, попробуйте завтра');
    }

    const region = await this.prisma.region.findUnique({ where: { id: dto.regionId } });
    if (!region) throw new NotFoundException('Region not found');

    return this.prisma.city.create({
      data: {
        name: { ru: dto.settlementName },
        countryId: region.countryId,
        regionId: region.id,
        cityStatus: 'PENDING',
        submittedByUserId: userId,
      },
    });
  }

  /// Последний известный курс по каждой валюте (на дату effectiveDate).
  /// Курсы обновляются отдельным фидом/сидом, здесь только чтение.
  private async latestExchangeRates() {
    const rows = await this.prisma.exchangeRate.findMany({ orderBy: { effectiveDate: 'desc' } });
    const latestByCurrency = new Map<string, (typeof rows)[number]>();
    for (const row of rows) {
      if (!latestByCurrency.has(row.currency)) latestByCurrency.set(row.currency, row);
    }
    return Array.from(latestByCurrency.values()).map((r) => ({
      currency: r.currency,
      rateToKzt: Number(r.rateToKzt),
      effectiveDate: r.effectiveDate,
    }));
  }
}
