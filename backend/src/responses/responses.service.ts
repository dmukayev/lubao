import { ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { Driver, Prisma, Response as CargoResponseEntity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ChatSystemMessagesService } from '../chats/chat-system-messages.service';
import { haulInfoByDriver } from '../deals/haul-summary';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';
import { IdentifiersService } from '../identifiers/identifiers.service';
import { toDateOnly } from '../common/date-only';
import { cancelStatsFor } from '../deals/cancel-policy';

type ResponseWithDriver = CargoResponseEntity & { driver: Driver };

@Injectable()
export class ResponsesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly chatSystem: ChatSystemMessagesService,
    @Optional() private readonly identifiers?: IdentifiersService,
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

  /// «Мои отклики» водителя (041, п.9): все его отклики со статусом и краткой
  /// сводкой груза — одним списком, чтобы видеть, куда откликался и что с этим.
  async listMine(driverId: string) {
    const responses = await this.prisma.response.findMany({
      where: { driverId },
      orderBy: { updatedAt: 'desc' },
      include: {
        cargo: { select: { id: true, status: true, destinationCountryId: true, destinationCityId: true, bodyTypeId: true, price: true, currency: true, readyDate: true } },
      },
    });
    return responses.map((r) => ({
      id: r.id,
      cargoId: r.cargoId,
      status: r.status,
      updatedAt: r.updatedAt,
      cargo: {
        id: r.cargo.id,
        status: r.cargo.status,
        destinationCountryId: r.cargo.destinationCountryId,
        destinationCityId: r.cargo.destinationCityId,
        bodyTypeId: r.cargo.bodyTypeId,
        price: Number(r.cargo.price),
        currency: r.cargo.currency,
        readyDate: toDateOnly(r.cargo.readyDate),
      },
    }));
  }

  async findMine(cargoId: string, driverId: string) {
    const response = await this.prisma.response.findUnique({
      where: { cargoId_driverId: { cargoId, driverId } },
      select: { id: true, status: true },
    });
    return response ?? null;
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
          select: { id: true, bodyTypeId: true, capacityTons: true, volumeM3: true, palletsEuro: true, specs: true },
        })
      : [];
    const bodyByVehicle = new Map(bodies.map((v) => [v.id, v]));
    // Сделка по выбранному отклику: логист видит её статус и переходит в неё
    // прямо из откликов (живая проверка 2026-10-07: «Выбран» оставался навсегда).
    const deals = await this.prisma.deal.findMany({
      where: { responseId: { in: responses.map((r) => r.id) } },
      select: { id: true, responseId: true, status: true },
    });
    const dealByResponse = new Map(deals.map((d) => [d.responseId, d]));
    // 046 п.3: отмены водителя — в карточке отклика.
    const cancelStats = await cancelStatsFor(this.prisma, 'DRIVER', [...combos.keys()]);

    return responses.map((r) => {
      const combo = combos.get(r.driverId);
      const bodyId = combo ? (combo.trailerId ?? combo.tractorId) : null;
      const body = bodyId != null ? bodyByVehicle.get(bodyId) : undefined;
      const info = haul.get(r.driverId);
      return {
        ...this.toDto(r),
        // 045 п.4–5: кузов для миниатюры; машины нет — кузов и тоннаж из регистрации.
        bodyTypeId: body?.bodyTypeId ?? r.driver.preferredBodyTypeId ?? null,
        specs: (body ? body.specs : r.driver.preferredSpecs) ?? null,
        capacityTons: body?.capacityTons != null ? Number(body.capacityTons) : r.driver.preferredCapacityTons != null ? Number(r.driver.preferredCapacityTons) : null,
        // 033 п.9 (хвост, 038 п.14) — объём/паллеты связки в отклике.
        volumeM3: body?.volumeM3 != null ? Number(body.volumeM3) : null,
        palletsEuro: body?.palletsEuro ?? null,
        committedWeightKg: info?.committedWeightKg ?? 0,
        activeDealsCount: info?.activeDealsCount ?? 0,
        committedHasUnknownWeight: info?.committedHasUnknownWeight ?? false,
        committedDestinationCountryId: info?.committedDestinationCountryId ?? null,
        committedDestinationCityId: info?.committedDestinationCityId ?? null,
        committedReadyDate: info?.committedReadyDate ?? null,
        dealId: dealByResponse.get(r.id)?.id ?? null,
        dealStatus: dealByResponse.get(r.id)?.status ?? null,
        cancelStats: cancelStats.get(r.driverId) ?? null,
      };
    });
  }

  /// Телефон в чёрном списке (039 п.2 / 041): после снятия гейта верификации
  /// с «Готов взять» заблокированному по номеру откликаться всё равно нельзя.
  private async assertNotBlacklisted(driverId: string) {
    if (!this.identifiers) return;
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, include: { user: { select: { phone: true } } } });
    const phone = driver?.user.phone;
    if (!phone) return;
    const match = await this.identifiers.checkMatches('PHONE', phone, { ownerType: 'DRIVER', ownerId: driverId });
    if (match.blocked) throw new ForbiddenException({ code: 'DRIVER_BLACKLISTED', message: 'This account is blocked' });
  }

  /// «Договорились?» → «Да» от водителя (042, decisions.md: договорились мимо
  /// кнопок — ловит «Договорились?»): отклик (новый или возвращённый в работу,
  /// даже если раньше отклонён — водитель говорит, что договорились) + push
  /// логисту «выберите его» + строка в чат. Сделку по-прежнему создаёт выбор логиста.
  async driverAgreed(cargoId: string, driverId: string) {
    await this.assertNotBlacklisted(driverId);
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    if (cargo.status !== 'PUBLISHED') {
      throw new ConflictException({ code: 'CARGO_NOT_AVAILABLE', message: 'Cargo is no longer available' });
    }
    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    const keep = existing && (existing.status === 'PENDING' || existing.status === 'SELECTED');
    const response = keep
      ? await this.prisma.response.findUniqueOrThrow({ where: { id: existing!.id }, include: { driver: true } })
      : existing
        ? await this.prisma.response.update({ where: { id: existing.id }, data: { status: 'PENDING' }, include: { driver: true } })
        : await this.prisma.response.create({ data: { cargoId, driverId, status: 'PENDING' }, include: { driver: true } });

    const contactUserId = await resolveCargoContactUserId(this.prisma, cargo);
    await this.notifications.notify(
      { userIds: contactUserId ? [contactUserId] : [], companyId: cargo.companyId },
      'DRIVER_AGREED',
      { cargoId, driverName: response.driver.fullName },
    );
    await this.chatSystem.post({
      driverId,
      companyId: cargo.companyId,
      cargoId,
      actorUserId: response.driver.userId,
      code: 'DRIVER_SAYS_AGREED',
      systemParams: { driverName: response.driver.fullName },
    });
    return this.toDto(response);
  }

  async createForCargo(cargoId: string, driverId: string, message?: string) {
    await this.assertNotBlacklisted(driverId);
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    // Груз с активной сделкой (IN_DEAL) и закрытый — для откликов закрыт (041, п.2).
    if (cargo.status !== 'PUBLISHED') {
      throw new ConflictException({ code: 'CARGO_NOT_AVAILABLE', message: 'Cargo is no longer available' });
    }
    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    // Отозвал → передумал → снова «Готов взять» (задача 038, п.2): НЕ 409,
    // а переоткрытие того же отклика (уникальный ключ cargoId+driverId не
    // даёт создать второй). Приглашён → «Готов взять» — то же переоткрытие
    // (INVITED → PENDING, задача 041, п.3). 409 — только для решённых.
    if (existing && existing.status !== 'CANCELLED' && existing.status !== 'INVITED') {
      throw new ConflictException({ code: 'RESPONSE_ALREADY_EXISTS', message: 'You have already responded to this cargo' });
    }

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
    // Анонсов может быть несколько (040): берём тот, где водитель на месте,
    // иначе ближайший по дате приезда.
    const arrivals = await client.arrival.findMany({
      where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
      orderBy: [{ plannedDay: 'asc' }, { createdAt: 'desc' }],
      select: { status: true, tractorId: true, trailerId: true },
    });
    const arrival = arrivals.find((a) => a.status === 'ON_SITE') ?? arrivals[0];
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
    if (response.status !== 'PENDING' && response.status !== 'INVITED') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
    }
    const wasInvited = response.status === 'INVITED';

    const updated = await this.closePending(responseId, response.cargoId, 'CANCELLED');

    // «Водитель отозвал отклик» / «отказался от приглашения» — системно в чат
    // (задача 038, п.11/12), логист с открытым чатом видит смену кнопок сразу.
    await this.chatSystem.post({
      driverId,
      companyId: response.cargo.companyId,
      cargoId: response.cargoId,
      actorUserId: updated.driver.userId,
      code: wasInvited ? 'INVITATION_DECLINED' : 'RESPONSE_WITHDRAWN',
      systemParams: { driverName: updated.driver.fullName },
    });

    return this.toDto(updated);
  }

  /// Активная сделка на груз уже есть → вторую создавать нельзя (задача
  /// 038, п.1): раньше `deal.responseId @unique` защищал только от второй
  /// сделки на ТОТ ЖЕ отклик, а «Выбрать» в чате с другим водителем
  /// спокойно создавал параллельную сделку на тот же груз.
  /// Замок по грузу (освобождается на commit/rollback); `::text` — Prisma
  /// не десериализует void. Берут ВСЕ переходы статуса откликов груза
  /// (выбор, отклонение, отзыв): иначе «Отклонить»/«Отозвать» затирали
  /// `SELECTED`, выставленный параллельным «Выбрать» (039, п.1).
  private async lockCargo(tx: Prisma.TransactionClient, cargoId: string) {
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtext(${cargoId}))::text`;
  }

  /// PENDING → REJECTED/CANCELLED под замком груза, условным апдейтом: если
  /// отклик за это время уже выбран/отозван/отклонён — 409, а не молчаливая
  /// перезапись (039, п.1).
  private async closePending(responseId: string, cargoId: string, to: 'REJECTED' | 'CANCELLED') {
    return this.prisma.$transaction(async (tx) => {
      await this.lockCargo(tx, cargoId);
      // PENDING и INVITED: приглашение можно и отозвать (логист), и отклонить (водитель).
      const res = await tx.response.updateMany({ where: { id: responseId, status: { in: ['PENDING', 'INVITED'] } }, data: { status: to } });
      if (res.count === 0) {
        throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
      }
      return tx.response.findUniqueOrThrow({ where: { id: responseId }, include: { driver: true } });
    });
  }

  /// Уникальный индекс «одна активная сделка на груз» / responseId @unique
  /// (039, п.3): гонка, дошедшая до БД, — это 409, а не 500.
  private rethrowUnique(e: unknown): never {
    if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
      throw new ConflictException({ code: 'CARGO_ALREADY_HAS_DEAL', message: 'Cargo already has an active deal' });
    }
    throw e;
  }

  private async assertNoActiveDeal(tx: Prisma.TransactionClient, cargoId: string) {
    // Задача 038, п.22 — проверка «нет активной сделки» без блокировки
    // гонялась: два логиста одновременно видели «свободно» и создавали две
    // сделки. Замок по грузу до проверки сериализует выбор.
    await this.lockCargo(tx, cargoId);
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
      if (response.status !== 'PENDING' && response.status !== 'INVITED') {
        throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
      }
      const updated = await this.closePending(responseId, response.cargoId, 'REJECTED');
      // Задача 038, п.27 — водитель с открытым чатом сразу видит «отклонён»
      // (системная строка + chat:updated из неё), а не вечный «Отклик отправлен».
      await this.chatSystem.post({
        driverId: updated.driverId,
        companyId,
        cargoId: updated.cargoId,
        actorUserId: actorUserId ?? updated.driver.userId,
        code: 'RESPONSE_REJECTED',
      });
      await this.notifyRejected([updated.driver.userId], companyId, updated.cargoId);
      return this.toDto(updated);
    }

    // Выбор — только из PENDING (задача 038, п.1): REJECTED/CANCELLED
    // отклик «Выбрать» в чате больше не воскрешает в сделку.
    if (response.status !== 'PENDING') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Response is no longer pending' });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await this.assertNoActiveDeal(tx, response.cargoId);
      const takenFrom = await this.markCargoTaken(tx, response.cargoId, responseId);
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
      return { selected, deal, takenFrom };
    }).catch((e) => this.rethrowUnique(e));

    await this.notifications.notify({ userIds: [updated.selected.driver.userId] }, 'DEAL_SELECTED', {
      dealId: updated.deal.id,
    });

    // «Выбран водитель» — системно в чат пары (задача 038, п.11/12).
    await this.chatSystem.post({
      driverId: updated.selected.driverId,
      companyId,
      cargoId: updated.selected.cargoId,
      actorUserId: actorUserId ?? updated.selected.driver.userId,
      code: 'DRIVER_SELECTED',
      systemParams: { driverName: updated.selected.driver.fullName },
    });

    await this.postCargoTaken(updated.takenFrom, companyId, updated.selected.cargoId, actorUserId ?? updated.selected.driver.userId);

    return this.toDto(updated.selected);
  }

  /// Груз ушёл в сделку (041, п.2): статус IN_DEAL (из ленты исчезает),
  /// остальные PENDING/INVITED отклики — REJECTED. Возвращает тех, кого
  /// отклонили, чтобы после коммита написать им «Груз ушёл другому».
  private async markCargoTaken(tx: Prisma.TransactionClient, cargoId: string, exceptResponseId: string | null) {
    const others = await tx.response.findMany({
      where: { cargoId, status: { in: ['PENDING', 'INVITED'] }, ...(exceptResponseId ? { id: { not: exceptResponseId } } : {}) },
      select: { id: true, driverId: true, driver: { select: { userId: true } } },
    });
    if (others.length > 0) {
      await tx.response.updateMany({ where: { id: { in: others.map((o) => o.id) } }, data: { status: 'REJECTED' } });
    }
    await tx.cargo.updateMany({ where: { id: cargoId, status: 'PUBLISHED' }, data: { status: 'IN_DEAL' } });
    return others;
  }

  private async postCargoTaken(others: Array<{ driverId: string; driver: { userId: string } }>, companyId: string, cargoId: string, actorUserId: string) {
    for (const other of others) {
      await this.chatSystem.post({ driverId: other.driverId, companyId, cargoId, actorUserId, code: 'CARGO_TAKEN' });
    }
    await this.notifyRejected(others.map((o) => o.driver.userId), companyId, cargoId);
  }

  /// Push «Логист выбрал другого водителя» (045 п.3) — best-effort: сбой
  /// уведомлений не должен откатывать выбор водителя.
  private async notifyRejected(userIds: string[], companyId: string, cargoId: string) {
    if (!userIds.length) return;
    try {
      const company = await this.prisma.company.findUnique({ where: { id: companyId }, select: { name: true } });
      await this.notifications.notify({ userIds }, 'RESPONSE_REJECTED', { cargoId, companyName: company?.name ?? '' });
    } catch {
      // уведомление не критично
    }
  }

  /// Приглашение с согласием (041, п.3): логист зовёт водителя на груз —
  /// создаётся отклик INVITED, НЕ сделка и НЕ отклонение чужих откликов.
  /// Водитель отвечает «Готов взять» (→ PENDING, потом «Выбрать» логиста) или
  /// «Отказаться». Повторное приглашение того, кто уже в игре, — идемпотентно.
  async inviteDriver(cargoId: string, driverId: string, companyId: string, actorUserId?: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    if (cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    // Проверка статуса груза и запись приглашения — в одной транзакции под
    // замком груза (041, п.13): иначе параллельный выбор другого водителя
    // успевал уйти между проверкой и записью, и на ушедший груз оставался
    // «висячий» INVITED.
    const { response, created } = await this.prisma.$transaction(async (tx) => {
      await this.lockCargo(tx, cargoId);
      const fresh = await tx.cargo.findUnique({ where: { id: cargoId }, select: { status: true } });
      if (fresh?.status !== 'PUBLISHED') {
        throw new ConflictException({ code: 'CARGO_NOT_AVAILABLE', message: 'Cargo is no longer available' });
      }

      const existing = await tx.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } }, include: { driver: true } });
      if (existing && (existing.status === 'INVITED' || existing.status === 'PENDING' || existing.status === 'SELECTED')) {
        return { response: existing, created: false };
      }
      if (existing && existing.status !== 'CANCELLED') {
        throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Driver already has a decided response for this cargo' });
      }

      const saved = existing
        ? await tx.response.update({ where: { id: existing.id }, data: { status: 'INVITED' }, include: { driver: true } })
        : await tx.response.create({ data: { cargoId, driverId, status: 'INVITED' }, include: { driver: true } });
      return { response: saved, created: true };
    });
    if (!created) return this.toDto(response);

    await this.notifications.notify({ userIds: [response.driver.userId] }, 'CARGO_INVITE', {
      cargoId,
      companyName: cargo.company.name,
    });
    await this.chatSystem.post({
      driverId,
      companyId,
      cargoId,
      actorUserId: actorUserId ?? response.driver.userId,
      code: 'DRIVER_INVITED',
      systemParams: { driverName: response.driver.fullName },
    });
    return this.toDto(response);
  }

  /// «Нашёл в Lubao» при закрытии груза (017, п.6) — сделка сразу, без
  /// согласия: логист уже договорился. Это прежнее поведение приглашения.
  async createDealDirect(cargoId: string, driverId: string, companyId: string, actorUserId?: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    if (cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    // CANCELLED (водитель отзывал) приглашать можно — переоткрывается тот
    // же отклик (задача 038, п.2); REJECTED/SELECTED — решённые, нельзя.
    if (existing && existing.status !== 'PENDING' && existing.status !== 'INVITED' && existing.status !== 'CANCELLED') {
      throw new ConflictException({ code: 'RESPONSE_NOT_PENDING', message: 'Driver already has a decided response for this cargo' });
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await this.assertNoActiveDeal(tx, cargoId);
      const takenFrom = await this.markCargoTaken(tx, cargoId, existing?.id ?? null);
      let selected;
      if (existing) {
        // Условный апдейт (п.22): решённый между проверкой и замком отклик
        // не воскрешается.
        const claimed = await tx.response.updateMany({
          where: { id: existing.id, status: { in: ['PENDING', 'INVITED', 'CANCELLED'] } },
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
      return { selected, takenFrom };
    }).catch((e) => this.rethrowUnique(e));
    const taken = updated.takenFrom;
    const selectedResponse = updated.selected;

    await this.notifications.notify({ userIds: [selectedResponse.driver.userId] }, 'CARGO_INVITE', {
      cargoId,
      companyName: cargo.company.name,
    });

    // «Выбран водитель» — системно в чат пары (задача 038, п.11/12).
    await this.chatSystem.post({
      driverId,
      companyId,
      cargoId,
      actorUserId: actorUserId ?? selectedResponse.driver.userId,
      code: 'DRIVER_SELECTED',
      systemParams: { driverName: selectedResponse.driver.fullName },
    });
    await this.postCargoTaken(taken, companyId, cargoId, actorUserId ?? selectedResponse.driver.userId);

    return this.toDto(selectedResponse);
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
