import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Company, Deal, Driver } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CargosService } from '../cargos/cargos.service';

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
  ) {}

  private readonly include = { driver: true, company: true, cargo: { include: { company: true } } } as const;

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

  async advanceStatus(id: string, driverId: string, nextStatus: string) {
    const deal = await this.findEntity(id);
    if (deal.driverId !== driverId) throw new ForbiddenException('Not your deal');

    const currentIndex = PROGRESSION.indexOf(deal.status as (typeof PROGRESSION)[number]);
    const nextIndex = PROGRESSION.indexOf(nextStatus as (typeof PROGRESSION)[number]);
    if (currentIndex === -1 || nextIndex !== currentIndex + 1) {
      throw new BadRequestException(`Cannot move deal from ${deal.status} to ${nextStatus}`);
    }

    const now = new Date();
    const timestampField = {
      CONFIRMED_BY_DRIVER: 'confirmedAt',
      LOADED: 'loadedAt',
      IN_TRANSIT: 'inTransitAt',
      DELIVERED: 'deliveredAt',
    }[nextStatus as 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED'];

    const updated = await this.prisma.deal.update({
      where: { id },
      data: { status: nextStatus as Deal['status'], [timestampField]: now },
      include: this.include,
    });
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
    return this.toDto(updated);
  }
}
