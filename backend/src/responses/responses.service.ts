import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Driver, Prisma, Response as CargoResponseEntity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChatSystemMessagesService } from '../chats/chat-system-messages.service';
import { haulInfoByDriver } from '../deals/haul-summary';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';

type ResponseWithDriver = CargoResponseEntity & { driver: Driver };

@Injectable()
export class ResponsesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly chatSystem: ChatSystemMessagesService,
  ) {}

  toDto(response: ResponseWithDriver) {
    return {
      id: response.id,
      cargoId: response.cargoId,
      driverId: response.driverId,
      driverName: response.driver.fullName,
      message: response.message,
      status: response.status,
      createdAt: response.createdAt,
    };
  }

  /// Список откликов для логиста (задача 038, п.8/9) — каждый отклик несёт
  /// сводку «Уже везёт…» по текущей связке водителя + вместимость прицепа:
  /// логист видит занятость ДО выбора, клиент мягко предупреждает, если
  /// груз, похоже, не поместится (водитель всё равно не сможет подтвердить).
  async listForCargo(cargoId: string) {
    const responses = await this.prisma.response.findMany({
      where: { cargoId },
      include: { driver: true },
      orderBy: { createdAt: 'desc' },
    });
    if (responses.length === 0) return [];

    const combos = new Map<string, { tractorId: string | null; trailerId: string | null }>();
    for (const r of responses) {
      if (!combos.has(r.driverId)) {
        combos.set(r.driverId, await this.currentVehicleCombo(this.prisma, r.driverId));
      }
    }
    const haul = await haulInfoByDriver(
      this.prisma,
      [...combos.entries()].map(([driverId, combo]) => ({ driverId, tractorId: combo.tractorId })),
    );
    const bodyIds = [...combos.values()].map((c) => c.trailerId ?? c.tractorId).filter((id): id is string => id != null);
    const bodies = bodyIds.length
      ? await this.prisma.vehicle.findMany({
          where: { id: { in: bodyIds } },
          select: { id: true, capacityTons: true, volumeM3: true, palletsEuro: true },
        })
      : [];
    const bodyByVehicle = new Map(bodies.map((v) => [v.id, v]));

    return responses.map((r) => {
      const combo = combos.get(r.driverId);
      const bodyId = combo ? (combo.trailerId ?? combo.tractorId) : null;
      const body = bodyId != null ? bodyByVehicle.get(bodyId) : undefined;
      const info = haul.get(r.driverId);
      return {
        ...this.toDto(r),
        capacityTons: body?.capacityTons != null ? Number(body.capacityTons) : null,
        // 033 п.9 (хвост, 038 п.14) — объём/паллеты связки в отклике.
        volumeM3: body?.volumeM3 != null ? Number(body.volumeM3) : null,
        palletsEuro: body?.palletsEuro ?? null,
        committedWeightKg: info?.committedWeightKg ?? 0,
        activeDealsCount: info?.activeDealsCount ?? 0,
        committedHasUnknownWeight: info?.committedHasUnknownWeight ?? false,
        committedDestinationCountryId: info?.committedDestinationCountryId ?? null,
        committedDestinationCityId: info?.committedDestinationCityId ?? null,
        committedReadyDate: info?.committedReadyDate ?? null,
      };
    });
  }

  async createForCargo(cargoId: string, driverId: string, message?: string) {
    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    // Отозвал → передумал → снова «Готов взять» (задача 038, п.2): НЕ 409,
    // а переоткрытие того же отклика (уникальный ключ cargoId+driverId не
    // даёт создать второй). 409 — только для реально решённых откликов.
    if (existing && existing.status !== 'CANCELLED') {
      throw new ConflictException({ code: 'RESPONSE_ALREADY_EXISTS', message: 'You have already responded to this cargo' });
    }
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');

    const response = existing
      ? await this.prisma.response.update({
          where: { id: existing.id },
          data: { status: 'PENDING', message: message ?? existing.message },
          include: { driver: true },
        })
      : await this.prisma.response.create({
          data: { cargoId, driverId, message, status: 'PENDING' },
          include: { driver: true },
        });

    const contactUserId = await resolveCargoContactUserId(this.prisma, cargo);
    await this.notifications.notify(
      { userIds: contactUserId ? [contactUserId] : [], companyId: cargo.companyId },
      'NEW_RESPONSE',
      { cargoId, driverName: response.driver.fullName },
    );

    // Системная строка «готов взять» в чат пары (задача 038, п.11) —
    // сервером, не клиентом: раньше клиент слал обычное сообщение от
    // имени водителя, и оно переводилось моделью.
    await this.chatSystem.post({
      driverId,
      companyId: cargo.companyId,
      cargoId,
      actorUserId: response.driver.userId,
      code: 'DRIVER_READY',
      systemParams: { driverName: response.driver.fullName },
    });

    return this.toDto(response);
  }

  /// Связка машин водителя на момент создания сделки (задача 031, этап A,
  /// п.4) — снимок, а не live-ссылка: если водитель потом сменит гараж,
  /// уже созданная сделка проверяется по машинам, которые он заявлял.
  /// Задача 032, п.5 — связка берётся из АКТИВНОГО анонса водителя (ту,
  /// что он выбрал на эту поездку), а не из первых по дате машин гаража:
  /// иначе проверенный тягач A в гараже проходит проверку, хотя в анонсе
  /// выбран непроверенный B — логист видит B, сделка подтверждается по A.
  private async currentVehicleCombo(
    client: Prisma.TransactionClient | PrismaService,
    driverId: string,
  ): Promise<{ tractorId: string | null; trailerId: string | null }> {
    const arrival = await client.arrival.findFirst({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: { createdAt: 'desc' },
      select: { tractorId: true, trailerId: true },
    });
    if (arrival?.tractorId) return { tractorId: arrival.tractorId, trailerId: arrival.trailerId };

    // Нет активного анонса (отклик без анонса — теоретически возможно,
    // например логист пригласил напрямую водителя, который ещё не
    // анонсировался) — фолбэк на гараж, как раньше.
    const [tractor, trailer] = await Promise.all([
      client.vehicle.findFirst({ where: { driverId, kind: { in: ['TRACTOR', 'RIGID'] }, isArchived: false }, orderBy: { createdAt: 'asc' } }),
      client.vehicle.findFirst({ where: { driverId, kind: 'TRAILER', isArchived: false }, orderBy: { createdAt: 'asc' } }),
    ]);
    return { tractorId: tractor?.id ?? null, trailerId: trailer?.id ?? null };
  }

  /// «Отозвать» (задача 035) — только сам водитель, только пока отклик
  /// ещё `PENDING` (логист уже посмотрел/выбрал — поздно отзывать молча).
  /// `CANCELLED` — значение уже было в схеме (задача 017), просто не
  /// использовалось ни одним путём до этой задачи.
  async withdraw(responseId: string, driverId: string) {
    const response = await this.prisma.response.findUnique({ where: { id: responseId }, include: { driver: true, cargo: { select: { companyId: true } } } });
    if (!response) throw new NotFoundException('Response not found');
    if (response.driverId !== driverId) throw new ForbiddenException('Not your response');
    if (response.status !== 'PENDING') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
    }

    const updated = await this.prisma.response.update({ where: { id: responseId }, data: { status: 'CANCELLED' }, include: { driver: true } });

    // «Водитель отозвал отклик» — системно в чат (задача 038, п.11/12),
    // логист с открытым чатом видит смену кнопок сразу.
    await this.chatSystem.post({
      driverId,
      companyId: response.cargo.companyId,
      cargoId: response.cargoId,
      actorUserId: updated.driver.userId,
      code: 'RESPONSE_WITHDRAWN',
      systemParams: { driverName: updated.driver.fullName },
    });

    return this.toDto(updated);
  }

  /// Активная сделка на груз уже есть → вторую создавать нельзя (задача
  /// 038, п.1): раньше `deal.responseId @unique` защищал только от второй
  /// сделки на ТОТ ЖЕ отклик, а «Выбрать» в чате с другим водителем
  /// спокойно создавал параллельную сделку на тот же груз.
  private async assertNoActiveDeal(tx: Prisma.TransactionClient, cargoId: string) {
    // Задача 038, п.22 — проверка «нет активной сделки» без блокировки
    // гонялась: два логиста одновременно видели «свободно» и создавали две
    // сделки. Замок по грузу до проверки сериализует выбор (освобождается на
    // commit/rollback); `::text` — Prisma не десериализует void.
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtext(${cargoId}))::text`;
    const activeDeal = await tx.deal.findFirst({
      where: { cargoId, status: { not: 'CANCELLED' } },
      select: { id: true },
    });
    if (activeDeal) {
      throw new ConflictException({ code: 'CARGO_ALREADY_HAS_DEAL', message: 'Cargo already has an active deal' });
    }
  }

  async updateStatus(responseId: string, companyId: string, status: 'SELECTED' | 'REJECTED', actorUserId?: string) {
    const response = await this.prisma.response.findUnique({
      where: { id: responseId },
      include: { driver: true, cargo: true },
    });
    if (!response) throw new NotFoundException('Response not found');
    if (response.cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    if (status === 'REJECTED') {
      // Повторное «Отклонить» — идемпотентно; но SELECTED/CANCELLED
      // отклонять нельзя: у SELECTED уже есть сделка, у CANCELLED нечего.
      if (response.status === 'REJECTED') return this.toDto(response);
      if (response.status !== 'PENDING') {
        throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
      }
      const updated = await this.prisma.response.update({
        where: { id: responseId },
        data: { status: 'REJECTED' },
        include: { driver: true },
      });
      return this.toDto(updated);
    }

    // Выбор — только из PENDING (задача 038, п.1): REJECTED/CANCELLED
    // отклик «Выбрать» в чате больше не воскрешает в сделку.
    if (response.status !== 'PENDING') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await this.assertNoActiveDeal(tx, response.cargoId);
      await tx.response.updateMany({
        where: { cargoId: response.cargoId, status: 'PENDING', id: { not: responseId } },
        data: { status: 'REJECTED' },
      });
      // Условный апдейт (п.22): статус мог уйти из PENDING между чтением
      // снаружи транзакции и замком — 0 затронутых = отклик уже решён.
      const claimed = await tx.response.updateMany({ where: { id: responseId, status: 'PENDING' }, data: { status: 'SELECTED' } });
      if (claimed.count === 0) {
        throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
      }
      const selected = await tx.response.findUniqueOrThrow({ where: { id: responseId }, include: { driver: true } });
      const combo = await this.currentVehicleCombo(tx, selected.driverId);
      const deal = await tx.deal.create({
        data: {
          responseId: selected.id,
          cargoId: selected.cargoId,
          driverId: selected.driverId,
          companyId,
          status: 'SELECTED',
          tractorId: combo.tractorId,
          trailerId: combo.trailerId,
        },
      });
      await this.attachChatToDeal(tx, deal);
      return { selected, deal };
    });

    await this.notifications.notify({ userIds: [updated.selected.driver.userId] }, 'DEAL_STATUS', {
      dealId: updated.deal.id,
      status: 'SELECTED',
    });

    // «Выбран водитель» — системно в чат пары (задача 038, п.11/12).
    await this.chatSystem.post({
      driverId: updated.selected.driverId,
      companyId,
      cargoId: updated.selected.cargoId,
      actorUserId: actorUserId ?? updated.selected.driver.userId,
      code: 'DRIVER_SELECTED',
    });

    return this.toDto(updated.selected);
  }

  /// Логист приглашает конкретного водителя на груз напрямую (со страницы
  /// "Кто будет на Хоргосе"), без предварительного отклика водителя.
  async inviteDriver(cargoId: string, driverId: string, companyId: string, actorUserId?: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    if (cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    // CANCELLED (водитель отзывал) приглашать можно — переоткрывается тот
    // же отклик (задача 038, п.2); REJECTED/SELECTED — решённые, нельзя.
    if (existing && existing.status !== 'PENDING' && existing.status !== 'CANCELLED') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Driver already has a decided response for this cargo' });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await this.assertNoActiveDeal(tx, cargoId);
      await tx.response.updateMany({
        where: { cargoId, status: 'PENDING' },
        data: { status: 'REJECTED' },
      });
      let selected;
      if (existing) {
        // Условный апдейт (п.22): решённый между проверкой и замком отклик
        // не воскрешается.
        const claimed = await tx.response.updateMany({
          where: { id: existing.id, status: { in: ['PENDING', 'CANCELLED'] } },
          data: { status: 'SELECTED' },
        });
        if (claimed.count === 0) {
          throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Driver already has a decided response for this cargo' });
        }
        selected = await tx.response.findUniqueOrThrow({ where: { id: existing.id }, include: { driver: true } });
      } else {
        selected = await tx.response.create({
          data: { cargoId, driverId, status: 'SELECTED' },
          include: { driver: true },
        });
      }
      const combo = await this.currentVehicleCombo(tx, selected.driverId);
      const deal = await tx.deal.create({
        data: {
          responseId: selected.id,
          cargoId: selected.cargoId,
          driverId: selected.driverId,
          companyId,
          status: 'SELECTED',
          tractorId: combo.tractorId,
          trailerId: combo.trailerId,
        },
      });
      await this.attachChatToDeal(tx, deal);
      return selected;
    });

    await this.notifications.notify({ userIds: [updated.driver.userId] }, 'CARGO_INVITE', {
      cargoId,
      companyName: cargo.company.name,
    });

    // «Выбран водитель» — системно в чат пары (задача 038, п.11/12).
    await this.chatSystem.post({
      driverId,
      companyId,
      cargoId,
      actorUserId: actorUserId ?? updated.driver.userId,
      code: 'DRIVER_SELECTED',
    });

    return this.toDto(updated);
  }

  /// Чат водитель+логист(+груз), заведённый до сделки (задача 017, п.1/3),
  /// привязывается к только что созданной сделке — история переписки не
  /// теряется, карточка сделки закрепляется сверху чата на клиенте.
  private async attachChatToDeal(tx: Prisma.TransactionClient, deal: { id: string; cargoId: string; driverId: string; companyId: string }) {
    await tx.chat.updateMany({
      where: { driverId: deal.driverId, companyId: deal.companyId, cargoId: deal.cargoId },
      data: { dealId: deal.id },
    });
  }
}
