import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Arrival } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { haulInfoByDriver } from '../deals/haul-summary';
import { addDaysDateOnly, localDateOnly, parseDateOnly, toDateOnly } from '../common/date-only';
import { AnnounceArrivalDto } from './dto/arrival.dto';
import { decideFreshness } from './arrival-freshness';

const MAX_DAYS_AHEAD = 14;
/// Несколько анонсов подряд разрешены («в Алматы до чт, потом в Астане»),
/// но не бесконечно.
const MAX_ACTIVE_ARRIVALS = 5;

@Injectable()
export class ArrivalsService {
  private readonly logger = new Logger(ArrivalsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications?: NotificationsService,
  ) {}

  private async toDto(arrival: Arrival) {
    const [directions, viewsCount] = await Promise.all([
      this.prisma.arrivalDirection.findMany({ where: { arrivalId: arrival.id }, select: { countryId: true } }),
      this.prisma.arrivalView.count({ where: { arrivalId: arrival.id } }),
    ]);

    return {
      id: arrival.id,
      pointId: arrival.pointId,
      plannedAt: arrival.plannedAt,
      plannedDay: toDateOnly(arrival.plannedDay),
      arrivedAt: arrival.arrivedAt,
      waitDays: arrival.waitDays,
      anyCountry: arrival.anyCountry,
      countryIds: directions.map((d) => d.countryId),
      status: arrival.status,
      viewsCount,
      tractorId: arrival.tractorId,
      trailerId: arrival.trailerId,
      lastConfirmedAt: arrival.lastConfirmedAt,
      // Что приложению спросить у водителя сейчас (040, п.4): «Доехали?» в
      // день приезда либо «Ещё ищете груз?» после напоминания.
      ask: this.pendingQuestion(arrival),
    };
  }

  private pendingQuestion(a: Arrival): 'DAY' | 'STILL_LOOKING' | null {
    if (a.status === 'PLANNED') return a.dayAskedAt ? 'DAY' : null;
    if (a.status === 'ON_SITE' && a.staleAskedAt) {
      const lastAnswer = a.lastConfirmedAt ?? a.arrivedAt ?? a.plannedAt;
      return a.staleAskedAt.getTime() >= lastAnswer.getTime() ? 'STILL_LOOKING' : null;
    }
    return null;
  }

  /// Правила свежести (задача 040) применяются так: фоновый планировщик
  /// раз в 5 минут (`ArrivalsScheduler` → `sweep` с уведомлениями) и ленивая
  /// проверка при чтении (только гашение, без push) — чтобы выдача не
  /// зависела от того, жив ли планировщик.
  async sweep(opts: { now?: Date; notify: boolean; driverId?: string }): Promise<{ expired: number; asked: number }> {
    const now = opts.now ?? new Date();
    const rows = await this.prisma.arrival.findMany({
      where: { status: { in: ['PLANNED', 'ON_SITE'] }, ...(opts.driverId ? { driverId: opts.driverId } : {}) },
      include: { point: { select: { name: true } }, driver: { select: { userId: true } } },
    });

    let expired = 0;
    let asked = 0;
    for (const row of rows) {
      const action = decideFreshness(row, now);
      if (action === 'EXPIRE') {
        const res = await this.prisma.arrival.updateMany({ where: { id: row.id, status: row.status }, data: { status: 'EXPIRED' } });
        expired += res.count;
      } else if (opts.notify && (action === 'ASK_DAY' || action === 'ASK_STILL_LOOKING')) {
        const data = action === 'ASK_DAY' ? { dayAskedAt: now } : { staleAskedAt: now };
        // Условный апдейт: два тика/инстанса не пришлют push дважды.
        const res = await this.prisma.arrival.updateMany({
          where: { id: row.id, status: row.status, ...(action === 'ASK_DAY' ? { dayAskedAt: null } : { staleAskedAt: row.staleAskedAt }) },
          data,
        });
        if (res.count === 0) continue;
        asked += 1;
        await this.notifications?.notify(
          { userIds: [row.driver.userId] },
          action === 'ASK_DAY' ? 'ARRIVAL_DAY_CHECK' : 'ARRIVAL_STILL_LOOKING',
          { pointName: row.point.name },
        );
      }
    }
    if (expired || asked) this.logger.log(`arrivals sweep: expired=${expired}, asked=${asked}`);
    return { expired, asked };
  }

