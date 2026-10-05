import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Driver, Prisma, Response as CargoResponseEntity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';

type ResponseWithDriver = CargoResponseEntity & { driver: Driver };

@Injectable()
export class ResponsesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
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

  async listForCargo(cargoId: string) {
    const responses = await this.prisma.response.findMany({
      where: { cargoId },
      include: { driver: true },
      orderBy: { createdAt: 'desc' },
    });
    return responses.map((r) => this.toDto(r));
  }

  async createForCargo(cargoId: string, driverId: string, message?: string) {
    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    if (existing) {
      throw new ConflictException('You have already responded to this cargo');
    }
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
    if (!cargo) throw new NotFoundException('Cargo not found');

    const response = await this.prisma.response.create({
      data: { cargoId, driverId, message, status: 'PENDING' },
      include: { driver: true },
    });

    const contactUserId = await resolveCargoContactUserId(this.prisma, cargo);
    await this.notifications.notify(
      { userIds: contactUserId ? [contactUserId] : [], companyId: cargo.companyId },
      'NEW_RESPONSE',
      { cargoId, driverName: response.driver.fullName },
    );

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

  async updateStatus(responseId: string, companyId: string, status: 'SELECTED' | 'REJECTED') {
    const response = await this.prisma.response.findUnique({
      where: { id: responseId },
      include: { driver: true, cargo: true },
    });
    if (!response) throw new NotFoundException('Response not found');
    if (response.cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    if (status === 'REJECTED') {
      const updated = await this.prisma.response.update({
        where: { id: responseId },
        data: { status: 'REJECTED' },
        include: { driver: true },
      });
      return this.toDto(updated);
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.response.updateMany({
        where: { cargoId: response.cargoId, status: 'PENDING', id: { not: responseId } },
        data: { status: 'REJECTED' },
      });
      const selected = await tx.response.update({
        where: { id: responseId },
        data: { status: 'SELECTED' },
        include: { driver: true },
      });
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

    return this.toDto(updated.selected);
  }

  /// Логист приглашает конкретного водителя на груз напрямую (со страницы
  /// "Кто будет на Хоргосе"), без предварительного отклика водителя.
  async inviteDriver(cargoId: string, driverId: string, companyId: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    if (cargo.companyId !== companyId) throw new ForbiddenException('Not your cargo');

    const existing = await this.prisma.response.findUnique({ where: { cargoId_driverId: { cargoId, driverId } } });
    if (existing && existing.status !== 'PENDING') {
      throw new ConflictException('Driver already has a decided response for this cargo');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.response.updateMany({
        where: { cargoId, status: 'PENDING' },
        data: { status: 'REJECTED' },
      });
      const selected = existing
        ? await tx.response.update({ where: { id: existing.id }, data: { status: 'SELECTED' }, include: { driver: true } })
        : await tx.response.create({
            data: { cargoId, driverId, status: 'SELECTED' },
            include: { driver: true },
          });
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
