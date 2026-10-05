import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Arrival } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AnnounceArrivalDto } from './dto/arrival.dto';

const MAX_DAYS_AHEAD = 14;
const STALE_AFTER_HOURS = 24;

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function sameDay(a: Date, b: Date): boolean {
  return startOfDay(a).getTime() === startOfDay(b).getTime();
}

@Injectable()
export class ArrivalsService {
  constructor(private readonly prisma: PrismaService) {}

  private async toDto(arrival: Arrival) {
    const [directions, viewsCount] = await Promise.all([
      this.prisma.arrivalDirection.findMany({ where: { arrivalId: arrival.id }, select: { countryId: true } }),
      this.prisma.arrivalView.count({ where: { arrivalId: arrival.id } }),
    ]);

    return {
      id: arrival.id,
      pointId: arrival.pointId,
      plannedAt: arrival.plannedAt,
      arrivedAt: arrival.arrivedAt,
      waitDays: arrival.waitDays,
      anyCountry: arrival.anyCountry,
      countryIds: directions.map((d) => d.countryId),
      status: arrival.status,
      viewsCount,
    };
  }

  /// PLANNED, чей plannedAt прошёл больше чем на 24 ч без перехода в
  /// ON_SITE, сам угасает (п. 4 задачи 015). Полноценный фоновый cron —
  /// задача 018; здесь — ленивая проверка при каждом чтении, достаточная
  /// для текущего масштаба.
  private async expireStale(where: { driverId: string } | Record<string, never> = {}) {
    const staleBefore = new Date(Date.now() - STALE_AFTER_HOURS * 60 * 60 * 1000);
    await this.prisma.arrival.updateMany({
      where: { ...where, status: 'PLANNED', plannedAt: { lt: staleBefore } },
      data: { status: 'CANCELLED' },
    });
  }