  private async expireStale(where: { driverId?: string } = {}) {
    await this.sweep({ notify: false, driverId: where.driverId });
  }

  /// Текущий анонс — тот, где водитель на месте; иначе ближайший по дате.
  private static current<T extends { status: string; plannedDay: Date }>(active: T[]): T | undefined {
    return active.find((a) => a.status === 'ON_SITE') ?? active[0];
  }

  private async activeFor(driverId: string) {
    const active = await this.prisma.arrival.findMany({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: [{ plannedDay: 'asc' }, { createdAt: 'asc' }],
    });
    // ON_SITE первым, остальные — по дате приезда.
    return [...active.filter((a) => a.status === 'ON_SITE'), ...active.filter((a) => a.status !== 'ON_SITE')];
  }

  /// «Сегодня» — по календарю клиента (041, п.13): день, который видит
  /// водитель, не зависит от серверного часового пояса. Мусор или значение
  /// дальше чем на ±2 суток от серверного — игнорируется (серверное «сегодня»).
  static resolveToday(clientToday: string | undefined, now = new Date()): string {
    const server = localDateOnly(now);
    if (!clientToday || !/^\d{4}-\d{2}-\d{2}$/.test(clientToday)) return server;
    const diffDays = Math.abs(parseDateOnly(clientToday).getTime() - parseDateOnly(server).getTime()) / (24 * 60 * 60 * 1000);
    return Number.isFinite(diffDays) && diffDays <= 2 ? clientToday : server;
  }

  async getMine(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    await this.expireStale({ driverId: driver.id });

    const active = await this.activeFor(driver.id);
    const current = ArrivalsService.current(active);
    // Обёртка в объект, а не голый null (задача 027): NestJS отдаёт bare
    // null пустым телом без Content-Type, и Dio кладёт в res.data пустую
    // строку '' вместо null — `'' as Map` падает на клиенте.
    return {
      arrival: current ? await this.toDto(current) : null,
      arrivals: await Promise.all(active.map((a) => this.toDto(a))),
    };
  }

  /// Шаблон для «Повторить прошлый анонс» (п. 6) — последний отменённый
  /// или завершённый анонс водителя, без привязки к дате.
  async getLastTemplate(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const last = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: { in: ['COMPLETED', 'CANCELLED', 'EXPIRED'] } },
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
    // Задача 032, п.12 (038) — прошлая связка могла устареть: машина уже
    // в архиве. Проверяем каждую и выкидываем архивные, а не подставляем
    // слепо; оставшиеся дыры добираем из гаража ниже.
    let fromLast: { tractorId: string | null; trailerId: string | null } | null = null;
    if (lastWithCombo) {
      const ids = [lastWithCombo.tractorId, lastWithCombo.trailerId].filter((v): v is string => v != null);
      const alive = await this.prisma.vehicle.findMany({ where: { id: { in: ids }, isArchived: false }, select: { id: true, kind: true } });
      const byId = new Map(alive.map((v) => [v.id, v]));
      const tractor = lastWithCombo.tractorId ? byId.get(lastWithCombo.tractorId) : undefined;
      const trailer = lastWithCombo.trailerId ? byId.get(lastWithCombo.trailerId) : undefined;
      // Типы проверяем так же, как при явном выборе: в «тягаче» не прицеп,
      // в «прицепе» не тягач, у RIGID-одиночки прицепа нет (039, п.5).
      const tractorOk = tractor && tractor.kind !== 'TRAILER' ? tractor : undefined;
      const trailerOk = trailer && trailer.kind === 'TRAILER' && tractorOk?.kind !== 'RIGID' ? trailer : undefined;
      fromLast = { tractorId: tractorOk?.id ?? null, trailerId: trailerOk?.id ?? null };
      if (fromLast.tractorId) return fromLast;
    }

