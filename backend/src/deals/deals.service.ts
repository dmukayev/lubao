import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Company, Deal, Driver, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { completeArrivalForConfirmedDeal } from '../arrivals/arrival-lifecycle';
import { evaluateVehicleLoad } from './vehicle-load';
import { CargosService } from '../cargos/cargos.service';
import { ChatSystemMessagesService } from '../chats/chat-system-messages.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';
import { toDateOnly } from '../common/date-only';

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
    private readonly chatSystem: ChatSystemMessagesService,
    private readonly realtime: RealtimeGateway,
  ) {}

  /// Push обеим сторонам + WeCom компании при смене статуса сделки
  /// (задача 011, таблица событий «Смена статуса сделки»). Задача 038,
  /// п.12 — плюс deal:updated в комнату чата сделки: собеседник с
  /// открытым чатом видит новый статус без перезахода.
  private async notifyStatusChange(deal: DealWithRelations, status: string) {
    const contactUserId = await resolveCargoContactUserId(this.prisma, deal.cargo);
    await this.notifications.notify(
      { userIds: [deal.driver.userId, ...(contactUserId ? [contactUserId] : [])], companyId: deal.companyId },
      'DEAL_STATUS',
      { dealId: deal.id, status },
    );
    const chat = await this.prisma.chat.findFirst({ where: { dealId: deal.id }, select: { id: true } });
    if (chat) this.realtime.emitDealUpdated(chat.id, { dealId: deal.id, status });
    // Личные комнаты участников: водителю — чтобы трекинг рейса стартовал/
    // останавливался по событию, логисту — чтобы список сделок обновлялся.
    for (const userId of new Set([deal.driver.userId, ...(contactUserId ? [contactUserId] : [])])) {
      this.realtime.emitDealUpdatedToUser(userId, { dealId: deal.id, status });
    }
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
      cancelReasonCode: deal.cancelReasonCode,
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

  /// Жёсткая проверка вместимости при «Подтверждаю перевозку» (задача 037);
  /// сам расчёт — `evaluateVehicleLoad` (его же использует подсказка в ленте).
  /// Отклики и выбор логистом не ограничиваются (п.1/3 — логист видит
  /// «Уже везёт…» и решает сам).
  private async assertVehicleNotFull(tx: Prisma.TransactionClient | PrismaService, deal: DealWithRelations) {
    const cargo = deal.cargo;
    if (!cargo) return;

    const load = await evaluateVehicleLoad(tx, {
      driverId: deal.driverId,
      tractorId: deal.tractorId,
      trailerId: deal.trailerId,
      cargo,
      excludeDealId: deal.id,
    });
    if (load.verdict === 'NONE' || load.verdict === 'OK') return;
    throw new ConflictException({
      code: 'VEHICLE_FULL',
      reason: load.verdict,
      usedWeightKg: load.usedWeightKg,
      capacityKg: load.capacityKg,
      deals: load.deals,
      message: 'Vehicle is already committed — finish or cancel the current haul first',
    });
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
    // «Перевозка подтверждена» — системная строка в чат (задача 038, п.11).
    if (nextStatus === 'CONFIRMED_BY_DRIVER') {
      // Анонс сделал своё дело и гаснет сам (задача 040, п.4).
      await completeArrivalForConfirmedDeal(this.prisma, updated.driverId, now);
      await this.chatSystem.post({
        driverId: updated.driverId,
        companyId: updated.companyId,
        cargoId: updated.cargoId,
        actorUserId: updated.driver.userId,
        code: 'DEAL_CONFIRMED',
      });
    }
    // Доставлено → груз закрыт («нашёл в Lubao»), 041.
    if (nextStatus === 'DELIVERED') {
      await this.prisma.cargo.updateMany({
        where: { id: updated.cargoId, status: 'IN_DEAL' },
        data: { status: 'ARCHIVED', closeOutcome: 'FOUND_IN_APP', closedAt: new Date() },
      });
    }
    await this.notifyStatusChange(updated, nextStatus);
    return this.toDto(updated);
  }

  async cancel(id: string, ctx: { driverId?: string; companyId?: string }, reason: string, reasonCode?: string) {
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
        // Код причины (038, п.15) — «взял другой груз» и т.п. считаются
        // в статистике по коду, не по переведённой строке.
        // п.28 (038): код «взял другой груз» — признак ВОДИТЕЛЯ; от компании/админа игнорируется.
        cancelReasonCode: ctx.driverId ? (reasonCode ?? null) : null,
        cancelledByRole: ctx.driverId ? 'DRIVER' : 'COMPANY',
      },
      include: this.include,
    });
    // Сделка отменена → груз снова в ленте, если он не был закрыт (041, п.2).
    await this.prisma.cargo.updateMany({ where: { id: updated.cargoId, status: 'IN_DEAL' }, data: { status: 'PUBLISHED' } });
    await this.notifyStatusChange(updated, 'CANCELLED');
    return this.toDto(updated);
  }
}