  async getMine(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    await this.expireStale({ driverId: driver.id });

    const arrival = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: { createdAt: 'desc' },
    });
    // Обёртка в объект, а не голый null (задача 027): NestJS отдаёт bare
    // null пустым телом без Content-Type, и Dio кладёт в res.data пустую
    // строку '' вместо null — `'' as Map` падает на клиенте.
    return { arrival: arrival ? await this.toDto(arrival) : null };
  }

  /// Шаблон для «Повторить прошлый анонс» (п. 6) — последний отменённый
  /// или завершённый анонс водителя, без привязки к дате.
  async getLastTemplate(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const last = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['COMPLETED', 'CANCELLED'] } },
      orderBy: { updatedAt: 'desc' },
    });
    if (!last) return { template: null };

    const directions = await this.prisma.arrivalDirection.findMany({
      where: { arrivalId: last.id },
      select: { countryId: true },
    });
    return {
      template: { pointId: last.pointId, anyCountry: last.anyCountry, countryIds: directions.map((d) => d.countryId) },
    };
  }

  /// Связка на поездку (задача 031, этап A, п.5) — по умолчанию та же, что
  /// в прошлом анонсе; если анонсов ещё не было, берём текущий тягач/прицеп
  /// водителя из гаража. Выбор связки шагом анонса — Stage B; здесь только
  /// заполняем поле, ничего не ломая в текущем Flutter-клиенте.
  private async resolveDefaultVehicleCombo(driverId: string): Promise<{ tractorId: string | null; trailerId: string | null }> {
    const lastWithCombo = await this.prisma.arrival.findFirst({
      where: { driverId, OR: [{ tractorId: { not: null } }, { trailerId: { not: null } }] },
      orderBy: { createdAt: 'desc' },
      select: { tractorId: true, trailerId: true },
    });
    if (lastWithCombo) return lastWithCombo;

    const [tractor, trailer] = await Promise.all([
      this.prisma.vehicle.findFirst({ where: { driverId, kind: { in: ['TRACTOR', 'RIGID'] }, isArchived: false }, orderBy: { createdAt: 'asc' } }),
      this.prisma.vehicle.findFirst({ where: { driverId, kind: 'TRAILER', isArchived: false }, orderBy: { createdAt: 'asc' } }),
    ]);
    return { tractorId: tractor?.id ?? null, trailerId: trailer?.id ?? null };
  }

  /// Анонс «буду на точке» — создаёт новый активный анонс или обновляет уже
  /// существующий PLANNED (один активный анонс на водителя, п. 2). Если
  /// водитель уже ON_SITE, дата/точка не трогаются — меняются только
  /// направления/срок ожидания на эту поездку.
  async announce(userId: string, dto: AnnounceArrivalDto) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const point = await this.prisma.point.findUnique({ where: { id: dto.pointId } });
    if (!point || !point.isActive) throw new NotFoundException('Point not found');

    const plannedAt = new Date(dto.plannedAt);
    const maxDate = new Date(Date.now() + MAX_DAYS_AHEAD * 24 * 60 * 60 * 1000);
    if (plannedAt > maxDate) {
      throw new BadRequestException(`plannedAt must be within ${MAX_DAYS_AHEAD} days`);
    }

    const anyCountry = dto.anyCountry ?? false;
    const countryIds = anyCountry ? [] : (dto.countryIds ?? []);
    const waitDays = dto.waitDays ?? 2;

    const existing = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['PLANNED', 'ON_SITE'] } },
    });
    const combo = existing ? null : await this.resolveDefaultVehicleCombo(driver.id);

    const arrival = await this.prisma.$transaction(async (tx) => {
      const saved =
        existing && existing.status === 'ON_SITE'
          ? await tx.arrival.update({ where: { id: existing.id }, data: { anyCountry, waitDays } })
          : existing
            ? await tx.arrival.update({
                where: { id: existing.id },
                data: { pointId: dto.pointId, plannedAt, anyCountry, waitDays, status: 'PLANNED' },
              })
            : await tx.arrival.create({
                data: {
                  driverId: driver.id,
                  pointId: dto.pointId,
                  plannedAt,
                  anyCountry,
                  waitDays,
                  status: 'PLANNED',
                  tractorId: combo?.tractorId,
                  trailerId: combo?.trailerId,
                },
              });

      await tx.arrivalDirection.deleteMany({ where: { arrivalId: saved.id } });
      if (!anyCountry && countryIds.length > 0) {
        await tx.arrivalDirection.createMany({
          data: countryIds.map((countryId) => ({ arrivalId: saved.id, countryId })),
          skipDuplicates: true,
        });
      }
      return saved;
    });

    return this.toDto(arrival);
  }

  /// «Повторить прошлый анонс» (п. 6) — тот же терминал и страны, дата —
  /// сегодня.
  async repeat(userId: string) {
    const { template } = await this.getLastTemplate(userId);
    if (!template) throw new NotFoundException('No previous announcement to repeat');

    return this.announce(userId, {
      pointId: template.pointId,
      plannedAt: new Date().toISOString(),
      anyCountry: template.anyCountry,
      countryIds: template.countryIds,
    });
  }

  /// «Я уже на месте»: переводит PLANNED в ON_SITE. Если активного анонса
  /// нет — короткий путь без похода в шторку (как раньше): анонс создаётся
  /// сразу ON_SITE на первой активной точке с направлениями из профиля.
  async checkIn(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const existing = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['PLANNED', 'ON_SITE'] } },
    });

    if (existing) {
      const arrival = await this.prisma.arrival.update({
        where: { id: existing.id },
        data: { status: 'ON_SITE', arrivedAt: new Date() },
      });
      return this.toDto(arrival);
    }

    const point = await this.prisma.point.findFirst({ where: { isActive: true } });
    if (!point) throw new NotFoundException('No active loading point configured');

    const directions = await this.prisma.driverDirection.findMany({ where: { driverId: driver.id } });

    const arrival = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.arrival.create({
        data: {
          driverId: driver.id,
          pointId: point.id,
          plannedAt: new Date(),
          arrivedAt: new Date(),
          status: 'ON_SITE',
          anyCountry: driver.anyCountry,
        },
      });
      if (!driver.anyCountry && directions.length > 0) {
        await tx.arrivalDirection.createMany({
          data: directions.map((d) => ({ arrivalId: saved.id, countryId: d.countryId })),
          skipDuplicates: true,
        });
      }
      return saved;
    });

    return this.toDto(arrival);
  }

  /// «Отменить» (и алиас для старого «Я уехал») — завершает активный анонс.
  async cancel(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const existing = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['PLANNED', 'ON_SITE'] } },
    });
    if (!existing) return null;

    const status = existing.status === 'ON_SITE' ? 'COMPLETED' : 'CANCELLED';
    const arrival = await this.prisma.arrival.update({ where: { id: existing.id }, data: { status } });
    return this.toDto(arrival);
  }

  /// «Кто будет на точке» (макет 06) — для логиста, по дню. `date` не задан
  /// → сегодня. Для сегодняшнего дня считаются и ON_SITE, и PLANNED на
  /// сегодня; для остальных дней — только PLANNED на этот день (п. 10).
  /// Фильтр по стране — по направлениям ЭТОЙ поездки (ArrivalDirection),
  /// не по постоянному профилю водителя (п. 12 — отличие от старой версии).
  async listForCompany(
    companyId: string,
    filters: {
      date?: Date;
      pointId?: string;
      countryId?: string;
      bodyTypeId?: string;
      minCapacityTons?: number;
      verifiedOnly?: boolean;
    },
  ) {
    await this.expireStale();

    const targetDate = filters.date ?? new Date();
    const isToday = sameDay(targetDate, new Date());

    const arrivals = await this.prisma.arrival.findMany({
      where: {
        status: { in: ['PLANNED', 'ON_SITE'] },
        pointId: filters.pointId,
      },
      include: { driver: { include: { user: true } }, directions: true },
      orderBy: { plannedAt: 'asc' },
    });

    const dayFiltered = arrivals.filter((a) => {
      if (isToday && a.status === 'ON_SITE') return true;
      return sameDay(a.plannedAt, targetDate);
    });

    // Задача 031, этап A, п.6 — кузов/тоннаж связки ЭТОЙ поездки (её прицеп,
    // либо сама машина для RIGID-одиночки), не первой попавшейся машины
    // гаража. Старые записи без связки (до миграции 031) — по-прежнему
    // берём единственную TRAILER/RIGID машину водителя.
    const rows = await Promise.all(
      dayFiltered.map(async (arrival) => {
        const vehicle = arrival.trailerId
          ? await this.prisma.vehicle.findUnique({ where: { id: arrival.trailerId } })
          : arrival.tractorId
            ? await this.prisma.vehicle.findUnique({ where: { id: arrival.tractorId } })
            : await this.prisma.vehicle.findFirst({
                where: { driverId: arrival.driverId, kind: { in: ['TRAILER', 'RIGID'] } },
                orderBy: { createdAt: 'asc' },
              });
        return { arrival, vehicle };
      }),
    );

    const filtered = rows
      .filter((r) => !filters.verifiedOnly || r.arrival.driver.isVerified)
      .filter((r) => !filters.bodyTypeId || r.vehicle?.bodyTypeId === filters.bodyTypeId)
      .filter(
        (r) =>
          !filters.minCapacityTons ||
          (r.vehicle?.capacityTons != null && Number(r.vehicle.capacityTons) >= filters.minCapacityTons!),
      )
      .filter(
        (r) =>
          !filters.countryId ||
          r.arrival.anyCountry ||
          r.arrival.directions.some((d) => d.countryId === filters.countryId),
      );

    if (filtered.length > 0) {
      await this.prisma.arrivalView.createMany({
        data: filtered.map((r) => ({ arrivalId: r.arrival.id, companyId })),
        skipDuplicates: true,
      });
    }

    return filtered.map((r) => ({
      arrivalId: r.arrival.id,
      driverId: r.arrival.driver.id,
      driverName: r.arrival.driver.fullName,
      phone: r.arrival.driver.user.phone,
      isVerified: r.arrival.driver.isVerified,
      ratingAvg: Number(r.arrival.driver.ratingAvg),
      ratingCount: r.arrival.driver.ratingCount,
      pointId: r.arrival.pointId,
      status: r.arrival.status,
      plannedAt: r.arrival.plannedAt,
      arrivedAt: r.arrival.arrivedAt,
      bodyTypeId: r.vehicle?.bodyTypeId ?? null,
      capacityTons: r.vehicle?.capacityTons ? Number(r.vehicle.capacityTons) : null,
      anyCountry: r.arrival.anyCountry,
      directionCountryIds: r.arrival.directions.map((d) => d.countryId),
    }));
  }

  /// Полоса дней у логиста (п. 9-10) — число водителей по каждому из
  /// ближайших `days` дней, начиная с сегодня.
  async summary(days: number, pointId?: string) {
    await this.expireStale();

    const today = startOfDay(new Date());
    const arrivals = await this.prisma.arrival.findMany({
      where: { status: { in: ['PLANNED', 'ON_SITE'] }, pointId },
      select: { plannedAt: true, status: true },
    });

    const result: { date: string; count: number }[] = [];
    for (let i = 0; i < days; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() + i);
      const isToday = i === 0;
      // ON_SITE считается только в сегодняшний день, даже если plannedAt
      // (когда собирались приехать) приходится на другую дату — водитель
      // физически уже на месте сейчас, а не "планируется" на будущий день.
      const count = arrivals.filter((a) =>
        isToday ? a.status === 'ON_SITE' || sameDay(a.plannedAt, date) : a.status === 'PLANNED' && sameDay(a.plannedAt, date),
      ).length;
      result.push({ date: date.toISOString(), count });
    }
    return result;
  }
}