    const [tractor, trailer] = await Promise.all([
      this.prisma.vehicle.findFirst({ where: { driverId, kind: { in: ['TRACTOR', 'RIGID'] }, isArchived: false }, orderBy: { createdAt: 'asc' } }),
      this.prisma.vehicle.findFirst({ where: { driverId, kind: 'TRAILER', isArchived: false }, orderBy: { createdAt: 'asc' } }),
    ]);
    // RIGID-одиночка — без прицепа (039, п.5).
    if (tractor?.kind === 'RIGID') return { tractorId: tractor.id, trailerId: null };
    // Прицеп из прошлой связки переносим, только если у неё вообще не было
    // тягача; если тягач ушёл в архив, прицеп принадлежал старой паре (039, п.5).
    const carriedTrailer = lastWithCombo && lastWithCombo.tractorId == null ? fromLast?.trailerId : null;
    return { tractorId: tractor?.id ?? null, trailerId: carriedTrailer ?? trailer?.id ?? null };
  }

  /// Анонс «свободен в <город> с <даты>» (задача 040, п.3). Анонсов может
  /// быть несколько подряд — разные города/даты; повторный анонс на тот же
  /// город и тот же день обновляет существующий, а не плодит дубли. С
  /// `arrivalId` правится конкретный анонс. Водитель уже ON_SITE — дата и
  /// город не трогаются, меняются только направления/срок/связка.
  async announce(userId: string, dto: AnnounceArrivalDto) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const point = await this.prisma.point.findUnique({ where: { id: dto.pointId } });
    if (!point || !point.isActive) throw new NotFoundException('Point not found');

    const plannedAt = new Date(dto.plannedAt);
    // День приезда — календарная дата от клиента (041, п.5); для старых
    // клиентов — календарная часть plannedAt.
    const plannedDay = parseDateOnly(dto.plannedDay ?? dto.plannedAt);
    const maxDate = new Date(Date.now() + MAX_DAYS_AHEAD * 24 * 60 * 60 * 1000);
    if (plannedAt > maxDate) {
      throw new BadRequestException(`plannedAt must be within ${MAX_DAYS_AHEAD} days`);
    }

    const anyCountry = dto.anyCountry ?? false;
    const countryIds = anyCountry ? [] : (dto.countryIds ?? []);
    const waitDays = dto.waitDays ?? 2;

    await this.expireStale({ driverId: driver.id });
    const active = await this.activeFor(driver.id);
    const existing = dto.arrivalId
      ? active.find((a) => a.id === dto.arrivalId)
      : active.find((a) => a.status === 'PLANNED' && a.pointId === dto.pointId && toDateOnly(a.plannedDay) === toDateOnly(plannedDay));
    if (dto.arrivalId && !existing) throw new NotFoundException('Arrival not found');
    if (!existing && active.length >= MAX_ACTIVE_ARRIVALS) {
      throw new BadRequestException('TOO_MANY_ARRIVALS');
    }

    // Задача 031, этап B, п.9 — шаг «На чём еду»: явный выбор в dto
    // проверяется (машина должна быть в гараже этого водителя и не в
    // архиве) и используется; без явного выбора — связка прошлого анонса по
    // умолчанию (этап A) при создании нового анонса, а у уже существующего
    // анонса связка остаётся как была (не затирается каждым мелким
    // редактированием срока/направлений).
    let combo: { tractorId: string | null; trailerId: string | null } | null = null;
    if (dto.tractorId !== undefined || dto.trailerId !== undefined) {
      const ids = [dto.tractorId, dto.trailerId].filter((v): v is string => v != null);
      if (ids.length > 0) {
        const owned = await this.prisma.vehicle.findMany({ where: { id: { in: ids }, driverId: driver.id, isArchived: false } });
        if (owned.length !== ids.length) throw new BadRequestException('Unknown vehicle in combo');
        // Задача 032, п.12 (038) — проверка ТИПОВ связки: в tractorId нельзя
        // подставить прицеп, в trailerId — тягач, а у RIGID-одиночки
        // прицепа не бывает вовсе.
        const byId = new Map(owned.map((v) => [v.id, v]));
        const tractor = dto.tractorId ? byId.get(dto.tractorId) : null;
        if (tractor && tractor.kind === 'TRAILER') throw new BadRequestException('tractorId must be a tractor or rigid truck');
        const trailer = dto.trailerId ? byId.get(dto.trailerId) : null;
        if (trailer && trailer.kind !== 'TRAILER') throw new BadRequestException('trailerId must be a trailer');
        if (tractor?.kind === 'RIGID' && dto.trailerId) throw new BadRequestException('A rigid truck has no trailer');
      }
      combo = { tractorId: dto.tractorId ?? null, trailerId: dto.trailerId ?? null };
    } else if (!existing) {
      combo = await this.resolveDefaultVehicleCombo(driver.id);
    }

    const arrival = await this.prisma.$transaction(async (tx) => {
      const saved =
        existing && existing.status === 'ON_SITE'
          ? await tx.arrival.update({
              where: { id: existing.id },
              data: { anyCountry, waitDays, ...(combo ?? {}) },
            })
          : existing
            ? await tx.arrival.update({
                where: { id: existing.id },
                // Сменили дату/город — вопрос «Доехали?» для нового дня ещё не задавался.
                data: { pointId: dto.pointId, plannedAt, plannedDay, anyCountry, waitDays, status: 'PLANNED', dayAskedAt: null, ...(combo ?? {}) },
              })
            : await tx.arrival.create({
                data: {
                  driverId: driver.id,
                  pointId: dto.pointId,
                  plannedAt,
                  plannedDay,
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

  /// «Повторить прошлый анонс» (п. 6) — тот же город и страны, дата — сегодня.
  async repeat(userId: string, clientToday?: string) {
    const { template } = await this.getLastTemplate(userId);
    if (!template) throw new NotFoundException('No previous announcement to repeat');

    return this.announce(userId, {
      pointId: template.pointId,
      plannedAt: new Date().toISOString(),
      plannedDay: ArrivalsService.resolveToday(clientToday),
      anyCountry: template.anyCountry,
      countryIds: template.countryIds,
    });
  }

  /// «Я на месте»: переводит анонс в ON_SITE. `arrivalId` не задан — берём
  /// ближайший запланированный на сегодня или раньше (иначе — ближайший по
  /// дате). Одновременно «на месте» — только один анонс: прежний гаснет
  /// (водитель переехал в другой город). Если активного анонса нет — короткий
  /// путь без шторки: анонс создаётся сразу ON_SITE в городе из `pointId`,
  /// иначе в городе водителя из профиля.
  async checkIn(userId: string, arrivalId?: string, pointId?: string, clientToday?: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    await this.expireStale({ driverId: driver.id });
    const active = await this.activeFor(driver.id);
    const today = ArrivalsService.resolveToday(clientToday);

    const target = arrivalId
      ? active.find((a) => a.id === arrivalId)
      : (active.find((a) => a.status === 'ON_SITE') ??
        active.find((a) => toDateOnly(a.plannedDay) <= today) ??
        active[0]);
    if (arrivalId && !target) throw new NotFoundException('Arrival not found');

    const now = new Date();
    if (target) {
      const arrival = await this.prisma.$transaction(async (tx) => {
        await tx.arrival.updateMany({ where: { driverId: driver.id, status: 'ON_SITE', id: { not: target.id } }, data: { status: 'COMPLETED' } });
        return tx.arrival.update({
          where: { id: target.id },
          data: {
            status: 'ON_SITE',
            arrivedAt: target.status === 'ON_SITE' ? target.arrivedAt : now,
            // «Я на месте» — это и есть ответ на «Доехали?»/«Ещё ищете груз?».
            lastConfirmedAt: now,
          },
        });
      });
      return this.toDto(arrival);
    }

    const point = pointId
      ? await this.prisma.point.findFirst({ where: { id: pointId, isActive: true } })
      : ((await this.prisma.point.findFirst({ where: { cityId: driver.homeCityId, isActive: true } })) ??
        (await this.prisma.point.findFirst({ where: { isActive: true }, orderBy: { createdAt: 'asc' } })));
    if (!point) throw new NotFoundException('No active loading point configured');

    const directions = await this.prisma.driverDirection.findMany({ where: { driverId: driver.id } });

    const arrival = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.arrival.create({
        data: {
          driverId: driver.id,
          pointId: point.id,
          plannedAt: now,
          plannedDay: parseDateOnly(today),
          arrivedAt: now,
          lastConfirmedAt: now,
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

  /// «Да, ещё ищу» на вопрос «Ещё ищете груз?» — отсчёт 12 ч начинается заново.
  async confirmStillLooking(userId: string, arrivalId?: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const onSite = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: 'ON_SITE', ...(arrivalId ? { id: arrivalId } : {}) },
    });
    if (!onSite) throw new NotFoundException('Arrival not found');
    const arrival = await this.prisma.arrival.update({ where: { id: onSite.id }, data: { lastConfirmedAt: new Date() } });
    return this.toDto(arrival);
  }

  /// «Отменить» (и «Я уехал») — завершает анонс: `arrivalId` не задан — тот,
  /// где водитель на месте, иначе ближайший.
  async cancel(userId: string, arrivalId?: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const active = await this.activeFor(driver.id);
    const existing = arrivalId ? active.find((a) => a.id === arrivalId) : ArrivalsService.current(active);
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
      /// `YYYY-MM-DD` — день, который выбрал логист; `today` — его «сегодня»
      /// (клиент знает свой календарь, сервер часовых поясов не считает).
      date?: string;
      today?: string;
      pointId?: string;
      countryId?: string;
      bodyTypeId?: string;
      minCapacityTons?: number;
      verifiedOnly?: boolean;
    },
  ) {
    await this.expireStale();

    const todayStr = filters.today ?? toDateOnly(new Date());
    const targetStr = filters.date ?? todayStr;
    const isToday = targetStr === todayStr;

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
      return toDateOnly(a.plannedDay) === targetStr;
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
        // 045 п.5: машины ещё нет — кузов и тоннаж из регистрации водителя.
        const body = {
          bodyTypeId: vehicle?.bodyTypeId ?? arrival.driver.preferredBodyTypeId ?? null,
          capacityTons: vehicle?.capacityTons ?? arrival.driver.preferredCapacityTons ?? null,
          // 048 п.6: строка машины у логиста — по профилю кузова.
          specs: (vehicle ? vehicle.specs : arrival.driver.preferredSpecs) ?? null,
        };
        return { arrival, vehicle, body };
      }),
    );

    const filtered = rows
      .filter((r) => !filters.verifiedOnly || r.arrival.driver.isVerified)
      .filter((r) => !filters.bodyTypeId || r.body.bodyTypeId === filters.bodyTypeId)
      .filter(
        (r) =>
          !filters.minCapacityTons ||
          (r.body.capacityTons != null && Number(r.body.capacityTons) >= filters.minCapacityTons!),
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

    // Задача 037, п.7 / 038, п.8 — логист видит ДО выбора, что водитель
    // уже везёт догруз: «Уже везёт: 8 т из 20 т · Алматы · погрузка
    // завтра». Считается по тягачу связки анонса — те же правила, что у
    // жёсткой проверки при подтверждении; груз без веса — флаг «машина
    // занята». Не запрет, просто прозрачность.
    const committedByDriver = await haulInfoByDriver(
      this.prisma,
      filtered.map((r) => ({ driverId: r.arrival.driver.id, tractorId: r.arrival.tractorId })),
    );

    // Задача 038, п.15 (037, п.8) — доля отмен в карточке водителя для
    // логиста: «отменил 1 из 15 сделок». Два groupBy на весь список, не
    // по запросу на водителя.
    const driverIds = [...new Set(filtered.map((r) => r.arrival.driver.id))];
    const [totalsByDriver, cancelledByDriver] = driverIds.length
      ? await Promise.all([
          this.prisma.deal.groupBy({ by: ['driverId'], where: { driverId: { in: driverIds } }, _count: true }),
          this.prisma.deal.groupBy({
            by: ['driverId'],
            where: { driverId: { in: driverIds }, status: 'CANCELLED', cancelledByRole: 'DRIVER' },
            _count: true,
          }),
        ])
      : [[], []];
    const dealsTotalMap = new Map(totalsByDriver.map((g) => [g.driverId, g._count as unknown as number]));
    const dealsCancelledMap = new Map(cancelledByDriver.map((g) => [g.driverId, g._count as unknown as number]));

    return filtered.map((r) => ({
      arrivalId: r.arrival.id,
      driverId: r.arrival.driver.id,
      driverName: r.arrival.driver.fullName,
      // Номер — только по нажатию «Позвонить» (POST /drivers/:id/contact, 043 п.11).
      hasPhone: !!r.arrival.driver.user.phone,
      isVerified: r.arrival.driver.isVerified,
      ratingAvg: Number(r.arrival.driver.ratingAvg),
      ratingCount: r.arrival.driver.ratingCount,
      pointId: r.arrival.pointId,
      status: r.arrival.status,
      plannedAt: r.arrival.plannedAt,
      plannedDay: toDateOnly(r.arrival.plannedDay),
      arrivedAt: r.arrival.arrivedAt,
      bodyTypeId: r.body.bodyTypeId,
      specs: r.body.specs,
      capacityTons: r.body.capacityTons != null ? Number(r.body.capacityTons) : null,
      // Задача 033, п.9 — «тент · 20 т · 90 м³ · 33 пал.» в «Кто будет».
      volumeM3: r.vehicle?.volumeM3 != null ? Number(r.vehicle.volumeM3) : null,
      palletsEuro: r.vehicle?.palletsEuro ?? null,
      // Задача 037, п.7 / 038, п.8 — «Уже везёт: 8 т из 20 т · … · погрузка …».
      committedWeightKg: committedByDriver.get(r.arrival.driver.id)?.committedWeightKg ?? 0,
      activeDealsCount: committedByDriver.get(r.arrival.driver.id)?.activeDealsCount ?? 0,
      committedHasUnknownWeight: committedByDriver.get(r.arrival.driver.id)?.committedHasUnknownWeight ?? false,
      committedDestinationCountryId: committedByDriver.get(r.arrival.driver.id)?.committedDestinationCountryId ?? null,
      committedDestinationCityId: committedByDriver.get(r.arrival.driver.id)?.committedDestinationCityId ?? null,
      committedReadyDate: committedByDriver.get(r.arrival.driver.id)?.committedReadyDate ?? null,
      // Задача 038, п.15 — «отменил 1 из 15 сделок» прямо в карточке.
      dealsTotal: dealsTotalMap.get(r.arrival.driver.id) ?? 0,
      dealsCancelledByDriver: dealsCancelledMap.get(r.arrival.driver.id) ?? 0,
      anyCountry: r.arrival.anyCountry,
      directionCountryIds: r.arrival.directions.map((d) => d.countryId),
    }));
  }

  /// Полоса дней у логиста (п. 9-10) — число водителей по каждому из
  /// ближайших `days` дней, начиная с сегодня.
  async summary(days: number, pointId?: string, from?: string) {
    await this.expireStale();

    const today = from ?? toDateOnly(new Date());
    const arrivals = await this.prisma.arrival.findMany({
      where: { status: { in: ['PLANNED', 'ON_SITE'] }, pointId },
      select: { plannedDay: true, status: true },
    });

    const result: { date: string; count: number }[] = [];
    for (let i = 0; i < days; i++) {
      const date = addDaysDateOnly(today, i);
      const isToday = i === 0;
      // ON_SITE считается только в сегодняшний день, даже если plannedAt
      // (когда собирались приехать) приходится на другую дату — водитель
      // физически уже на месте сейчас, а не "планируется" на будущий день.
      const count = arrivals.filter((a) =>
        isToday ? a.status === 'ON_SITE' || toDateOnly(a.plannedDay) === date : a.status === 'PLANNED' && toDateOnly(a.plannedDay) === date,
      ).length;
      result.push({ date, count });
    }
    return result;
  }
}
