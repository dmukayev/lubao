import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DistanceService } from './distance.service';
import { bucketForCountry, dedupPoints, pricePerKm, PRICE_POINT_DEDUP_DAYS, routeStats, tonnageClass } from './route-price';

const DAY_MS = 24 * 60 * 60 * 1000;

type CargoForPricing = {
  id: string;
  companyId: string;
  price: Prisma.Decimal | number;
  currency: string;
  weightKg: Prisma.Decimal | number | null;
  destinationCityId: string | null;
  point: { cityId: string };
  destinationCountry: { code: string };
};

/// Расстояние, ₸/км и статистика цен по маршрутам (047 п.2–4, 6–8).
@Injectable()
export class PricingService {
  private readonly logger = new Logger(PricingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly distance: DistanceService,
  ) {}

  private async kztRate(currency: string): Promise<number | null> {
    if (currency === 'KZT') return 1;
    const rate = await this.prisma.exchangeRate.findFirst({ where: { currency: currency as never }, orderBy: { effectiveDate: 'desc' } });
    return rate ? Number(rate.rateToKzt) : null;
  }

  /// Расстояние и цена за км груза (в валюте груза). OSRM недоступен —
  /// оба `null`, досчитает `fillMissingDistances`.
  async distanceFor(cargo: Pick<CargoForPricing, 'price' | 'destinationCityId' | 'point'>): Promise<{ distanceKm: number | null; pricePerKm: number | null }> {
    const km = await this.distance.roadKm(cargo.point.cityId, cargo.destinationCityId);
    return { distanceKm: km, pricePerKm: pricePerKm(Number(cargo.price), km) };
  }

  /// 049 п.11: точка объявления (LISTED) — одна на груз: появились км (OSRM
  /// досчитал) — создать, сменилась цена или маршрут — обновить. Только для
  /// проверенной компании (так и публикуются грузы).
  async upsertListedPoint(cargo: CargoForPricing & { distanceKm: number | null }) {
    const existing = await this.prisma.pricePoint.findFirst({ where: { cargoId: cargo.id, kind: 'LISTED' }, select: { id: true } });
    if (!existing) return this.recordPoint('LISTED', cargo);
    const rate = await this.kztRate(cargo.currency);
    const perKm = cargo.destinationCityId && cargo.distanceKm ? pricePerKm(Number(cargo.price) * (rate ?? NaN), cargo.distanceKm) : null;
    if (perKm == null || !Number.isFinite(perKm)) {
      await this.prisma.pricePoint.delete({ where: { id: existing.id } });
      return;
    }
    await this.prisma.pricePoint.update({
      where: { id: existing.id },
      data: {
        fromCityId: cargo.point.cityId,
        toCityId: cargo.destinationCityId!,
        bucket: bucketForCountry(cargo.destinationCountry.code),
        tonnageClass: tonnageClass(cargo.weightKg == null ? null : Number(cargo.weightKg)),
        pricePerKmKzt: perKm,
      },
    });
  }

  /// Точка статистики: объявление проверенной компании (LISTED) или сделка (DEAL).
  async recordPoint(kind: 'LISTED' | 'DEAL', cargo: CargoForPricing & { distanceKm: number | null }, extra: { driverId?: string; dealId?: string } = {}) {
    try {
      if (!cargo.destinationCityId || !cargo.distanceKm) return;
      const rate = await this.kztRate(cargo.currency);
      const perKm = pricePerKm(Number(cargo.price) * (rate ?? NaN), cargo.distanceKm);
      if (perKm == null || !Number.isFinite(perKm)) return;
      await this.prisma.pricePoint.create({
        data: {
          kind,
          cargoId: cargo.id,
          dealId: extra.dealId ?? null,
          driverId: extra.driverId ?? null,
          companyId: cargo.companyId,
          fromCityId: cargo.point.cityId,
          toCityId: cargo.destinationCityId,
          bucket: bucketForCountry(cargo.destinationCountry.code),
          tonnageClass: tonnageClass(cargo.weightKg == null ? null : Number(cargo.weightKg)),
          pricePerKmKzt: perKm,
        },
      });
    } catch (e) {
      // Статистика — по возможности: сбой не ломает публикацию/доставку.
      this.logger.warn(`точка цены для груза ${cargo.id} не записана: ${(e as Error).message}`);
    }
  }

