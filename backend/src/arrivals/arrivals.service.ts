import { Injectable, NotFoundException } from '@nestjs/common';
import { Arrival } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ArrivalsService {
  constructor(private readonly prisma: PrismaService) {}

  private async toDto(arrival: Arrival) {
    const logists = await this.prisma.cargo.groupBy({
      by: ['companyId'],
      where: { pointId: arrival.pointId, status: 'PUBLISHED' },
    });

    return {
      id: arrival.id,
      pointId: arrival.pointId,
      arrivedAt: arrival.arrivedAt,
      expectedDepartureAt: arrival.expectedDepartureAt,
      status: arrival.status,
      logistsCount: logists.length,
    };
  }

  async getMine(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const arrival = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: 'ACTIVE' },
      orderBy: { arrivedAt: 'desc' },
    });
    return arrival ? this.toDto(arrival) : null;
  }

  /// «Я уже на месте»: подтверждает присутствие в единственной активной точке
  /// старта (сейчас — только Хоргос). Повторный вызов просто обновляет
  /// arrivedAt на текущий момент — логисты должны видеть, что водитель
  /// на месте СЕЙЧАС, а не был там когда-то раньше.
  async checkIn(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const point = await this.prisma.point.findFirst({ where: { isActive: true } });
    if (!point) throw new NotFoundException('No active loading point configured');

    const existing = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: 'ACTIVE' },
    });

    const arrival = existing
      ? await this.prisma.arrival.update({
          where: { id: existing.id },
          data: { pointId: point.id, arrivedAt: new Date() },
        })
      : await this.prisma.arrival.create({
          data: { driverId: driver.id, pointId: point.id, arrivedAt: new Date() },
        });

    return this.toDto(arrival);
  }

  async leave(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');

    const existing = await this.prisma.arrival.findFirst({
      where: { driverId: driver.id, status: 'ACTIVE' },
    });
    if (!existing) return null;

    const arrival = await this.prisma.arrival.update({
      where: { id: existing.id },
      data: { status: 'COMPLETED' },
    });
    return this.toDto(arrival);
  }

  /// «Кто будет на Хоргосе» — список водителей, которые сейчас на активной
  /// точке, для логистов. N+1 по машине/направлениям — приемлемо на текущем
  /// масштабе (тот же подход, что и в DriversService.toDto).
  async listForCompany(filters: {
    countryId?: string;
    bodyTypeId?: string;
    minCapacityTons?: number;
    verifiedOnly?: boolean;
  }) {
    const arrivals = await this.prisma.arrival.findMany({
      where: { status: 'ACTIVE' },
      include: { driver: { include: { user: true } } },
      orderBy: { arrivedAt: 'desc' },
    });

    const rows = await Promise.all(
      arrivals.map(async (arrival) => {
        const [vehicle, directions] = await Promise.all([
          this.prisma.vehicle.findFirst({ where: { driverId: arrival.driverId }, orderBy: { createdAt: 'asc' } }),
          this.prisma.driverDirection.findMany({ where: { driverId: arrival.driverId } }),
        ]);
        return { arrival, vehicle, directionCountryIds: directions.map((d) => d.countryId) };
      }),
    );

    return rows
      .filter((r) => !filters.verifiedOnly || r.arrival.driver.isVerified)
      .filter((r) => !filters.bodyTypeId || r.vehicle?.bodyTypeId === filters.bodyTypeId)
      .filter(
        (r) =>
          !filters.minCapacityTons ||
          (r.vehicle?.capacityTons != null && Number(r.vehicle.capacityTons) >= filters.minCapacityTons!),
      )
      .filter(
        (r) => !filters.countryId || r.arrival.driver.anyCountry || r.directionCountryIds.includes(filters.countryId!),
      )
      .map((r) => ({
        arrivalId: r.arrival.id,
        driverId: r.arrival.driver.id,
        driverName: r.arrival.driver.fullName,
        phone: r.arrival.driver.user.phone,
        isVerified: r.arrival.driver.isVerified,
        ratingAvg: Number(r.arrival.driver.ratingAvg),
        ratingCount: r.arrival.driver.ratingCount,
        arrivedAt: r.arrival.arrivedAt,
        bodyTypeId: r.vehicle?.bodyTypeId ?? null,
        capacityTons: r.vehicle?.capacityTons ? Number(r.vehicle.capacityTons) : null,
        anyCountry: r.arrival.driver.anyCountry,
        directionCountryIds: r.directionCountryIds,
      }));
  }
}
