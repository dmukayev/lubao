import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Cargo, Company } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ResponsesService } from '../responses/responses.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { CloseCargoDto } from './dto/close-cargo.dto';
import { parseDateOnly, toDateOnly } from '../common/date-only';
import { haversineKm } from '../common/geo';
import { CARGO_ARCHIVE_AFTER_MS } from './cargo-lifecycle';
import { evaluateVehicleLoad } from '../deals/vehicle-load';

/// Лента: «рядом» с городом водителя — та же область либо ≤200 км (040, п.5).
export const NEARBY_KM = 200;
const FEED_DEFAULT_LIMIT = 30;
const FEED_MAX_LIMIT = 100;

type GeoCity = { id: string; regionId: string | null; lat: unknown; lng: unknown };
type GeoPoint = { cityId: string; lat: unknown; lng: unknown; city: GeoCity };
export type FeedOrigin = { cityId: string; regionId: string | null; lat: number | null; lng: number | null };

type CargoWithCompany = Cargo & { company: Company & { country: { code: string } }; publishedBy?: { id: string; name: string | null; phone: string | null } | null };

interface CargoContact {
  id: string;
  name: string | null;
  phone: string | null;
  wechatId: string | null;
}

@Injectable()
export class CargosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly responses: ResponsesService,
  ) {}

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
      };
    }
    const owner = await this.prisma.companyMember.findFirst({
      where: { companyId: cargo.companyId, role: 'OWNER' },
      orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, phone: true } } },
    });
    if (!owner) return null;
    return {
      id: owner.user.id,
      name: owner.fullName ?? owner.user.name,
      phone: owner.contactPhone ?? owner.user.phone,
      wechatId: owner.wechatId,
    };
  }

  async toDto(cargo: CargoWithCompany) {
    const companyCompletedDeals = await this.prisma.deal.count({
      where: { companyId: cargo.companyId, status: 'DELIVERED' },
    });
    const contact = await this.resolveContact(cargo);

    return {
      id: cargo.id,
      companyId: cargo.companyId,
      companyName: cargo.company.name,
      companyIsVerified: cargo.company.isVerified,
      companyRatingAvg: Number(cargo.company.ratingAvg),
      companyRatingCount: cargo.company.ratingCount,
      companyCompletedDeals,
      contactUserId: contact?.id ?? null,
      contactName: contact?.name ?? null,
      contactPhone: contact?.phone ?? null,
      contactWechatId: contact?.wechatId ?? null,
      // WhatsApp заблокирован в Китае — водителю показываем чат Lubao
      // вместо кнопки, которая всё равно не дойдёт до логиста (decisions.md
      // «Звонки — обычные, через телефон», 2026-10-05).
      isWhatsappBlocked: cargo.company.country.code === 'CN',
      pointId: cargo.pointId,
      destinationCountryId: cargo.destinationCountryId,
      destinationCityId: cargo.destinationCityId,
      bodyTypeId: cargo.bodyTypeId,
      weightKg: cargo.weightKg ? Number(cargo.weightKg) : null,
      volumeM3: cargo.volumeM3 ? Number(cargo.volumeM3) : null,
      palletCount: cargo.palletCount ?? null,
      photoUrls: cargo.photoUrls,
      price: Number(cargo.price),
      currency: cargo.currency,
      readyDate: toDateOnly(cargo.readyDate),
      allowPartial: cargo.allowPartial,
      description: cargo.description,
      status: cargo.status,
      publishedAt: cargo.publishedAt,
      expiresAt: cargo.expiresAt,
      closeOutcome: cargo.closeOutcome,
      closedAt: cargo.closedAt,
    };
  }

  private get includeForDto() {
    return { company: { include: { country: { select: { code: true } } } }, publishedBy: { select: { id: true, name: true, phone: true } } } as const;
  }

  /// Кузов связки водителя для отсева грузов (задача 033, п.8) — прицеп
  /// (или одиночка-RIGID) активного анонса; без анонса — первый из гаража.
  private async driverCargoBody(driverId: string): Promise<{ capacityTons: number | null; volumeM3: number | null; palletsEuro: number | null } | null> {
    const arrival = await this.prisma.arrival.findFirst({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: { createdAt: 'desc' },
      include: { trailer: true, tractor: true },
    });
    const fromArrival = arrival?.trailer ?? (arrival?.tractor?.kind === 'RIGID' ? arrival.tractor : null);
    const vehicle =
      fromArrival ??
      (await this.prisma.vehicle.findFirst({
        where: { driverId, kind: { in: ['TRAILER', 'RIGID'] }, isArchived: false },
        // TRAILER раньше RIGID («kind: desc» — 'TRAILER' > 'RIGID' по алфавиту).
        orderBy: [{ kind: 'desc' }, { createdAt: 'asc' }],
      }));
    if (!vehicle) return null;
    return {
      capacityTons: vehicle.capacityTons != null ? Number(vehicle.capacityTons) : null,
      volumeM3: vehicle.volumeM3 != null ? Number(vehicle.volumeM3) : null,
      palletsEuro: vehicle.palletsEuro ?? null,
    };
  }

  /// Задача 033, п.8 — груз скрывается, только когда известно И ТО И
  /// ДРУГОЕ (параметр груза и параметр машины) и груз больше машины; у
  /// машины без размера отсекаем только по весу.
  static cargoFitsVehicle(
    cargo: { weightKg: unknown; volumeM3: unknown; palletCount: number | null },
    body: { capacityTons: number | null; volumeM3: number | null; palletsEuro: number | null },
  ): boolean {
    if (cargo.weightKg != null && body.capacityTons != null && Number(cargo.weightKg) > body.capacityTons * 1000) return false;
    if (cargo.volumeM3 != null && body.volumeM3 != null && Number(cargo.volumeM3) > body.volumeM3) return false;
    if (cargo.palletCount != null && body.palletsEuro != null && cargo.palletCount > body.palletsEuro) return false;
    return true;
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
  async feed(driverId?: string, page: { limit?: number; offset?: number } = {}) {
    const limit = Math.min(Math.max(page.limit ?? FEED_DEFAULT_LIMIT, 1), FEED_MAX_LIMIT);
    const offset = Math.max(page.offset ?? 0, 0);

    // company.isBlocked (задача 026, п.5) — груз блокированной компании не
    // трогаем (статус/история не меняются), просто скрываем из ленты
    // водителя, пока компанию не разблокируют.
    const cargos = await this.prisma.cargo.findMany({
      where: { status: 'PUBLISHED', company: { isBlocked: false } },
      include: { ...this.includeForDto, point: { include: { city: true } } },
      orderBy: { readyDate: 'asc' },
    });
    const body = driverId ? await this.driverCargoBody(driverId) : null;
    const fitting = body ? cargos.filter((c) => CargosService.cargoFitsVehicle(c, body)) : cargos;

    const [{ origin, source }, driver] = driverId
      ? await Promise.all([
          this.feedOrigin(driverId),
          this.prisma.driver.findUnique({ where: { id: driverId }, include: { homeCity: true, directions: true } }),
        ])
      : [{ origin: null, source: null }, null];
    const homeCountryId = driver?.homeCity?.countryId ?? null;
    const selected = new Set(driver?.directions?.map((d) => d.countryId) ?? []);

    const ranked = fitting.map((cargo) => {
      const pickupRank = origin ? CargosService.pickupRank(cargo.point, origin) : 2;
      const section: 'home' | 'selected' | 'other' =
        homeCountryId && cargo.destinationCountryId === homeCountryId
          ? 'home'
          : (driver?.anyCountry ?? true) || selected.has(cargo.destinationCountryId)
            ? 'selected'
            : 'other';
      return { cargo, pickupRank, section };
    });
    const sectionOrder = { home: 0, selected: 1, other: 2 } as const;
    ranked.sort(
      (a, b) =>
        a.pickupRank - b.pickupRank ||
        sectionOrder[a.section] - sectionOrder[b.section] ||
        a.cargo.readyDate.getTime() - b.cargo.readyDate.getTime(),
    );

    const items = await Promise.all(
      ranked.slice(offset, offset + limit).map(async ({ cargo, pickupRank, section }) => ({
        ...(await this.toDto(cargo)),
        pickupRank,
        feedSection: section,
      })),
    );
    return { items, total: ranked.length, offset, limit, originCityId: origin?.cityId ?? null, originSource: source };
  }

  /// «Помещается к текущему: 8 т + 10 т из 20 т» (задача 040, п.6) — для
  /// водителя с активной сделкой; расчёт тот же, что при подтверждении
  /// (`evaluateVehicleLoad`). Без активной сделки подсказки нет.
  async partialHint(driverId: string, cargoId: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');

    const lastDeal = await this.prisma.deal.findFirst({
      where: { driverId, status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT'] } },
      orderBy: { createdAt: 'desc' },
    });
    if (!lastDeal) return { hint: null };

    const load = await evaluateVehicleLoad(this.prisma, {
      driverId,
      tractorId: lastDeal.tractorId,
      trailerId: lastDeal.trailerId,
      cargo,
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
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  /// Задача 033, п.10 — подсказка при публикации: «подходит N водителям на
  /// точке». Простой счётчик по активным анонсам, те же правила отсева,
  /// что у ленты (cargoFitsVehicle).
  async fitCount(params: { weightKg?: number; volumeM3?: number; palletCount?: number; pointId?: string }) {
    const arrivals = await this.prisma.arrival.findMany({
      where: { status: { in: ['PLANNED', 'ON_SITE'] }, ...(params.pointId ? { pointId: params.pointId } : {}) },
      include: { trailer: true, tractor: true },
    });
    const cargoLike = {
      weightKg: params.weightKg ?? null,
      volumeM3: params.volumeM3 ?? null,
      palletCount: params.palletCount ?? null,
    };
    const fittingDrivers = new Set<string>();
    for (const arrival of arrivals) {
      const vehicle = arrival.trailer ?? (arrival.tractor?.kind === 'RIGID' ? arrival.tractor : null);
      const body = {
        capacityTons: vehicle?.capacityTons != null ? Number(vehicle.capacityTons) : null,
        volumeM3: vehicle?.volumeM3 != null ? Number(vehicle.volumeM3) : null,
        palletsEuro: vehicle?.palletsEuro ?? null,
      };
      if (CargosService.cargoFitsVehicle(cargoLike, body)) fittingDrivers.add(arrival.driverId);
    }
    return { count: fittingDrivers.size };
  }

  async byId(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: this.includeForDto });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return this.toDto(cargo);
  }

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

    const cargo = await this.prisma.cargo.create({
      data: {
        companyId,
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
        readyDate,
        allowPartial: dto.allowPartial ?? false,
        description: dto.description,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        expiresAt,
      },
      include: this.includeForDto,
    });
    return this.toDto(cargo);
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

    const cargo = await this.prisma.cargo.update({
      where: { id },
      data: {
        pointId: dto.pointId,
        allowPartial: dto.allowPartial,
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        palletCount: dto.palletCount,
        photoUrls: dto.photoUrls,
        price: dto.price,
        currency: dto.currency,
        readyDate,
        expiresAt,
        description: dto.description,
      },
      include: this.includeForDto,
    });
    return this.toDto(cargo);
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

    await this.prisma.cargo.update({
      where: { id },
      data: { status: 'CANCELLED', closeOutcome: dto.outcome, closedAt: new Date() },
    });
  }
}
