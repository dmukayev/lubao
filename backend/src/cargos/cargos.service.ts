import { PricingService } from '../pricing/pricing.service';
import { cancelStatsFor } from '../deals/cancel-policy';
import { BadRequestException, ConflictException, Optional, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { BodyTypeProfile, Cargo, CargoStatus, Company, PaymentForm, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FeedQuery, FeedSort } from './feed-query';
import { ResponsesService } from '../responses/responses.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { CloseCargoDto } from './dto/close-cargo.dto';
import { localDateOnly, parseDateOnly, toDateOnly } from '../common/date-only';
import { haversineKm } from '../common/geo';
import { CARGO_ARCHIVE_AFTER_MS } from './cargo-lifecycle';
import { evaluateVehicleLoad } from '../deals/vehicle-load';
import { partialLoadsEnabled } from '../app-settings/partial-loads';
import { ContactPolicyService } from '../contact-events/contact-policy.service';
import { RequestContext } from '../common/request-context';
import { validateSpecs } from '../body-types/specs';
import { DriverBody, cargoFitsBody } from '../body-types/profile-fit';
import { newResponsesByCargo } from '../responses/new-responses';

/// 056 п.2: вкладки «Грузов» логиста по статусу груза. Доставленный груз
/// архивируется (deals.service: DELIVERED → ARCHIVED), сделка в работе — IN_DEAL.
export type CompanyCargoTab = 'active' | 'work' | 'archive';
export const COMPANY_TAB_STATUSES: Record<CompanyCargoTab, CargoStatus[]> = {
  active: ['PUBLISHED'],
  work: ['IN_DEAL'],
  archive: ['ARCHIVED', 'EXPIRED', 'CANCELLED'],
};

/// Лента: «рядом» с городом водителя — та же область либо ≤200 км (040, п.5).
export const NEARBY_KM = 200;
const FEED_DEFAULT_LIMIT = 30;
/// ≤ 50 на страницу (043 п.11, защита от парсинга): всю ленту одним запросом не выгрузить.
const FEED_MAX_LIMIT = 50;

type GeoCity = { id: string; regionId: string | null; lat: unknown; lng: unknown };
type GeoPoint = { cityId: string; lat: unknown; lng: unknown; city: GeoCity };
export type FeedOrigin = { cityId: string; regionId: string | null; lat: number | null; lng: number | null };

type CargoWithCompany = Cargo & { company: Company & { country: { code: string } }; publishedBy?: { id: string; name: string | null; phone: string | null; lastSeenAt?: Date | null } | null };

interface CargoContact {
  id: string;
  name: string | null;
  phone: string | null;
  wechatId: string | null;
  lastSeenAt?: Date | null;
}

/// 058 п.1: условия оплаты из формы. `undefined` — поле не трогаем (правка),
/// `null` — убрать. Аванс не больше цены груза (в той же валюте).
function paymentTerms(
  dto: { advanceAmount?: number | null; paymentForm?: PaymentForm | null; paymentDelayDays?: number | null },
  price: number,
  currentAdvance: number | null = null,
) {
  const advance = dto.advanceAmount === undefined ? currentAdvance : dto.advanceAmount;
  if (advance != null && advance > price) {
    throw new BadRequestException({ code: 'VALIDATION_FAILED', message: ['advanceAmount must not be greater than price'], fields: [{ field: 'advanceAmount', rule: 'max', limit: price }] });
  }
  return {
    advanceAmount: dto.advanceAmount === undefined ? undefined : dto.advanceAmount && dto.advanceAmount > 0 ? dto.advanceAmount : null,
    paymentForm: dto.paymentForm,
    paymentDelayDays: dto.paymentDelayDays === undefined ? undefined : dto.paymentDelayDays || null,
  };
}

@Injectable()
export class CargosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly responses: ResponsesService,
    private readonly contactPolicy: ContactPolicyService,
    @Optional() private readonly pricing?: PricingService,
    @Optional() private readonly redis?: RedisService,
  ) {}

  private readonly logger = new Logger(CargosService.name);

  /// Публикация не ждёт расстояние дольше этого: холодный OSRM на новую пару
  /// городов отвечает до ~30 с, а приложение ждёт ответ 20 с — логист видел
  /// ошибку, жал «Опубликовать» ещё раз, и появлялся второй такой же груз.
  static PRICING_INLINE_MS = 3000;

  private async applyPricingBounded(cargoId: string, listed: boolean) {
    const work = this.applyPricing(cargoId, listed).catch((e) => this.logger.warn(`Расстояние для груза ${cargoId}: ${(e as Error).message}`));
    let timer: NodeJS.Timeout | undefined;
    await Promise.race([work, new Promise<void>((resolve) => (timer = setTimeout(resolve, CargosService.PRICING_INLINE_MS)))]);
    clearTimeout(timer);
  }

  /// Повтор той же формы (ключ `Idempotency-Key`, 10 мин) — тот же груз, а не второй.
  private static readonly IDEMPOTENCY_TTL_S = 600;

  async createIdempotent(companyId: string, userId: string, companyIsVerified: boolean, dto: CreateCargoDto, key?: string) {
    if (!key || !this.redis || !/^[A-Za-z0-9_-]{8,64}$/.test(key)) return this.create(companyId, userId, companyIsVerified, dto);
    const redisKey = `cargo-create:${userId}:${key}`;
    const claimed = await this.redis.client.set(redisKey, 'pending', 'EX', CargosService.IDEMPOTENCY_TTL_S, 'NX');
    if (!claimed) {
      // Первый запрос ещё идёт или уже создал груз — ждём его результат.
      for (let i = 0; i < 50; i++) {
        const value = await this.redis.client.get(redisKey);
        if (value && value !== 'pending') return this.toDto(await this.findEntity(value));
        if (!value) break;
        await new Promise((r) => setTimeout(r, 300));
      }
      throw new ConflictException({ code: 'CARGO_CREATE_IN_PROGRESS', message: 'The same cargo is being published' });
    }
    try {
      const cargo = await this.create(companyId, userId, companyIsVerified, dto);
      await this.redis.client.set(redisKey, cargo.id, 'EX', CargosService.IDEMPOTENCY_TTL_S);
      return cargo;
    } catch (e) {
      await this.redis.client.del(redisKey);
      throw e;
    }
  }

  /// 049 п.1: флаг догруза — читается часто (каждая карточка), кэш на 5 с.
  private partialFlag: { value: boolean; at: number } | null = null;
  private async partialEnabled(): Promise<boolean> {
    if (this.partialFlag && Date.now() - this.partialFlag.at < 5000) return this.partialFlag.value;
    const value = await partialLoadsEnabled(this.prisma);
    this.partialFlag = { value, at: Date.now() };
    return value;
  }

  /// 047 п.1: категория — активная запись справочника.
  private async assertCategory(categoryId: string | undefined) {
    if (!categoryId) throw new BadRequestException('CATEGORY_REQUIRED');
    const category = await this.prisma.cargoCategory.findUnique({ where: { id: categoryId }, select: { isActive: true } });
    if (!category?.isActive) throw new BadRequestException('CATEGORY_REQUIRED');
  }

  /// 047 п.2–4: расстояние и ₸/км по городам груза; при публикации — точка статистики.
  private async applyPricing(cargoId: string, listed: boolean) {
    if (!this.pricing) return;
    const cargo = await this.prisma.cargo.findUnique({
      where: { id: cargoId },
      include: { point: { select: { cityId: true } }, destinationCountry: { select: { code: true } } },
    });
    if (!cargo) return;
    const { distanceKm, pricePerKm } = await this.pricing.distanceFor(cargo);
    await this.prisma.cargo.update({ where: { id: cargoId }, data: { distanceKm, pricePerKm } });
    // 049 п.11: при публикации — новая точка, при правке цены/маршрута — та же обновляется.
    if (listed) await this.pricing.recordPoint('LISTED', { ...cargo, distanceKm });
    else await this.pricing.upsertListedPoint({ ...cargo, distanceKm });
  }

  /// Водитель звонит/пишет конкретному логисту, опубликовавшему груз, а не
  /// «компании» (decisions.md «Компания: проверка, роли, контакты», задача
  /// 012) — своё имя/телефон/WeChat у каждого сотрудника (CompanyMember.
  /// fullName/contactPhone/wechatId), не общий телефон компании. У грузов
  /// до задачи 017 нет `publishedByUserId` — откатываемся на владельца
  /// компании (самый старый `OWNER`). Пока сотрудник не заполнил «Мой
  /// профиль» — показываем то, что есть (User.name/phone), а не пусто.
  private async resolveContact(cargo: CargoWithCompany): Promise<CargoContact | null> {
    if (cargo.publishedBy) {
      const member = await this.prisma.companyMember.findFirst({ where: { userId: cargo.publishedBy.id } });
      return {
        id: cargo.publishedBy.id,
        name: member?.fullName ?? cargo.publishedBy.name,
        phone: member?.contactPhone ?? cargo.publishedBy.phone,
        wechatId: member?.wechatId ?? null,
        lastSeenAt: cargo.publishedBy.lastSeenAt ?? null,
      };
    }
    const owner = await this.prisma.companyMember.findFirst({
      where: { companyId: cargo.companyId, role: 'OWNER' },
      orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, phone: true, lastSeenAt: true } } },
    });
    if (!owner) return null;
    return {
      id: owner.user.id,
      name: owner.fullName ?? owner.user.name,
      phone: owner.contactPhone ?? owner.user.phone,
      wechatId: owner.wechatId,
      lastSeenAt: owner.user.lastSeenAt ?? null,
    };
  }

  async toDto(cargo: CargoWithCompany) {
    const companyCompletedDeals = await this.prisma.deal.count({
      where: { companyId: cargo.companyId, status: 'DELIVERED' },
    });
    const contact = await this.resolveContact(cargo);
    // 046 п.3: отмены компании — водителю в карточке груза.
    const companyCancelStats = (await cancelStatsFor(this.prisma, 'COMPANY', [cargo.companyId])).get(cargo.companyId) ?? null;

    return {
      id: cargo.id,
      companyId: cargo.companyId,
      companyName: cargo.company.name,
      companyIsVerified: cargo.company.isVerified,
      companyRatingAvg: Number(cargo.company.ratingAvg),
      companyRatingCount: cargo.company.ratingCount,
      companyCompletedDeals,
      companyCancelStats,
      contactUserId: contact?.id ?? null,
      contactName: contact?.name ?? null,
      // Номер не отдаётся в списках и карточке (043 п.11) — только по нажатию
      // через POST /cargos/:id/contact; здесь — есть ли он вообще.
      hasContactPhone: !!contact?.phone,
      contactWechatId: contact?.wechatId ?? null,
      // 058 п.7: логист «в сети / был в сети».
      contactLastSeenAt: contact?.lastSeenAt ?? null,
      // WhatsApp заблокирован в Китае — водителю показываем чат Lubao
      // вместо кнопки, которая всё равно не дойдёт до логиста (decisions.md
      // «Звонки — обычные, через телефон», 2026-10-05).
      isWhatsappBlocked: cargo.company.country.code === 'CN',
      pointId: cargo.pointId,
      destinationCountryId: cargo.destinationCountryId,
      destinationCityId: cargo.destinationCityId,
      bodyTypeId: cargo.bodyTypeId,
      // 047: категория, расстояние по дороге и цена за км (в валюте груза).
      categoryId: cargo.categoryId,
      distanceKm: cargo.distanceKm ?? null,
      pricePerKm: cargo.pricePerKm != null ? Number(cargo.pricePerKm) : null,
      extraBodyTypeIds: cargo.extraBodyTypeIds ?? [],
      specs: cargo.specs ?? null,
      weightKg: cargo.weightKg ? Number(cargo.weightKg) : null,
      volumeM3: cargo.volumeM3 ? Number(cargo.volumeM3) : null,
      palletCount: cargo.palletCount ?? null,
      photoUrls: cargo.photoUrls,
      price: Number(cargo.price),
      currency: cargo.currency,
      // 058 п.1: условия оплаты; 8а — метка типа компании.
      advanceAmount: cargo.advanceAmount != null ? Number(cargo.advanceAmount) : null,
      paymentForm: cargo.paymentForm ?? null,
      paymentDelayDays: cargo.paymentDelayDays ?? null,
      companyKind: cargo.company.kind,
      // 058 п.2: «нужно 3 · осталось 2».
      trucksNeeded: cargo.trucksNeeded,
      trucksTaken: cargo.trucksNeeded > 1 ? await this.prisma.deal.count({ where: { cargoId: cargo.id, status: { not: 'CANCELLED' } } }) : undefined,
      readyDate: toDateOnly(cargo.readyDate),
      // 049 п.1: догруз выключен — бейджа нет, даже если груз помечен раньше.
      allowPartial: cargo.allowPartial && (await this.partialEnabled()),
      description: cargo.description,
      status: cargo.status,
      publishedAt: cargo.publishedAt,
      expiresAt: cargo.expiresAt,
      closeOutcome: cargo.closeOutcome,
      closedAt: cargo.closedAt,
    };
  }

  /// «Позвонить»/WhatsApp водителя (043 п.11): правила и лимит — в
  /// ContactPolicyService, номер — того логиста, что опубликовал груз.
  async revealContact(ctx: RequestContext, cargoId: string, type: 'CALL' | 'WHATSAPP') {
    if (!ctx.driver) throw new ForbiddenException('Only drivers call cargo contacts');
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, include: this.includeForDto });
    if (!cargo) throw new NotFoundException('Cargo not found');
    await this.contactPolicy.assertDriverMayContactCargo(ctx.driver, cargoId);
    const contact = await this.resolveContact(cargo);
    if (!contact?.phone) throw new NotFoundException({ code: 'NO_PHONE', message: 'Cargo contact has no phone' });
    await this.contactPolicy.consume(ctx.user.id, `cargo:${cargoId}`);
    await this.contactPolicy.record({ actorUserId: ctx.user.id, driverId: ctx.driver.id, companyId: cargo.companyId, cargoId, type });
    return { phone: contact.phone };
  }

  private get includeForDto() {
    return { company: { include: { country: { select: { code: true } } } }, publishedBy: { select: { id: true, name: true, phone: true, lastSeenAt: true } } } as const;
  }

  /// Кузов связки водителя для отсева грузов (задача 033, п.8) — прицеп
  /// (или одиночка-RIGID) активного анонса; без анонса — первый из гаража.
  private async driverCargoBody(driverId: string): Promise<DriverBody | null> {
    const arrival = await this.prisma.arrival.findFirst({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: { createdAt: 'desc' },
      include: { trailer: { include: { bodyType: { select: { profile: true } } } }, tractor: { include: { bodyType: { select: { profile: true } } } } },
    });
    const fromArrival = arrival?.trailer ?? (arrival?.tractor?.kind === 'RIGID' ? arrival.tractor : null);
    const vehicle =
      fromArrival ??
      (await this.prisma.vehicle.findFirst({
        where: { driverId, kind: { in: ['TRAILER', 'RIGID'] }, isArchived: false },
        // TRAILER раньше RIGID («kind: desc» — 'TRAILER' > 'RIGID' по алфавиту).
        orderBy: [{ kind: 'desc' }, { createdAt: 'asc' }],
        include: { bodyType: { select: { profile: true } } },
      }));
    if (!vehicle) {
      // 045 п.5 / 048 п.7: машины ещё нет — кузов, тоннаж и «основа» из регистрации.
      const driver = await this.prisma.driver.findUnique({
        where: { id: driverId },
        select: { preferredCapacityTons: true, preferredSpecs: true, preferredBodyType: { select: { profile: true } } },
      });
      if (!driver || (driver.preferredCapacityTons == null && !driver.preferredBodyType)) return null;
      return {
        profile: driver.preferredBodyType?.profile ?? null,
        capacityTons: driver.preferredCapacityTons != null ? Number(driver.preferredCapacityTons) : null,
        volumeM3: null,
        palletsEuro: null,
        specs: (driver.preferredSpecs as Record<string, unknown> | null) ?? null,
      };
    }
    return {
      profile: vehicle.bodyType?.profile ?? null,
      capacityTons: vehicle.capacityTons != null ? Number(vehicle.capacityTons) : null,
      volumeM3: vehicle.volumeM3 != null ? Number(vehicle.volumeM3) : null,
      palletsEuro: vehicle.palletsEuro ?? null,
      specs: (vehicle.specs as Record<string, unknown> | null) ?? null,
    };
  }

  /// Профили, под которые подходит груз (основной кузов + другие подходящие), 048.
  private static cargoProfiles(cargo: { bodyTypeId: string; extraBodyTypeIds?: string[] }, profileOf: Map<string, BodyTypeProfile>): BodyTypeProfile[] {
    return [...new Set([cargo.bodyTypeId, ...(cargo.extraBodyTypeIds ?? [])].map((id) => profileOf.get(id)).filter((p): p is BodyTypeProfile => !!p))];
  }

  private async bodyProfiles(): Promise<Map<string, BodyTypeProfile>> {
    const rows = await this.prisma.bodyType.findMany({ select: { id: true, profile: true } });
    return new Map(rows.map((r) => [r.id, r.profile]));
  }

  private static num(v: unknown): number | null {
    return v == null ? null : Number(v);
  }

  /// 0 — груз грузится в городе водителя; 1 — в той же области или ≤200 км;
  /// 2 — остальные (задача 040, п.5).
  static pickupRank(point: GeoPoint, origin: FeedOrigin): 0 | 1 | 2 {
    if (point.cityId === origin.cityId) return 0;
    if (origin.regionId && point.city.regionId === origin.regionId) return 1;
    const lat = CargosService.num(point.lat) ?? CargosService.num(point.city.lat);
    const lng = CargosService.num(point.lng) ?? CargosService.num(point.city.lng);
    if (origin.lat != null && origin.lng != null && lat != null && lng != null) {
      if (haversineKm({ lat: origin.lat, lng: origin.lng }, { lat, lng }) <= NEARBY_KM) return 1;
    }
    return 2;
  }

  /// Откуда водитель смотрит на ленту: город его анонса (на месте, иначе
  /// ближайший запланированный), фолбэк — домашний город (040, п.5).
  private async feedOrigin(driverId: string) {
    const arrivals = await this.prisma.arrival.findMany({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      include: { point: { include: { city: true } } },
      orderBy: { plannedDay: 'asc' },
    });
    const arrival = arrivals.find((a) => a.status === 'ON_SITE') ?? arrivals[0];
    if (arrival) {
      const { point } = arrival;
      const origin: FeedOrigin = {
        cityId: point.cityId,
        regionId: point.city.regionId,
        lat: CargosService.num(point.lat) ?? CargosService.num(point.city.lat),
        lng: CargosService.num(point.lng) ?? CargosService.num(point.city.lng),
      };
      return { origin, source: 'arrival' as const };
    }
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, include: { homeCity: true } });
    if (!driver?.homeCity) return { origin: null, source: null };
    const c = driver.homeCity;
    return {
      origin: { cityId: c.id, regionId: c.regionId, lat: CargosService.num(c.lat), lng: CargosService.num(c.lng) } as FeedOrigin,
      source: 'home' as const,
    };
  }

  /// Лента водителя — отсев и порядок на сервере (задача 040, п.5): город
  /// погрузки = город анонса → та же область / ≤200 км → остальные; внутри
  /// — «домой» → выбранные страны → остальные, затем по дате готовности.
  /// Страница `limit/offset`; весь отсортированный набор считается в памяти
  /// (на старте — сотни грузов), `total` нужен клиенту для «показать ещё».
  async feed(driverId?: string, query: FeedQuery = {}) {
    const limit = Math.min(Math.max(query.limit ?? FEED_DEFAULT_LIMIT, 0), FEED_MAX_LIMIT);
    const offset = Math.max(query.offset ?? 0, 0);

    // 059 п.4: в базе — простые фильтры, наружу — лёгкие строки (без связей
    // компании и т.п.); полные карточки — только для страницы.
    // company.isBlocked (задача 026, п.5) — груз блокированной компании
    // скрываем из ленты, пока компанию не разблокируют.
    const where: Prisma.CargoWhereInput = { status: 'PUBLISHED', company: { isBlocked: false } };
    const and: Prisma.CargoWhereInput[] = [];
    if (query.fromCityId) and.push({ point: { cityId: query.fromCityId } });
    else if (query.fromCountryId) and.push({ point: { city: { countryId: query.fromCountryId } } });
    if (query.weightMinT != null) and.push({ weightKg: { gte: query.weightMinT * 1000 } });
    if (query.weightMaxT != null) and.push({ weightKg: { lte: query.weightMaxT * 1000 } });
    if (query.withAdvance) and.push({ advanceAmount: { gt: 0 } });
    if (query.ready && query.ready !== 'any') {
      const days = { today: 0, '3d': 3, week: 7 }[query.ready];
      const limitDay = parseDateOnly(localDateOnly(new Date(Date.now() + days * 86_400_000)));
      and.push({ readyDate: { lte: limitDay } });
    }
    if (query.bodyTypeIds?.length) and.push({ OR: [{ bodyTypeId: { in: query.bodyTypeIds } }, { extraBodyTypeIds: { hasSome: query.bodyTypeIds } }] });
    if (and.length) where.AND = and;

    const rows = await this.prisma.cargo.findMany({
      where,
      select: {
        id: true, pointId: true, destinationCountryId: true, destinationCityId: true, bodyTypeId: true, extraBodyTypeIds: true,
        weightKg: true, volumeM3: true, palletCount: true, specs: true, price: true, currency: true, readyDate: true,
        distanceKm: true, pricePerKm: true, publishedAt: true,
        point: { select: { cityId: true, lat: true, lng: true, city: { select: { id: true, regionId: true, lat: true, lng: true } } } },
        destinationCity: { select: { regionId: true } },
      },
      orderBy: { readyDate: 'asc' },
    });

    // Цена и ₸/км — в тенге по курсу НБ РК (058 п.4: и RUB, UZS).
    const rate = await this.kztRates();
    const kzt = (amount: number | null, currency: string) => (amount == null || rate[currency] == null ? null : amount * rate[currency]!);
    const priceFloor = query.priceMin != null ? kzt(query.priceMin, query.priceCurrency ?? 'KZT') : null;
    const priceCeil = query.priceMax != null ? kzt(query.priceMax, query.priceCurrency ?? 'KZT') : null;

    const body = driverId && !query.bodyTypeIds?.length ? await this.driverCargoBody(driverId) : null;
    const profileOf = body ? await this.bodyProfiles() : new Map<string, BodyTypeProfile>();

    const enriched = rows
      .map((c) => {
        const priceKzt = kzt(Number(c.price), c.currency);
        const perKmKzt = c.pricePerKm != null ? kzt(Number(c.pricePerKm), c.currency) : null;
        return { c, priceKzt, perKmKzt };
      })
      .filter(({ c, priceKzt, perKmKzt }) => {
        if (priceFloor != null && (priceKzt == null || priceKzt < priceFloor)) return false;
        if (priceCeil != null && (priceKzt == null || priceKzt > priceCeil)) return false;
        if (query.perKmMin != null && (perKmKzt == null || perKmKzt < query.perKmMin)) return false;
        // 048 п.5: отсев по профилю кузова моей машины (если кузова не выбраны в фильтре).
        if (body && !cargoFitsBody({ profiles: CargosService.cargoProfiles(c, profileOf), weightKg: c.weightKg, volumeM3: c.volumeM3, palletCount: c.palletCount, specs: c.specs as Record<string, unknown> | null }, body)) return false;
        return true;
      });

    const [{ origin: statusOrigin, source }, driver] = driverId
      ? await Promise.all([
          this.feedOrigin(driverId),
          this.prisma.driver.findUnique({ where: { id: driverId }, include: { homeCity: true, directions: true } }),
        ])
      : [{ origin: null, source: null }, null];
    // 059 п.5: выбран другой город «откуда» — он и есть город погрузки.
    let origin = statusOrigin;
    if (query.fromCityId) {
      const city = await this.prisma.city.findUnique({ where: { id: query.fromCityId } });
      if (city) origin = { cityId: city.id, regionId: city.regionId, lat: CargosService.num(city.lat), lng: CargosService.num(city.lng) };
    }
    const homeCountryId = driver?.homeCity?.countryId ?? null;
    const selected = new Set(driver?.directions?.map((d) => d.countryId) ?? []);
    // 045 п.7: страна с уточнёнными областями — груз «в выбранное», только если
    // город назначения в одной из них (груз без города — по стране).
    const regionsByCountry = new Map((driver?.directions ?? []).filter((d) => (d.regionIds?.length ?? 0) > 0).map((d) => [d.countryId, new Set(d.regionIds)]));
    const inSelected = (cargo: { destinationCountryId: string; destinationCity: { regionId: string | null } | null }) => {
      if (!selected.has(cargo.destinationCountryId)) return false;
      const regions = regionsByCountry.get(cargo.destinationCountryId);
      if (!regions || !cargo.destinationCity?.regionId) return true;
      return regions.has(cargo.destinationCity.regionId);
    };
    // 049 п.8 (CLAUDE.md): «домой» — город назначения в той же области, что и
    // домашний город; у домашнего города без области — по стране.
    const homeRegionId = driver?.homeCity?.regionId ?? null;
    const isHome = (cargo: { destinationCountryId: string; destinationCity: { regionId: string | null } | null }) => {
      if (!homeCountryId || cargo.destinationCountryId !== homeCountryId) return false;
      if (!homeRegionId) return true;
      return cargo.destinationCity?.regionId === homeRegionId;
    };

    const ranked = enriched.map((e) => {
      const pickupRank = origin ? CargosService.pickupRank(e.c.point, origin) : 2;
      const home = isHome(e.c);
      const section: 'home' | 'selected' | 'other' = home ? 'home' : (driver?.anyCountry ?? true) || inSelected(e.c) ? 'selected' : 'other';
      return { ...e, pickupRank, section, home };
    });

    // 059 п.5: «Грузы из других городов» — свёрнуты, если город погрузки известен.
    const collapse = !!origin && !query.showOtherCities;
    const nearby = collapse ? ranked.filter((r) => r.pickupRank < 2) : ranked;
    const otherCitiesCount = collapse ? ranked.length - nearby.length : 0;

    // 059 п.1: чипы «куда» — из реальных грузов выборки (без фильтра «куда»).
    const byCountry = new Map<string, number>();
    const byCity = new Map<string, number>();
    let homeCount = 0;
    for (const r of nearby) {
      byCountry.set(r.c.destinationCountryId, (byCountry.get(r.c.destinationCountryId) ?? 0) + 1);
      if (r.c.destinationCityId) byCity.set(r.c.destinationCityId, (byCity.get(r.c.destinationCityId) ?? 0) + 1);
      if (r.home) homeCount++;
    }
    const top = (m: Map<string, number>, n: number) => [...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, n).map(([id, count]) => ({ id, count }));
    const chips = {
      all: nearby.length,
      home: homeCount,
      countries: top(byCountry, 6),
      cities: top(byCity, 4),
    };

    const matched = nearby.filter((r) => {
      if (query.toHome && !r.home) return false;
      if (query.toCityId) return r.c.destinationCityId === query.toCityId;
      if (query.toCountryId) return r.c.destinationCountryId === query.toCountryId;
      return true;
    });

    // 059 п.3: сортировка; по умолчанию — как раньше (город погрузки → домой → выбранные → дата).
    const sectionOrder = { home: 0, selected: 1, other: 2 } as const;
    const nullsLast = (a: number | null, b: number | null, dir: 1 | -1) => (a == null ? (b == null ? 0 : 1) : b == null ? -1 : (a - b) * dir);
    const byDate = (a: (typeof matched)[number], b: (typeof matched)[number]) => a.c.readyDate.getTime() - b.c.readyDate.getTime();
    const sorters: Record<FeedSort, (a: (typeof matched)[number], b: (typeof matched)[number]) => number> = {
      default: (a, b) => a.pickupRank - b.pickupRank || sectionOrder[a.section] - sectionOrder[b.section] || byDate(a, b),
      price_asc: (a, b) => nullsLast(a.priceKzt, b.priceKzt, 1) || byDate(a, b),
      price_desc: (a, b) => nullsLast(a.priceKzt, b.priceKzt, -1) || byDate(a, b),
      per_km: (a, b) => nullsLast(a.perKmKzt, b.perKmKzt, -1) || byDate(a, b),
      ready: (a, b) => byDate(a, b) || a.pickupRank - b.pickupRank,
      distance_asc: (a, b) => nullsLast(a.c.distanceKm, b.c.distanceKm, 1) || byDate(a, b),
      distance_desc: (a, b) => nullsLast(a.c.distanceKm, b.c.distanceKm, -1) || byDate(a, b),
      new: (a, b) => b.c.publishedAt.getTime() - a.c.publishedAt.getTime(),
    };
    matched.sort(sorters[query.sort ?? 'default']);

    const meta = { total: matched.length, offset, limit, originCityId: origin?.cityId ?? null, originSource: query.fromCityId ? ('filter' as const) : source, chips, otherCitiesCount };
    const pageRanked = limit === 0 ? [] : matched.slice(offset, offset + limit);
    if (pageRanked.length === 0) return { items: [], ...meta };

    // Полные карточки — только для страницы.
    const pageIds = pageRanked.map((r) => r.c.id);
    const full = new Map((await this.prisma.cargo.findMany({ where: { id: { in: pageIds } }, include: this.includeForDto })).map((c) => [c.id, c]));
    // 045 п.2: состояние груза для ЭТОГО водителя (вместо «Опубликован») и
    // сколько других водителей уже откликнулись — два запроса на страницу.
    const [mine, others] = driverId
      ? await Promise.all([
          this.prisma.response.findMany({ where: { cargoId: { in: pageIds }, driverId }, select: { cargoId: true, status: true } }),
          this.prisma.response.groupBy({
            by: ['cargoId'],
            where: { cargoId: { in: pageIds }, driverId: { not: driverId }, status: { in: ['PENDING', 'SELECTED'] } },
            _count: { _all: true },
          }),
        ])
      : [[], []];
    const myStatus = new Map(mine.map((r) => [r.cargoId, r.status]));
    const othersCount = new Map(others.map((g) => [g.cargoId, g._count._all]));
    const items = (
      await Promise.all(
        pageRanked.map(async ({ c, pickupRank, section }) => {
          const cargo = full.get(c.id);
          if (!cargo) return null;
          return {
            ...(await this.toDto(cargo)),
            pickupRank,
            feedSection: section,
            myResponseStatus: myStatus.get(c.id) ?? null,
            responsesCount: othersCount.get(c.id) ?? 0,
          };
        }),
      )
    ).filter((x): x is NonNullable<typeof x> => x != null);
    return { items, ...meta };
  }

  /// Курсы в ₸ (последний на валюту), ₸ = 1.
  private async kztRates(): Promise<Record<string, number | undefined>> {
    const rows = await this.prisma.exchangeRate.findMany({ orderBy: { effectiveDate: 'desc' } });
    const out: Record<string, number | undefined> = { KZT: 1 };
    for (const r of rows) if (out[r.currency] == null) out[r.currency] = Number(r.rateToKzt);
    return out;
  }

  /// «Помещается к текущему: 8 т + 10 т из 20 т» (задача 040, п.6) — для
  /// водителя с активной сделкой; расчёт тот же, что при подтверждении
  /// (`evaluateVehicleLoad`). Без активной сделки подсказки нет.
  async partialHint(driverId: string, cargoId: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');

    const lastDeal = await this.prisma.deal.findFirst({
      where: { driverId, status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'CANCEL_REQUESTED', 'DISPUTED'] } },
      orderBy: { createdAt: 'desc' },
    });
    if (!lastDeal) return { hint: null };
    // 049 п.1: догруз выключен — подсказки «помещается к текущему» нет.
    if (!(await this.partialEnabled())) return { hint: null };

    const load = await evaluateVehicleLoad(this.prisma, {
      driverId,
      tractorId: lastDeal.tractorId,
      trailerId: lastDeal.trailerId,
      cargo,
      partialLoadsEnabled: true,
    });
    if (load.verdict === 'NONE') return { hint: null };
    return {
      hint: {
        fits: load.verdict === 'OK',
        reason: load.verdict === 'OK' ? null : load.verdict,
        committedWeightKg: load.usedWeightKg,
        cargoWeightKg: cargo.weightKg != null ? Number(cargo.weightKg) : null,
        capacityKg: load.capacityKg,
      },
    };
  }

  async mine(companyId: string) {
    const cargos = await this.prisma.cargo.findMany({
      where: { companyId },
      include: this.includeForDto,
      orderBy: { createdAt: 'desc' },
    });
    return this.withActiveDeals(cargos);
  }

  /// 056 п.2: «Грузы» логиста по вкладкам — Активные (ищем водителя), В работе
  /// (сделка от «выбран» до «в пути»), Архив (доставлено, снят, истёк; поиск по
  /// городу и периоду). Страницами; числа на вкладках — одним запросом.
  async companyTab(
    companyId: string,
    params: { tab: CompanyCargoTab; limit?: number; offset?: number; cityId?: string; from?: string; to?: string; userId?: string },
  ) {
    const limit = Math.min(Math.max(params.limit ?? 20, 1), 50);
    const offset = Math.max(params.offset ?? 0, 0);
    const where: Prisma.CargoWhereInput = { companyId, status: { in: COMPANY_TAB_STATUSES[params.tab] } };
    if (params.tab === 'archive') {
      if (params.cityId) where.OR = [{ destinationCityId: params.cityId }, { point: { cityId: params.cityId } }];
      const range: Prisma.DateTimeFilter = {};
      if (params.from) range.gte = new Date(`${params.from}T00:00:00.000Z`);
      if (params.to) range.lte = new Date(`${params.to}T00:00:00.000Z`);
      if (range.gte || range.lte) where.readyDate = range;
    }

    let cargos: Array<Prisma.CargoGetPayload<{ include: CargosService['includeForDto'] }>>;
    let total: number;
    let newByCargo = new Map<string, number>();
    if (params.tab === 'active') {
      // 056 п.5: грузы с новыми откликами — наверху. Активных у компании
      // немного, поэтому порядок считаем по всем, а страницу режем после.
      const all = await this.prisma.cargo.findMany({ where, select: { id: true, createdAt: true }, orderBy: { createdAt: 'desc' } });
      newByCargo = params.userId ? await newResponsesByCargo(this.prisma, params.userId, all.map((c) => c.id)) : new Map();
      const ordered = [...all].sort((a, b) => {
        const na = (newByCargo.get(a.id) ?? 0) > 0 ? 1 : 0;
        const nb = (newByCargo.get(b.id) ?? 0) > 0 ? 1 : 0;
        return nb - na || b.createdAt.getTime() - a.createdAt.getTime();
      });
      total = ordered.length;
      const pageIds = ordered.slice(offset, offset + limit).map((c) => c.id);
      const rows = await this.prisma.cargo.findMany({ where: { id: { in: pageIds } }, include: this.includeForDto });
      const byId = new Map(rows.map((r) => [r.id, r]));
      cargos = pageIds.map((id) => byId.get(id)).filter((c): c is NonNullable<typeof c> => !!c);
    } else {
      [cargos, total] = await Promise.all([
        this.prisma.cargo.findMany({
          where,
          include: this.includeForDto,
          // Архив — свежие сверху по закрытию; «В работе» — по публикации.
          orderBy: params.tab === 'archive' ? [{ updatedAt: 'desc' }] : [{ createdAt: 'desc' }],
          take: limit,
          skip: offset,
        }),
        this.prisma.cargo.count({ where }),
      ]);
    }

    const ids = cargos.map((c) => c.id);
    const responseGroups = ids.length
      ? await this.prisma.response.groupBy({ by: ['cargoId'], where: { cargoId: { in: ids }, status: { in: ['PENDING', 'INVITED', 'SELECTED'] } }, _count: { _all: true } })
      : [];
    const responsesByCargo = new Map(responseGroups.map((g) => [g.cargoId, g._count._all]));
    const [items, counts] = await Promise.all([this.withActiveDeals(cargos), this.companyTabCounts(companyId, params.userId)]);
    return {
      items: items.map((c) => ({ ...c, responsesCount: responsesByCargo.get(c.id) ?? 0, newResponsesCount: newByCargo.get(c.id) ?? 0 })),
      total,
      limit,
      offset,
      counts,
    };
  }

  /// Числа на вкладках и (056 п.5) сколько новых откликов у этого сотрудника
  /// по активным грузам — цифра на вкладке «Грузы».
  async companyTabCounts(companyId: string, userId?: string): Promise<Record<CompanyCargoTab | 'newResponses', number>> {
    const groups = await this.prisma.cargo.groupBy({ by: ['status'], where: { companyId }, _count: { _all: true } });
    const byStatus = new Map(groups.map((g) => [g.status, g._count._all]));
    const sum = (tab: CompanyCargoTab) => COMPANY_TAB_STATUSES[tab].reduce((acc, st) => acc + (byStatus.get(st) ?? 0), 0);
    let newResponses = 0;
    if (userId) {
      const active = await this.prisma.cargo.findMany({ where: { companyId, status: 'PUBLISHED' }, select: { id: true } });
      const byCargo = await newResponsesByCargo(this.prisma, userId, active.map((c) => c.id));
      newResponses = [...byCargo.values()].reduce((a, b) => a + b, 0);
    }
    return { active: sum('active'), work: sum('work'), archive: sum('archive'), newResponses };
  }

  private async withActiveDeals(cargos: Array<Prisma.CargoGetPayload<{ include: CargosService['includeForDto'] }>>) {
    // 044 п.3: «Водитель: <имя> · подтвердил / ждём подтверждения» + «Документы» —
    // последняя неотменённая сделка по грузу, одним запросом.
    const deals = cargos.length
      ? await this.prisma.deal.findMany({
          where: { cargoId: { in: cargos.map((c) => c.id) }, status: { not: 'CANCELLED' } },
          orderBy: { createdAt: 'desc' },
          select: { id: true, cargoId: true, status: true, driver: { select: { fullName: true } } },
        })
      : [];
    const dealByCargo = new Map<string, (typeof deals)[number]>();
    for (const d of deals) if (!dealByCargo.has(d.cargoId)) dealByCargo.set(d.cargoId, d);
    return Promise.all(
      cargos.map(async (c) => {
        const deal = dealByCargo.get(c.id);
        return {
          ...(await this.toDto(c)),
          activeDeal: deal ? { id: deal.id, status: deal.status, driverName: deal.driver.fullName } : null,
        };
      }),
    );
  }

  /// Задача 033, п.10 — подсказка при публикации: «подходит N водителям на
  /// точке». Простой счётчик по активным анонсам, те же правила отсева,
  /// что у ленты (cargoFitsBody).
  async fitCount(params: { weightKg?: number; volumeM3?: number; palletCount?: number; pointId?: string; bodyTypeIds?: string[]; specs?: Record<string, unknown> }) {
    const arrivals = await this.prisma.arrival.findMany({
      where: { status: { in: ['PLANNED', 'ON_SITE'] }, ...(params.pointId ? { pointId: params.pointId } : {}) },
      include: {
        trailer: { include: { bodyType: { select: { profile: true } } } },
        tractor: { include: { bodyType: { select: { profile: true } } } },
        driver: { select: { preferredCapacityTons: true, preferredSpecs: true, preferredBodyType: { select: { profile: true } } } },
      },
    });
    // 048 п.4: «Подходит N водителям» — по профилю выбранных кузовов груза.
    const profileOf = params.bodyTypeIds?.length ? await this.bodyProfiles() : new Map<string, BodyTypeProfile>();
    const cargo = {
      profiles: [...new Set((params.bodyTypeIds ?? []).map((id) => profileOf.get(id)).filter((p): p is BodyTypeProfile => !!p))],
      weightKg: params.weightKg ?? null,
      volumeM3: params.volumeM3 ?? null,
      palletCount: params.palletCount ?? null,
      specs: params.specs ?? null,
    };
    const fittingDrivers = new Set<string>();
    for (const arrival of arrivals) {
      const vehicle = arrival.trailer ?? (arrival.tractor?.kind === 'RIGID' ? arrival.tractor : null);
      const d = arrival.driver;
      const body: DriverBody = vehicle
        ? {
            profile: vehicle.bodyType?.profile ?? null,
            capacityTons: vehicle.capacityTons != null ? Number(vehicle.capacityTons) : null,
            volumeM3: vehicle.volumeM3 != null ? Number(vehicle.volumeM3) : null,
            palletsEuro: vehicle.palletsEuro ?? null,
            specs: (vehicle.specs as Record<string, unknown> | null) ?? null,
          }
        : {
            profile: d.preferredBodyType?.profile ?? null,
            capacityTons: d.preferredCapacityTons != null ? Number(d.preferredCapacityTons) : null,
            volumeM3: null,
            palletsEuro: null,
            specs: (d.preferredSpecs as Record<string, unknown> | null) ?? null,
          };
      if (cargoFitsBody(cargo, body)) fittingDrivers.add(arrival.driverId);
    }
    return { count: fittingDrivers.size };
  }

  /// 052: «Все грузы компании» по ссылке /co — опубликованные грузы компании.
  async publishedByCompany(companyId: string) {
    const cargos = await this.prisma.cargo.findMany({
      // 057 п.7: грузы заблокированной компании по ссылке не показываем.
      where: { companyId, status: 'PUBLISHED', company: { isBlocked: false } },
      include: this.includeForDto,
      orderBy: { readyDate: 'asc' },
      take: 50,
    });
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  async byId(id: string) {
    const cargo = await this.prisma.cargo.findUnique({
      where: { id },
      include: { ...this.includeForDto, point: { select: { cityId: true } }, destinationCountry: { select: { code: true } } },
    });
    if (!cargo) throw new NotFoundException('Cargo not found');
    // 047 п.6: «Рынок за месяц: 650–720 ₸/км» — только в карточке, не в ленте.
    const market = this.pricing
      ? await this.pricing.marketFor(cargo.point.cityId, cargo.destinationCityId, cargo.destinationCountry.code, cargo.weightKg == null ? null : Number(cargo.weightKg))
      : null;
    return { ...(await this.toDto(cargo)), market };
  }

  /// 047 п.7: подсказка логисту при публикации — медиана по маршруту.
  /// 058 п.8: ☆ груза водителем (повтор — без ошибки).
  async setFavorite(driverId: string, cargoId: string, on: boolean) {
    if (on) {
      const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, select: { id: true } });
      if (!cargo) throw new NotFoundException('Cargo not found');
      await this.prisma.cargoFavorite.upsert({ where: { driverId_cargoId: { driverId, cargoId } }, create: { driverId, cargoId }, update: {} });
    } else {
      await this.prisma.cargoFavorite.deleteMany({ where: { driverId, cargoId } });
    }
  }

  /// «Избранное» в «Моих рейсах» — пока груз опубликован; новые сверху.
  async listFavorites(driverId: string) {
    const rows = await this.prisma.cargoFavorite.findMany({
      where: { driverId, cargo: { status: 'PUBLISHED', company: { isBlocked: false } } },
      orderBy: { createdAt: 'desc' },
      include: { cargo: { include: this.includeForDto } },
    });
    return Promise.all(rows.map((r) => this.toDto(r.cargo)));
  }

  async marketHint(pointId: string, destinationCityId: string | undefined, destinationCountryId: string, weightKg: number | undefined) {
    if (!this.pricing || !destinationCityId) return { market: null, distanceKm: null };
    const [point, country] = await Promise.all([
      this.prisma.point.findUnique({ where: { id: pointId }, select: { cityId: true } }),
      this.prisma.country.findUnique({ where: { id: destinationCountryId }, select: { code: true } }),
    ]);
    if (!point || !country) return { market: null, distanceKm: null };
    // Пара городов выбрана — расстояние считается сразу (к публикации оно уже
    // в кэше). Новая пара на холодном OSRM — до ~30 с: ждём не дольше лимита,
    // расчёт идёт дальше, форма спросит ещё раз.
    const distance = this.pricing.distanceFor({ price: 0, destinationCityId, point }).then((d) => d.distanceKm).catch(() => null);
    let timer: NodeJS.Timeout | undefined;
    const distanceKm = await Promise.race([distance, new Promise<null>((resolve) => (timer = setTimeout(() => resolve(null), CargosService.HINT_DISTANCE_MS)))]);
    clearTimeout(timer);
    return { market: await this.pricing.marketFor(point.cityId, destinationCityId, country.code, weightKg ?? null), distanceKm };
  }

  static HINT_DISTANCE_MS = 12000;

  private async findEntity(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: this.includeForDto });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return cargo;
  }

  async create(companyId: string, userId: string, companyIsVerified: boolean, dto: CreateCargoDto) {
    // Задача 012, п.4 — непроверенная компания может смотреть водителей на
    // точке и писать им, но не публиковать грузы (decisions.md «Компания:
    // проверка, роли, контакты»).
    if (!companyIsVerified) throw new ForbiddenException('COMPANY_NOT_VERIFIED');

    // Город погрузки обязателен (задача 040, п.7).
    const point = await this.prisma.point.findUnique({ where: { id: dto.pointId } });
    if (!point || !point.isActive) throw new BadRequestException('POINT_REQUIRED');
    const readyDate = parseDateOnly(dto.readyDate);
    const expiresAt = new Date(readyDate.getTime() + CARGO_ARCHIVE_AFTER_MS);
    const bodyData = await this.cargoBodyData(dto.bodyTypeId, dto.specs, dto.extraBodyTypeIds);
    await this.assertCategory(dto.categoryId);

    const created = await this.prisma.cargo.create({
      data: {
        companyId,
        categoryId: dto.categoryId,
        publishedByUserId: userId,
        pointId: point.id,
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        palletCount: dto.palletCount,
        photoUrls: dto.photoUrls ?? [],
        price: dto.price,
        currency: dto.currency,
        ...paymentTerms(dto, dto.price),
        trucksNeeded: dto.trucksNeeded ?? 1,
        readyDate,
        // 049 п.1: при выключенном догрузе пометка игнорируется.
        allowPartial: (dto.allowPartial ?? false) && (await this.partialEnabled()),
        description: dto.description,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        expiresAt,
        ...bodyData,
      },
      select: { id: true },
    });
    // Публикует только проверенная компания (проверено выше) — точка LISTED.
    await this.applyPricingBounded(created.id, true);
    return this.toDto(await this.findEntity(created.id));
  }

  async assertOwnedBy(cargoId: string, companyId: string) {
    const cargo = await this.findEntity(cargoId);
    if (cargo.companyId !== companyId) {
      throw new NotFoundException('Cargo not found');
    }
    return cargo;
  }

  /// Задача 012, п.6 — логист видит все грузы компании (чтобы подменить
  /// коллегу), но редактирует/закрывает только свои; владелец — любые.
  /// decisions.md «Компания: проверка, роли, контакты».
  async assertCanEdit(cargoId: string, companyId: string, userId: string, role: string) {
    const cargo = await this.assertOwnedBy(cargoId, companyId);
    if (role !== 'OWNER' && cargo.publishedByUserId !== userId) {
      throw new ForbiddenException('Only the owner or the logist who published this cargo can edit it');
    }
    return cargo;
  }

  async update(companyId: string, userId: string, role: string, id: string, dto: UpdateCargoDto) {
    const existing = await this.assertCanEdit(id, companyId, userId, role);

    const readyDate = dto.readyDate ? parseDateOnly(dto.readyDate) : existing.readyDate;
    const expiresAt =
      dto.readyDate != null ? new Date(readyDate.getTime() + CARGO_ARCHIVE_AFTER_MS) : existing.expiresAt;

    if (dto.pointId) {
      const point = await this.prisma.point.findUnique({ where: { id: dto.pointId } });
      if (!point || !point.isActive) throw new BadRequestException('POINT_REQUIRED');
    }
    // 048: сменили кузов или параметры — заново по полям профиля.
    const bodyData =
      dto.bodyTypeId !== undefined || dto.specs !== undefined || dto.extraBodyTypeIds !== undefined
        ? await this.cargoBodyData(dto.bodyTypeId ?? existing.bodyTypeId, dto.specs ?? (existing.specs as Record<string, unknown> | null) ?? undefined, dto.extraBodyTypeIds ?? existing.extraBodyTypeIds)
        : {};

    if (dto.categoryId !== undefined) await this.assertCategory(dto.categoryId);
    // 058 п.2: машин не меньше, чем уже взято сделок.
    const taken = dto.trucksNeeded !== undefined ? await this.prisma.deal.count({ where: { cargoId: id, status: { not: 'CANCELLED' } } }) : 0;
    if (dto.trucksNeeded !== undefined && dto.trucksNeeded < taken) {
      throw new BadRequestException({ code: 'VALIDATION_FAILED', message: ['trucksNeeded must not be less than taken deals'], fields: [{ field: 'trucksNeeded', rule: 'min', limit: taken }] });
    }

    await this.prisma.cargo.update({
      where: { id },
      data: {
        categoryId: dto.categoryId,
        pointId: dto.pointId,
        allowPartial: dto.allowPartial === undefined ? undefined : dto.allowPartial && (await this.partialEnabled()),
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        palletCount: dto.palletCount,
        photoUrls: dto.photoUrls,
        price: dto.price,
        currency: dto.currency,
        ...paymentTerms(dto, dto.price ?? Number(existing.price), existing.advanceAmount != null ? Number(existing.advanceAmount) : null),
        trucksNeeded: dto.trucksNeeded,
        readyDate,
        expiresAt,
        description: dto.description,
        ...bodyData,
      },
    });
    // 058 п.2: набрали все места — «В работе» (ждущие отклики закрываются),
    // добавили машин — снова в поиске.
    if (dto.trucksNeeded !== undefined) {
      if (taken >= dto.trucksNeeded && existing.status === 'PUBLISHED') {
        await this.prisma.cargo.updateMany({ where: { id, status: 'PUBLISHED' }, data: { status: 'IN_DEAL' } });
        await this.responses.closeForCargo(id, 'TAKEN_BY_OTHER');
      } else if (taken < dto.trucksNeeded && existing.status === 'IN_DEAL') {
        await this.prisma.cargo.updateMany({ where: { id, status: 'IN_DEAL' }, data: { status: 'PUBLISHED' } });
      }
    }
    // Сменился маршрут или цена — заново км и ₸/км.
    if (dto.pointId !== undefined || dto.destinationCityId !== undefined || dto.price !== undefined) await this.applyPricingBounded(id, false);
    return this.toDto(await this.findEntity(id));
  }

  /// 048: specs груза по полям профиля основного кузова; другие подходящие
  /// кузова — только существующие и не повторяющие основной.
  private async cargoBodyData(bodyTypeId: string, specsInput: Record<string, unknown> | undefined, extraIds: string[] | undefined) {
    const bodyType = await this.prisma.bodyType.findUnique({ where: { id: bodyTypeId }, select: { fields: true } });
    if (!bodyType) throw new BadRequestException('BODY_TYPE_REQUIRED');
    const specs = validateSpecs(bodyType.fields, specsInput ?? {}, 'cargo');
    const wanted = [...new Set((extraIds ?? []).filter((id) => id !== bodyTypeId))];
    const extra = wanted.length ? await this.prisma.bodyType.findMany({ where: { id: { in: wanted }, isActive: true }, select: { id: true } }) : [];
    return { specs: Object.keys(specs).length ? specs : Prisma.JsonNull, extraBodyTypeIds: extra.map((b) => b.id) };
  }

  /// Кандидаты на «Нашёл в Lubao» (задача 017, п.6) — водители, с кем уже
  /// был хоть какой-то контакт по этому грузу: отклик, звонок/WhatsApp или
  /// переписка. Объединяем по `driverId`, помечаем источник для UI.
  async closeCandidates(companyId: string, cargoId: string) {
    await this.assertOwnedBy(cargoId, companyId);

    const [responses, contactEvents, chats] = await Promise.all([
      this.prisma.response.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
      this.prisma.contactEvent.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
      this.prisma.chat.findMany({ where: { cargoId }, select: { driverId: true, driver: { select: { fullName: true } } } }),
    ]);

    const byDriver = new Map<string, { driverId: string; driverName: string }>();
    for (const r of [...responses, ...contactEvents, ...chats]) {
      byDriver.set(r.driverId, { driverId: r.driverId, driverName: r.driver.fullName });
    }
    return [...byDriver.values()];
  }

  /// Закрыть груз только через выбор исхода (задача 017, п.6) — заменяет
  /// старое «удаление» без причины. «Нашёл в Lubao» выбирает водителя и
  /// создаёт сделку тем же путём, что и приглашение/выбор отклика
  /// (`ResponsesService`) — не дублируем логику транзакции.
  async closeCargo(companyId: string, userId: string, role: string, id: string, dto: CloseCargoDto) {
    const cargo = await this.assertCanEdit(id, companyId, userId, role);
    if (cargo.status !== 'PUBLISHED') throw new BadRequestException('This cargo is already closed');

    if (dto.outcome === 'FOUND_IN_APP') {
      if (!dto.driverId) throw new BadRequestException('driverId is required for outcome=FOUND_IN_APP');
      // Если ответ этого водителя уже SELECTED (сделку создали обычным путём
      // раньше, через отклик/приглашение) — сделка уже есть, повторный
      // inviteDriver только упадёт конфликтом. Закрываем груз без повтора.
      const existingResponse = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId: id, driverId: dto.driverId } } });
      if (existingResponse?.status !== 'SELECTED') {
        await this.responses.createDealDirect(id, dto.driverId, companyId);
      }
    }

    // 057 п.16: «Нашёл в Lubao» — у груза идущая сделка: он остаётся IN_DEAL («В
    // работе»), в архив уйдёт сам при доставке. Остальные исходы — снят.
    await this.prisma.cargo.update({
      where: { id },
      data: dto.outcome === 'FOUND_IN_APP' ? { closeOutcome: dto.outcome, closedAt: new Date() } : { status: 'CANCELLED', closeOutcome: dto.outcome, closedAt: new Date() },
    });
    // 056 п.1: отклики, что ещё ждали, закрываются с причиной «груз снят».
    await this.responses.closeForCargo(id);
  }
}
