import { DealActor, notifyDealStatus } from './deal-status-notify';
import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { PricingService } from '../pricing/pricing.service';
import { CancelStage, Company, Deal, DealStatus, Driver, FaultSide, Prisma, ReviewAuthorRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { completeArrivalForConfirmedDeal } from '../arrivals/arrival-lifecycle';
import { evaluateVehicleLoad } from './vehicle-load';
import { CargosService } from '../cargos/cargos.service';
import { ChatSystemCode, ChatSystemMessagesService } from '../chats/chat-system-messages.service';
import {
  CANCEL_REQUEST_TIMEOUT_HOURS,
  CancelReasonCode,
  cancelStatsFor,
  DRIVER_ONLY_REASONS,
  faultFor,
  needsCounterpartyConsent,
  recomputeCompanyRating,
  recomputeDriverRating,
  stageForStatus,
} from './cancel-policy';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';
import { toDateOnly } from '../common/date-only';

function rethrowStatusRace(e: unknown): never {
  if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') throw new ConflictException('DEAL_STATUS_CHANGED');
  throw e;
}

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
    @Optional() private readonly pricing?: PricingService,
  ) {}

  /// Push обеим сторонам + WeCom компании при смене статуса сделки
  /// (задача 011, таблица событий «Смена статуса сделки»). Задача 038,
  /// п.12 — плюс deal:updated в комнату чата сделки: собеседник с
  /// открытым чатом видит новый статус без перезахода.
  private async notifyStatusChange(deal: DealWithRelations, status: string, actor: DealActor) {
    // 042 п.8: второй стороне — текст от её лица (кто нажал — push не получает).
    await notifyDealStatus(this.prisma, this.notifications, deal, status, actor);
    const contactUserId = await resolveCargoContactUserId(this.prisma, deal.cargo);
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
    // 046 п.3: обе стороны видят отмены друг друга (карточка сделки, чат).
    const [driverStats, companyStats] = await Promise.all([
      cancelStatsFor(this.prisma, 'DRIVER', [deal.driverId]),
      cancelStatsFor(this.prisma, 'COMPANY', [deal.companyId]),
    ]);
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
      // 046: этап и вина отмены; запрос отмены после «В пути» и спор.
      cancelStage: deal.cancelStage,
      faultSide: deal.faultSide,
      cancelRequest: deal.cancelRequestedAt
        ? {
            byRole: deal.cancelRequestedByRole,
            reasonCode: deal.cancelRequestReasonCode,
            reason: deal.cancelRequestReason,
            requestedAt: deal.cancelRequestedAt,
            expiresAt: new Date(deal.cancelRequestedAt.getTime() + CANCEL_REQUEST_TIMEOUT_HOURS * 60 * 60 * 1000),
            disputeReason: deal.disputeReason,
            disputedAt: deal.disputedAt,
          }
        : null,
      confirmedAt: deal.confirmedAt,
      loadedAt: deal.loadedAt,
      inTransitAt: deal.inTransitAt,
      deliveredAt: deal.deliveredAt,
      createdAt: deal.createdAt,
      driverCancelStats: driverStats.get(deal.driverId) ?? null,
      companyCancelStats: companyStats.get(deal.companyId) ?? null,
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
    // 044 п.2, 4–5: в карточке сделки — проверены ли машины рейса (плашка
    // «Машина ещё на проверке») и когда логист последний раз открыл документы.
    const vehicleIds = [deal.tractorId, deal.trailerId].filter((v): v is string => !!v);
    const [vehicles, lastDocsAccess] = await Promise.all([
      vehicleIds.length ? this.prisma.vehicle.findMany({ where: { id: { in: vehicleIds } }, select: { isVerified: true } }) : Promise.resolve([] as Array<{ isVerified: boolean }>),
      this.prisma.auditLog.findFirst({
        where: { entityType: 'Deal', entityId: deal.id, action: { in: ['DRIVER_DOCS_VIEWED', 'DRIVER_DOCS_DOWNLOADED'] } },
        orderBy: { createdAt: 'desc' },
        select: { createdAt: true },
      }),
    ]);
    return {
      ...(await this.toDto(deal)),
      vehiclesVerified: vehicles.length > 0 && vehicles.every((v) => v.isVerified),
      driverDocsOpenedAt: lastDocsAccess?.createdAt ?? null,
    };
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

    // Подтвердить сделку можно, только если проверен водитель (селфи+права —
    // контроллер проверил выше) и выбрана связка на рейс: тягач всегда, прицеп —
    // если тягач не RIGID (задача 032, п.5: без связки — 409 VEHICLE_REQUIRED).
    // Проверка САМОЙ машины больше не гейт (044 п.5, decisions.md 2026-10-07):
    // логист видит «Машина ещё на проверке» в пакете документов и решает сам.
    if (nextStatus === 'CONFIRMED_BY_DRIVER') {
      if (!deal.tractorId) throw new ConflictException('VEHICLE_REQUIRED');
      const tractor = await this.prisma.vehicle.findUnique({ where: { id: deal.tractorId }, select: { kind: true } });
      if (!tractor) throw new ConflictException('VEHICLE_REQUIRED');
      if (tractor.kind !== 'RIGID' && !deal.trailerId) throw new ConflictException('VEHICLE_REQUIRED');
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
        const confirmed = await tx.deal.update({
          where: { id },
          data: { status: nextStatus as Deal['status'], [timestampField]: now },
          include: this.include,
        });
        // Анонс сделал своё дело и гаснет сам (задача 040, п.4) — в той же
        // транзакции (042 п.0): сделка и анонс меняются вместе или никак.
        await completeArrivalForConfirmedDeal(tx, deal.driverId, now);
        return confirmed;
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
      // 047 п.4: сделка — точка статистики цен по маршруту.
      if (this.pricing) {
        const cargo = await this.prisma.cargo.findUnique({
          where: { id: updated.cargoId },
          include: { point: { select: { cityId: true } }, destinationCountry: { select: { code: true } } },
        });
        if (cargo) await this.pricing.recordPoint('DEAL', cargo, { driverId: updated.driverId, dealId: updated.id });
      }
    }
    await this.notifyStatusChange(updated, nextStatus, 'DRIVER');
    return this.toDto(updated);
  }

  /// Отмена сделки (046). До «В пути» — сразу, с этапом и стороной вины;
  /// после — только запросом: вторая сторона подтверждает или оспаривает,
  /// без ответа 24 ч отмена проходит сама (JobsService).
  async cancel(id: string, ctx: { driverId?: string; companyId?: string }, reason: string | undefined, reasonCode?: CancelReasonCode) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    const by: ReviewAuthorRole = ctx.driverId ? 'DRIVER' : 'COMPANY';
    const code: CancelReasonCode = reasonCode ?? 'OTHER';
    if (DRIVER_ONLY_REASONS.has(code) && by !== 'DRIVER') throw new BadRequestException('REASON_NOT_ALLOWED');
    const text = reason?.trim() || null;
    if (code === 'OTHER' && !text) throw new BadRequestException('REASON_TEXT_REQUIRED');

    if (deal.status === 'CANCEL_REQUESTED' || deal.status === 'DISPUTED') {
      throw new ConflictException('CANCEL_ALREADY_REQUESTED');
    }
    if (deal.status === 'DELIVERED' || deal.status === 'CANCELLED') {
      throw new BadRequestException('This deal can no longer be cancelled');
    }

    if (needsCounterpartyConsent(deal.status)) {
      const updated = await this.prisma.deal.update({
        where: { id, status: deal.status },
        data: {
          status: 'CANCEL_REQUESTED',
          cancelRequestedAt: new Date(),
          cancelRequestedByRole: by,
          cancelRequestReasonCode: code,
          cancelRequestReason: text,
        },
        include: this.include,
      }).catch(rethrowStatusRace);
      await this.postCancelLine(updated, by === 'DRIVER' ? updated.driver.userId : null, 'CANCEL_REQUESTED', { reasonCode: code, ...(text ? { reason: text } : {}) });
      await this.notifyStatusChange(updated, 'CANCEL_REQUESTED', by);
      return this.toDto(updated);
    }

    const updated = await this.closeCancelled(deal, {
      by,
      code,
      text,
      stage: stageForStatus(deal.status),
      faultSide: faultFor(code, by),
    });
    await this.notifyStatusChange(updated, 'CANCELLED', by);
    return this.toDto(updated);
  }

  /// Жалоба по сделке (046 п.6): одна открытая от автора на сделку.
  async complain(id: string, ctx: { driverId?: string; companyId?: string }, reporterUserId: string, reason: string, description?: string) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    const open = await this.prisma.complaint.findFirst({
      where: { reporterUserId, targetType: 'DEAL', targetId: id, status: { in: ['OPEN', 'IN_REVIEW'] } },
      select: { id: true },
    });
    if (open) throw new ConflictException('COMPLAINT_ALREADY_OPEN');
    const created = await this.prisma.complaint.create({
      data: { reporterUserId, targetType: 'DEAL', targetId: id, reason: reason.trim(), description: description?.trim() || null },
    });
    return { id: created.id, status: created.status };
  }

  /// Вторая сторона согласна с запросом отмены → CANCELLED, вина — по причине.
  async confirmCancel(id: string, ctx: { driverId?: string; companyId?: string }) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    const me: ReviewAuthorRole = ctx.driverId ? 'DRIVER' : 'COMPANY';
    if (deal.status !== 'CANCEL_REQUESTED') throw new ConflictException('NO_CANCEL_REQUEST');
    if (deal.cancelRequestedByRole === me) throw new ForbiddenException('OWN_CANCEL_REQUEST');
    const by = deal.cancelRequestedByRole as ReviewAuthorRole;
    const updated = await this.closeCancelled(deal, {
      by,
      code: deal.cancelRequestReasonCode,
      text: deal.cancelRequestReason,
      stage: 'IN_TRANSIT',
      faultSide: faultFor(deal.cancelRequestReasonCode, by),
      expectStatus: 'CANCEL_REQUESTED',
    });
    await this.postCancelLine(updated, me === 'DRIVER' ? updated.driver.userId : null, 'CANCEL_CONFIRMED');
    await this.notifyStatusChange(updated, 'CANCELLED', me);
    return this.toDto(updated);
  }

  /// «Оспорить» → DISPUTED: строка в «Требует внимания» админа с обеими позициями.
  async disputeCancel(id: string, ctx: { driverId?: string; companyId?: string }, reason: string) {
    const deal = await this.findEntity(id);
    this.assertParty(deal, ctx);
    const me: ReviewAuthorRole = ctx.driverId ? 'DRIVER' : 'COMPANY';
    if (deal.status !== 'CANCEL_REQUESTED') throw new ConflictException('NO_CANCEL_REQUEST');
    if (deal.cancelRequestedByRole === me) throw new ForbiddenException('OWN_CANCEL_REQUEST');
    const updated = await this.prisma.deal.update({
      where: { id, status: 'CANCEL_REQUESTED' },
      data: { status: 'DISPUTED', disputedAt: new Date(), disputeReason: reason.trim() },
      include: this.include,
    }).catch(rethrowStatusRace);
    await this.postCancelLine(updated, me === 'DRIVER' ? updated.driver.userId : null, 'CANCEL_DISPUTED');
    await this.notifyStatusChange(updated, 'DISPUTED', me);
    return this.toDto(updated);
  }

  /// Админ закрывает спор (046 п.5): отменить с виновной стороной или вернуть в «В пути».
  async resolveDispute(id: string, adminUserId: string, resolution: 'CANCEL' | 'RESUME', guilty: ReviewAuthorRole | null, note: string) {
    const deal = await this.findEntity(id);
    if (deal.status !== 'DISPUTED' && deal.status !== 'CANCEL_REQUESTED') throw new ConflictException('NO_DISPUTE');
    let updated: DealWithRelations;
    if (resolution === 'RESUME') {
      updated = await this.prisma.deal.update({
        where: { id, status: deal.status },
        data: {
          status: 'IN_TRANSIT',
          cancelRequestedAt: null,
          cancelRequestedByRole: null,
          cancelRequestReasonCode: null,
          cancelRequestReason: null,
          disputedAt: null,
          disputeReason: null,
        },
        include: this.include,
      }).catch(rethrowStatusRace);
      await this.postCancelLine(updated, adminUserId, 'CANCEL_RESUMED');
      await this.notifyStatusChange(updated, 'IN_TRANSIT', 'ADMIN');
    } else {
      const by = (deal.cancelRequestedByRole ?? 'DRIVER') as ReviewAuthorRole;
      const faultSide: FaultSide = guilty == null ? 'NEUTRAL' : guilty === by ? 'SELF' : 'OTHER_PARTY';
      updated = await this.closeCancelled(deal, {
        by,
        code: deal.cancelRequestReasonCode,
        text: deal.cancelRequestReason,
        stage: 'IN_TRANSIT',
        faultSide,
        expectStatus: deal.status,
      });
      await this.postCancelLine(updated, adminUserId, 'CANCEL_RESOLVED');
      await this.notifyStatusChange(updated, 'CANCELLED', 'ADMIN');
    }
    await this.prisma.auditLog.create({
      data: {
        actorUserId: adminUserId,
        action: 'DEAL_DISPUTE_RESOLVED',
        entityType: 'Deal',
        entityId: id,
        metadata: { resolution, guilty, note } as Prisma.InputJsonValue,
      },
    });
    return this.toDto(updated);
  }

  /// Запрос отмены без ответа 24 ч → отмена проходит, вина — на молчавшем.
  async expireCancelRequests(now = new Date()): Promise<{ cancelled: number }> {
    const before = new Date(now.getTime() - CANCEL_REQUEST_TIMEOUT_HOURS * 60 * 60 * 1000);
    const due = await this.prisma.deal.findMany({
      where: { status: 'CANCEL_REQUESTED', cancelRequestedAt: { lt: before } },
      include: this.include,
    });
    let cancelled = 0;
    for (const deal of due) {
      try {
        const updated = await this.closeCancelled(deal, {
          by: (deal.cancelRequestedByRole ?? 'DRIVER') as ReviewAuthorRole,
          code: deal.cancelRequestReasonCode,
          text: deal.cancelRequestReason,
          stage: 'IN_TRANSIT',
          faultSide: 'OTHER_PARTY',
          expectStatus: 'CANCEL_REQUESTED',
        });
        await this.postCancelLine(updated, null, 'CANCEL_AUTO');
        await this.notifyStatusChange(updated, 'CANCELLED', 'ADMIN');
        cancelled += 1;
      } catch {
        // Ответ пришёл между выборкой и записью — сделка уже не в запросе.
      }
    }
    return { cancelled };
  }

  /// Запись отмены: этап, сторона вины, груз снова в ленте, рейтинг обеих сторон.
  private async closeCancelled(
    deal: DealWithRelations,
    p: { by: ReviewAuthorRole; code: string | null; text: string | null; stage: CancelStage; faultSide: FaultSide; expectStatus?: DealStatus },
  ): Promise<DealWithRelations> {
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.deal.update({
        // Статус мог смениться параллельно (ответ второй стороны, таймаут) — тогда P2025 → 409.
        where: { id: deal.id, status: p.expectStatus ?? deal.status },
        data: {
          status: 'CANCELLED',
          cancelReason: p.text,
          cancelReasonCode: p.code ?? 'OTHER',
          cancelledByRole: p.by,
          cancelStage: p.stage,
          faultSide: p.faultSide,
        },
        include: this.include,
      });
      // Сделка отменена → груз снова в ленте, если он не был закрыт (041, п.2).
      await tx.cargo.updateMany({ where: { id: updated.cargoId, status: 'IN_DEAL' }, data: { status: 'PUBLISHED' } });
      await recomputeDriverRating(tx, updated.driverId);
      await recomputeCompanyRating(tx, updated.companyId);
      return updated;
    }).catch(rethrowStatusRace);
  }

  private async postCancelLine(deal: DealWithRelations, actorUserId: string | null, code: ChatSystemCode, systemParams: Record<string, string> = {}) {
    const chat = await this.prisma.chat.findFirst({ where: { dealId: deal.id }, select: { id: true } });
    const actor = actorUserId ?? (await resolveCargoContactUserId(this.prisma, deal.cargo)) ?? deal.driver.userId;
    if (chat) await this.chatSystem.postToChat(chat.id, actor, code, systemParams);
    else await this.chatSystem.post({ driverId: deal.driverId, companyId: deal.companyId, cargoId: deal.cargoId, actorUserId: actor, code, systemParams });
  }
}