  /// Раз в сутки: медиана и P25–P75 за 30 дней по (откуда, куда, корзина,
  /// тоннаж) при ≥ 5 точках после дедупа; меньше — строка удаляется («мало данных»).
  async recomputeStats(now = new Date()): Promise<{ routes: number }> {
    const since = new Date(now.getTime() - PRICE_POINT_DEDUP_DAYS * DAY_MS);
    const points = await this.prisma.pricePoint.findMany({ where: { createdAt: { gte: since } } });
    const groups = new Map<string, typeof points>();
    for (const p of points) {
      const key = [p.fromCityId, p.toCityId, p.bucket, p.tonnageClass].join('|');
      groups.set(key, [...(groups.get(key) ?? []), p]);
    }
    const keep: Array<{ fromCityId: string; toCityId: string; bucket: string; tonnageClass: number }> = [];
    for (const group of groups.values()) {
      const unique = dedupPoints(group);
      const stats = routeStats(unique.map((p) => Number(p.pricePerKmKzt)));
      if (!stats) continue;
      const { fromCityId, toCityId, bucket, tonnageClass: tc } = group[0];
      const id = { fromCityId, toCityId, bucket, tonnageClass: tc };
      const data = { median: stats.median, p25: stats.p25, p75: stats.p75, points: stats.points, dealPoints: unique.filter((p) => p.kind === 'DEAL').length, computedAt: now };
      await this.prisma.routePriceStat.upsert({ where: { fromCityId_toCityId_bucket_tonnageClass: id }, create: { ...id, ...data }, update: data });
      keep.push(id);
    }
    const stale = await this.prisma.routePriceStat.findMany({ select: { fromCityId: true, toCityId: true, bucket: true, tonnageClass: true } });
    for (const s of stale) {
      if (!keep.some((k) => k.fromCityId === s.fromCityId && k.toCityId === s.toCityId && k.bucket === s.bucket && k.tonnageClass === s.tonnageClass)) {
        await this.prisma.routePriceStat.delete({ where: { fromCityId_toCityId_bucket_tonnageClass: s } });
      }
    }
    return { routes: keep.length };
  }

  /// «Рынок за месяц» по маршруту груза — `null`, если данных мало.
  async marketFor(fromCityId: string, toCityId: string | null, countryCode: string, weightKg: number | null) {
    if (!toCityId) return null;
    const row = await this.prisma.routePriceStat.findUnique({
      where: { fromCityId_toCityId_bucket_tonnageClass: { fromCityId, toCityId, bucket: bucketForCountry(countryCode), tonnageClass: tonnageClass(weightKg) } },
    });
    return row ? { median: Number(row.median), p25: Number(row.p25), p75: Number(row.p75), points: row.points, dealPoints: row.dealPoints } : null;
  }

  /// Грузы без расстояния (OSRM был недоступен) — досчитать.
  async fillMissingDistances(limit = 200): Promise<{ filled: number }> {
    const cargos = await this.prisma.cargo.findMany({
      where: { distanceKm: null, destinationCityId: { not: null }, status: { in: ['PUBLISHED', 'IN_DEAL'] } },
      include: { point: { select: { cityId: true } }, destinationCountry: { select: { code: true } }, company: { select: { isVerified: true } } },
      take: limit,
    });
    let filled = 0;
    for (const c of cargos) {
      const d = await this.distanceFor(c);
      if (d.distanceKm == null) continue;
      await this.prisma.cargo.update({ where: { id: c.id }, data: { distanceKm: d.distanceKm, pricePerKm: d.pricePerKm } });
      // 049 п.11: км появились — груз попадает в статистику цен.
      if (c.company.isVerified) await this.upsertListedPoint({ ...c, distanceKm: d.distanceKm });
      filled += 1;
    }
    return { filled };
  }
}
