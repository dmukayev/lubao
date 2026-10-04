import { Injectable, NotFoundException } from '@nestjs/common';
import { Cargo, Company } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';

type CargoWithCompany = Cargo & { company: Company };

@Injectable()
export class CargosService {
  constructor(private readonly prisma: PrismaService) {}

  async toDto(cargo: CargoWithCompany) {
    const companyCompletedDeals = await this.prisma.deal.count({
      where: { companyId: cargo.companyId, status: 'DELIVERED' },
    });

    return {
      id: cargo.id,
      companyId: cargo.companyId,
      companyName: cargo.company.name,
      companyIsVerified: cargo.company.isVerified,
      companyRatingAvg: Number(cargo.company.ratingAvg),
      companyRatingCount: cargo.company.ratingCount,
      companyCompletedDeals,
      pointId: cargo.pointId,
      destinationCountryId: cargo.destinationCountryId,
      destinationCityId: cargo.destinationCityId,
      bodyTypeId: cargo.bodyTypeId,
      weightKg: cargo.weightKg ? Number(cargo.weightKg) : null,
      volumeM3: cargo.volumeM3 ? Number(cargo.volumeM3) : null,
      photoUrls: cargo.photoUrls,
      price: Number(cargo.price),
      currency: cargo.currency,
      readyDate: cargo.readyDate,
      description: cargo.description,
      status: cargo.status,
      publishedAt: cargo.publishedAt,
      expiresAt: cargo.expiresAt,
    };
  }

  async feed() {
    // company.isBlocked (задача 026, п.5) — груз блокированной компании не
    // трогаем (статус/история не меняются), просто скрываем из ленты
    // водителя, пока компанию не разблокируют.
    const cargos = await this.prisma.cargo.findMany({
      where: { status: 'PUBLISHED', company: { isBlocked: false } },
      include: { company: true },
      orderBy: { readyDate: 'asc' },
    });
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  async mine(companyId: string) {
    const cargos = await this.prisma.cargo.findMany({
      where: { companyId },
      include: { company: true },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(cargos.map((c) => this.toDto(c)));
  }

  async byId(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return this.toDto(cargo);
  }

  private async findEntity(id: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id }, include: { company: true } });
    if (!cargo) throw new NotFoundException('Cargo not found');
    return cargo;
  }

  async create(companyId: string, dto: CreateCargoDto) {
    const point = await this.prisma.point.findFirstOrThrow({ where: { isActive: true } });
    const readyDate = new Date(dto.readyDate);
    const expiresAt = new Date(readyDate.getTime() + 48 * 60 * 60 * 1000);

    const cargo = await this.prisma.cargo.create({
      data: {
        companyId,
        pointId: point.id,
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        photoUrls: dto.photoUrls ?? [],
        price: dto.price,
        currency: dto.currency,
        readyDate,
        description: dto.description,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        expiresAt,
      },
      include: { company: true },
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

  async update(companyId: string, id: string, dto: UpdateCargoDto) {
    const existing = await this.assertOwnedBy(id, companyId);

    const readyDate = dto.readyDate ? new Date(dto.readyDate) : existing.readyDate;
    const expiresAt =
      dto.readyDate != null ? new Date(readyDate.getTime() + 48 * 60 * 60 * 1000) : existing.expiresAt;

    const cargo = await this.prisma.cargo.update({
      where: { id },
      data: {
        destinationCountryId: dto.destinationCountryId,
        destinationCityId: dto.destinationCityId,
        bodyTypeId: dto.bodyTypeId,
        weightKg: dto.weightKg,
        volumeM3: dto.volumeM3,
        photoUrls: dto.photoUrls,
        price: dto.price,
        currency: dto.currency,
        readyDate,
        expiresAt,
        description: dto.description,
      },
      include: { company: true },
    });
    return this.toDto(cargo);
  }

  /// "Удаление" с точки зрения логиста — фактически мягкая отмена
  /// (status=CANCELLED), а не физическое удаление строки: на груз уже могут
  /// ссылаться отклики/сделки/contact-события, терять эту историю нельзя.
  async remove(companyId: string, id: string) {
    await this.assertOwnedBy(id, companyId);
    await this.prisma.cargo.update({ where: { id }, data: { status: 'CANCELLED' } });
  }
}
