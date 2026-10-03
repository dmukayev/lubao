import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Driver, Response as CargoResponseEntity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type ResponseWithDriver = CargoResponseEntity & { driver: Driver };

@Injectable()
export class ResponsesService {
  constructor(private readonly prisma: PrismaService) {}

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
    const response = await this.prisma.response.create({
      data: { cargoId, driverId, message, status: 'PENDING' },
      include: { driver: true },
    });
    return this.toDto(response);
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
      await tx.deal.create({
        data: {
          responseId: selected.id,
          cargoId: selected.cargoId,
          driverId: selected.driverId,
          companyId,
          status: 'SELECTED',
        },
      });
      return selected;
    });

    return this.toDto(updated);
  }

  /// Логист приглашает конкретного водителя на груз напрямую (со страницы
  /// "Кто будет на Хоргосе"), без предварительного отклика водителя.
  async inviteDriver(cargoId: string, driverId: string, companyId: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id: cargoId } });
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
      await tx.deal.create({
        data: { responseId: selected.id, cargoId: selected.cargoId, driverId: selected.driverId, companyId, status: 'SELECTED' },
      });
      return selected;
    });

    return this.toDto(updated);
  }
}
