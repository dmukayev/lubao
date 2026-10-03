import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReferenceDataService {
  constructor(private readonly prisma: PrismaService) {}

  async getAll() {
    const [countries, cities, bodyTypes, permits, points, exchangeRates] = await Promise.all([
      this.prisma.country.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.city.findMany(),
      this.prisma.bodyType.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.permit.findMany({ orderBy: { sortOrder: 'asc' } }),
      this.prisma.point.findMany({ where: { isActive: true } }),
      this.latestExchangeRates(),
    ]);

    return { countries, cities, bodyTypes, permits, points, exchangeRates };
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
