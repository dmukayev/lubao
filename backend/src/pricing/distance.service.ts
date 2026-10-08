import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type FetchLike = (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

/// Расстояние по дороге между городами справочника (047 п.2, decisions.md
/// 2026-10-08 «Расстояния — свой OSRM»): свой контейнер OSRM, без Google и
/// внешних API. Считается один раз на пару и кэшируется в `city_distances`
/// (в обе стороны — дорога та же). OSRM недоступен — `null` («—»), груз
/// досчитает планировщик.
@Injectable()
export class DistanceService {
  private readonly logger = new Logger(DistanceService.name);

  constructor(private readonly prisma: PrismaService) {}

  /// Подменяется в тестах.
  fetchFn: FetchLike = (url) => fetch(url, { signal: AbortSignal.timeout(5000) });

  private get baseUrl(): string | null {
    return process.env.OSRM_URL || null;
  }

  async roadKm(fromCityId: string | null | undefined, toCityId: string | null | undefined): Promise<number | null> {
    if (!fromCityId || !toCityId) return null;
    if (fromCityId === toCityId) return 0;
    const [a, b] = fromCityId < toCityId ? [fromCityId, toCityId] : [toCityId, fromCityId];
    const cached = await this.prisma.cityDistance.findUnique({ where: { fromCityId_toCityId: { fromCityId: a, toCityId: b } } });
    if (cached) return cached.km;

    const base = this.baseUrl;
    if (!base) return null;
    const cities = await this.prisma.city.findMany({ where: { id: { in: [a, b] } }, select: { id: true, lat: true, lng: true } });
    const from = cities.find((c) => c.id === a);
    const to = cities.find((c) => c.id === b);
    if (from?.lat == null || from.lng == null || to?.lat == null || to.lng == null) return null;

    const coords = `${Number(from.lng)},${Number(from.lat)};${Number(to.lng)},${Number(to.lat)}`;
    try {
      const res = await this.fetchFn(`${base.replace(/\/$/, '')}/route/v1/driving/${coords}?overview=false`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const body = (await res.json()) as { code?: string; routes?: Array<{ distance?: number }> };
      const meters = body.code === 'Ok' ? body.routes?.[0]?.distance : undefined;
      if (meters == null || !Number.isFinite(meters)) throw new Error(`no route (${body.code ?? '?'})`);
      const km = Math.round(meters / 1000);
      await this.prisma.cityDistance.upsert({
        where: { fromCityId_toCityId: { fromCityId: a, toCityId: b } },
        create: { fromCityId: a, toCityId: b, km, source: 'osrm' },
        update: { km, source: 'osrm', computedAt: new Date() },
      });
      return km;
    } catch (e) {
      this.logger.warn(`OSRM: расстояние ${a} → ${b} не получено: ${(e as Error).message}`);
      return null;
    }
  }
}
