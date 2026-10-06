import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Company, Deal, Driver, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CargosService } from '../cargos/cargos.service';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';

const PROGRESSION = ['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'] as const;

type DealWithRelations = Deal & {
  driver: Driver;
  company: Company;
  cargo: Parameters<CargosService['toDto']>[0];
};

@Injectable()
export class DealsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cargos: CargosService,
    private readonly notifications: NotificationsService,
  ) {}

  /// Push обеим сторонам + WeCom компании при смене статуса сделки
  /// (задача 011, таблица событий «Смена статуса сделки»).
  private async notifyStatusChange(deal: DealWithRelations, status: string) {
    const contactUserId = await resolveCargoContactUserId(this.prisma, deal.cargo);
    await this.notifications.notify(
      { userIds: [deal.driver.userId, ...(contactUserId ? [contactUserId] : [])], companyId: deal.companyId },
      'DEAL_STATUS',
      { dealId: deal.id, status },
    );
  }

  private readonly include = {
    driver: true,
    company: true,
    cargo: { include: { company: { include: { country: { select: { code: true } } } }, publishedBy: { select: { id: true, name: true, phone: true } } } },
  } as const;

  async toDto(deal: DealWithRelations) {
    return {
      id: deal.id,
      responseId: deal.responseId,
      cargoId: deal.cargoId,
      driverId: deal.driverId,
      driverName: deal.driver.fullName,
      companyId: deal.companyId,
      companyName: deal.company.name,
      status: deal.status,
      cancelReason: deal.cancelReason,
      cancelledByRole: deal.cancelledByRole,
      confirmedAt: deal.confirmedAt,
      loadedAt: deal.loadedAt,
      inTransitAt: deal.inTransitAt,
      deliveredAt: deal.deliveredAt,
      createdAt: deal.createdAt,
      cargo: await this.cargos.toDto(deal.cargo),
      driverLocation:
        deal.driver.currentLat && deal.driver.currentLng
          ? {
              lat: Number(deal.driver.currentLat),
              lng: Number(deal.driver.currentLng),
              updatedAt: deal.driver.locationUpdatedAt,
            }
          : null,
    };
  }

  async mine(ctx: { driverId?: string; companyId?: string }) {
    const deals = await this.prisma.deal.findMany({
      where: ctx.driverId ? { driverId: ctx.driverId } : { companyId: ctx.companyId },
      include: this.include,
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(deals.map((d) => this.toDto(d)));
  }

  private async findEntity(id: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id }, include: this.include });
    if (!deal) throw new NotFoundException('Deal not found');
    return deal;
  }

  async byId(id: string, ctx: { driverId?: string; companyId?: string }) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    return this.toDto(deal);
  }

  private assertParty(deal: Deal, ctx: { driverId?: string; companyId?: string }) {
    const isParty = (ctx.driverId && deal.driverId === ctx.driverId) || (ctx.companyId && deal.companyId === ctx.companyId);
    if (!isParty) throw new ForbiddenException('Not a party to this deal');
  }

  /// Задача 037 — догруз разрешён, «бронь всего подряд» — нет: при
  /// «Подтверждаю перевозку» суммируются ВСЕ активные сделки водителя на
  /// ту же связку машин (+ новая). Правила:
  /// - вес: Σ ≤ capacityTons×1000; груз БЕЗ веса = полная загрузка;
  /// - объём/паллеты: только когда известны и у машины, и у всех грузов;
  /// - даты погрузки всех грузов в окне ±1 день от новой — иначе это не
  ///   догруз, а следующий рейс (подтверждать после DELIVERED текущих).
  /// Отклики и выбор логистом не ограничиваются (п.1/3 — логист видит
  /// «Уже везёт…» и решает сам), жёсткая проверка только здесь.
  private async assertVehicleNotFull(tx: Prisma.TransactionClient | PrismaService, deal: DealWithRelations) {
    const cargo = deal.cargo;
    if (!cargo) return;

    // Задача 038, п.6 — активные сделки считаем по ТЯГАЧУ, без прицепа в
    // фильтре: одна машина везёт одну загрузку, и смена прицепа в анонсе —
    // не способ подтвердить вторую полную машину тем же тягачом. Прицеп
    // участвует только как источник вместимости (ниже).
    const activeDeals = await tx.deal.findMany({
      where: {
        driverId: deal.driverId,
        status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT'] },
        tractorId: deal.tractorId,
        id: { not: deal.id },
      },
      include: { cargo: true },
    });
    if (activeDeals.length === 0) return;

    const bodyVehicleId = deal.trailerId ?? deal.tractorId;
    const vehicle = bodyVehicleId ? await tx.vehicle.findUnique({ where: { id: bodyVehicleId } }) : null;
    const capacityKg = vehicle?.capacityTons != null ? Number(vehicle.capacityTons) * 1000 : null;

    const allCargos = [cargo, ...activeDeals.map((d) => d.cargo).filter((c): c is NonNullable<typeof c> => c != null)];
    const describe = activeDeals.map((d) => ({
      dealId: d.id,
      weightKg: d.cargo?.weightKg != null ? Number(d.cargo.weightKg) : null,
      readyDate: d.cargo?.readyDate ?? null,
      destinationCountryId: d.cargo?.destinationCountryId ?? null,
      destinationCityId: d.cargo?.destinationCityId ?? null,
    }));
    const usedWeightKg = activeDeals.reduce((sum, d) => sum + (d.cargo?.weightKg != null ? Number(d.cargo.weightKg) : 0), 0);
    const reject = (reason: 'NEXT_TRIP' | 'FULL') => {
      throw new ConflictException({
        code: 'VEHICLE_FULL',
        reason,
        usedWeightKg,
        capacityKg,
        deals: describe,
        message: 'Vehicle is already committed — finish or cancel the current haul first',
      });
    };

    const DAY_MS = 24 * 60 * 60 * 1000;
    const newReady = cargo.readyDate.getTime();
    const sameWindow = activeDeals.every((d) => d.cargo != null && Math.abs(d.cargo.readyDate.getTime() - newReady) <= DAY_MS);
    if (!sameWindow) reject('NEXT_TRIP');

    // Задача 038, п.6 — прицеп без тоннажа: вместимость неизвестна, догруз
    // не посчитать — разрешаем только ОДНУ активную сделку на тягач
    // (раньше вес вообще не проверялся, и лимита не было).
    if (capacityKg == null) reject('FULL');

    // Груз без веса занимает машину целиком — второй рядом не подтвердить.
    if (allCargos.some((c) => c.weightKg == null)) reject('FULL');
    const totalKg = allCargos.reduce((sum, c) => sum + Number(c.weightKg), 0);
    if (capacityKg != null && totalKg > capacityKg) reject('FULL');
    if (vehicle?.volumeM3 != null && allCargos.every((c) => c.volumeM3 != null)) {
      const totalM3 = allCargos.reduce((sum, c) => sum + Number(c.volumeM3), 0);
      if (totalM3 > Number(vehicle.volumeM3)) reject('FULL');
    }
    if (vehicle?.palletsEuro != null && allCargos.every((c) => c.palletCount != null)) {
      const totalPallets = allCargos.reduce((sum, c) => sum + (c.palletCount as number), 0);
      if (totalPallets > vehicle.palletsEuro) reject('FULL');
    }
  }

  async advanceStatus(id: string, driverId: string, nextStatus: string) {
    const deal = await this.findEntity(id);
    if (deal.driverId !== driverId) throw new ForbiddenException('Not your deal');

    const currentIndex = PROGRESSION.indexOf(deal.status as (typeof PROGRESSION)[number]);
    const nextIndex = PROGRESSION.indexOf(nextStatus as (typeof PROGRESSION)[number]);
    if (currentIndex === -1 || nextIndex !== currentIndex + 1) {
      throw new BadRequestException(`Cannot move deal from ${deal.status} to ${nextStatus}`);
    }

    // Задача 031, этап A, п.4 / задача 032, п.5 — подтвердить сделку можно,
    // только если проверены И водитель (селфи+права, контроллер уже
    // проверил выше), И машины выбранной на рейс связки (свои техпаспорта).
    // Раньше сделка без связки (null — до миграции 031 или анонса не было)
    // тихо пропускала эту проверку — теперь это 409 VEHICLE_REQUIRED, а не
    // молчаливый пропуск: тягач обязателен всегда, прицеп — если тягач не
    // RIGID (одиночка без прицепа).
    if (nextStatus === 'CONFIRMED_BY_DRIVER') {
      if (!deal.tractorId) throw new ConflictException('VEHICLE_REQUIRED');
      const tractor = await this.prisma.vehicle.findUnique({ where: { id: deal.tractorId }, select: { isVerified: true, kind: true } });
      if (!tractor) throw new ConflictException('VEHICLE_REQUIRED');
      const needsTrailer = tractor.kind !== 'RIGID';
      if (needsTrailer && !deal.trailerId) throw new ConflictException('VEHICLE_REQUIRED');

      const vehicleIds = [deal.tractorId, ...(needsTrailer ? [deal.trailerId as string] : [])];
      const vehicles = await this.prisma.vehicle.findMany({ where: { id: { in: vehicleIds } }, select: { id: true, isVerified: true } });
      const notVerified = vehicles.some((v) => !v.isVerified);
      if (notVerified || vehicles.length !== vehicleIds.length) {
        throw new BadRequestException('VEHICLE_NOT_VERIFIED');
      }
    }

    const now = new Date();
    const timestampField = {
      CONFIRMED_BY_DRIVER: 'confirmedAt',
      LOADED: 'loadedAt',
      IN_TRANSIT: 'inTransitAt',
      DELIVERED: 'deliveredAt',
    }[nextStatus as 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED'];

    let updated: DealWithRelations;
    if (nextStatus === 'CONFIRMED_BY_DRIVER') {
      // Задача 038, п.7 — проверка вместимости и запись статуса в ОДНОЙ
      // транзакции под advisory-замком по водителю: два параллельных
      // «Подтверждаю перевозку» сериализуются, и второй уже видит сделку,
      // записанную первым (раньше оба читали «свободно» и оба проходили).
      // pg_advisory_xact_lock освобождается сам при commit/rollback.
      updated = await this.prisma.$transaction(async (tx) => {
        // ::text — pg_advisory_xact_lock возвращает void, который Prisma
        // не умеет десериализовать (Raw query failed … type 'void').
        await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtext(${deal.driverId}))::text`;
        // Перечитываем статус под замком — параллельное подтверждение ТОЙ
        // ЖЕ сделки второй раз не пройдёт прогрессию.
        const fresh = await tx.deal.findUnique({ where: { id }, select: { status: true } });
        if (fresh?.status !== deal.status) {
          throw new BadRequestException(`Cannot move deal from ${fresh?.status ?? 'missing'} to ${nextStatus}`);
        }
        await this.assertVehicleNotFull(tx, deal);
        return tx.deal.update({
          where: { id },
          data: { status: nextStatus as Deal['status'], [timestampField]: now },
          include: this.include,
        });
      });
    } else {
      updated = await this.prisma.deal.update({
        where: { id },
        data: { status: nextStatus as Deal['status'], [timestampField]: now },
        include: this.include,
      });
    }
    await this.notifyStatusChange(updated, nextStatus);
    return this.toDto(updated);
  }

  async cancel(id: string, ctx: { driverId?: string; companyId?: string }, reason: string) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    if (deal.status === 'DELIVERED' || deal.status === 'CANCELLED') {
      throw new BadRequestException('This deal can no longer be cancelled');
    }

    const updated = await this.prisma.deal.update({
      where: { id },
      data: {
        status: 'CANCELLED',
        cancelReason: reason,
        cancelledByRole: ctx.driverId ? 'DRIVER' : 'COMPANY',
      },
      include: this.include,
    });
    await this.notifyStatusChange(updated, 'CANCELLED');
    return this.toDto(updated);
  }
}
