import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { SubmitCityDto } from './dto/submit-city.dto';

@Injectable()
export class ReferenceDataService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly appSettings: AppSettingsService,
  ) {}

  async getAll() {
    const [
      countries,
      regions,
      cities,
      bodyTypes,
      permits,
      points,
      exchangeRates,
      defaultPointCityId,
      supportWhatsapp,
      supportWechat,
      supportEmail,
    ] = await Promise.all([
      this.prisma.country.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.region.findMany(),
      this.prisma.city.findMany(),
      this.prisma.bodyType.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.permit.findMany({ orderBy: { sortOrder: 'asc' } }),
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
      permits,
      points,
      exchangeRates,
      defaultPointCityId,
      supportWhatsapp,
      supportWechat,
      supportEmail,
    };
  }

  /// Водитель/логист не нашёл свой город в справочнике — создаём его сразу
  /// (cityStatus=PENDING), чтобы регистрация/заполнение профиля не
  /// прерывались; админ позже подтверждает/объединяет/отклоняет (см. 021).
  async submitCity(userId: string, dto: SubmitCityDto) {
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
