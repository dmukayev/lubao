import { Injectable, NotFoundException } from '@nestjs/common';
import { Driver } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { CreateVerificationDocumentDto } from './dto/create-verification-document.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';

/// Задача 031, этап A, п.4 — проверка разделена: водитель «Проверен» по
/// селфи и правам (человек); техпаспорта тягача/прицепа теперь проверяют
/// конкретную машину (Vehicle.isVerified, см. admin.service.ts), а не
/// личность водителя. «Подтвердить сделку» дополнительно требует проверенную
/// связку машин (deals.service.ts).
export const REQUIRED_DRIVER_DOC_TYPES = ['SELFIE', 'DRIVER_LICENSE'] as const;

/// Обязательный документ для машины зависит от её вида — тягач и одиночка
/// (RIGID) показывают техпаспорт машины, прицеп — свой отдельный.
export function requiredVehicleDocType(kind: 'TRACTOR' | 'TRAILER' | 'RIGID'): 'VEHICLE_PASSPORT' | 'TRAILER_PASSPORT' {
  return kind === 'TRAILER' ? 'TRAILER_PASSPORT' : 'VEHICLE_PASSPORT';
}

@Injectable()
export class DriversService {
  constructor(private readonly prisma: PrismaService) {}

  private async verificationStatus(userId: string, isVerified: boolean): Promise<'NONE' | 'PENDING' | 'APPROVED'> {
    if (isVerified) return 'APPROVED';
    const anyDoc = await this.prisma.verificationDocument.findFirst({ where: { userId } });
    return anyDoc ? 'PENDING' : 'NONE';
  }

  async toDto(driver: Driver) {
    const [directions, permits, tractor, trailer, verificationStatus] = await Promise.all([
      this.prisma.driverDirection.findMany({ where: { driverId: driver.id } }),
      this.prisma.driverPermit.findMany({ where: { driverId: driver.id } }),
      this.prisma.vehicle.findFirst({ where: { driverId: driver.id, kind: { in: ['TRACTOR', 'RIGID'] }, isArchived: false }, orderBy: { createdAt: 'asc' } }),
      this.prisma.vehicle.findFirst({ where: { driverId: driver.id, kind: 'TRAILER', isArchived: false }, orderBy: { createdAt: 'asc' } }),
      this.verificationStatus(driver.userId, driver.isVerified),
    ]);
    // Задача 031 — Vehicle разделена на тягач+прицеп (гараж), но старый
    // контракт /drivers/me отдаёт одну объединённую «машину» (пока Stage B
    // не завёл в клиенте настоящий список гаража) — склеиваем здесь, чтобы
    // ничего в уже работающем Flutter-коде не ломать.
    const vehicle = tractor || trailer;

    return {
      id: driver.id,
      userId: driver.userId,
      fullName: driver.fullName,
      homeCityId: driver.homeCityId,
      anyCountry: driver.anyCountry,
      isVerified: driver.isVerified,
      verificationStatus,
      ratingAvg: Number(driver.ratingAvg),
      ratingCount: driver.ratingCount,
      location:
        driver.currentLat && driver.currentLng
          ? {
              lat: Number(driver.currentLat),
              lng: Number(driver.currentLng),
              updatedAt: driver.locationUpdatedAt,
            }
          : null,
      directionCountryIds: directions.map((d) => d.countryId),
      permitIds: permits.map((p) => p.permitId),
      vehicle: vehicle
        ? {
            id: vehicle.id,
            bodyTypeId: trailer?.bodyTypeId ?? tractor?.bodyTypeId ?? null,
            plateNumber: tractor?.plateNumber ?? null,
            brand: tractor?.brand ?? trailer?.brand ?? null,
            capacityTons: trailer?.capacityTons ? Number(trailer.capacityTons) : null,
          }
        : null,
    };
  }

  async getByUserId(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');
    return this.toDto(driver);
  }

  /// null, если у этого пользователя ещё нет анкеты водителя (например, сразу
  /// после подтверждения SMS-кода, до прохождения формы регистрации).
  async findByUserId(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    return driver ? this.toDto(driver) : null;
  }

  /// Одновременно и завершение быстрой регистрации (если анкеты ещё нет —
  /// создаёт её), и редактирование профиля в дальнейшем (если уже есть).
  async updateProfile(userId: string, input: UpdateDriverDto) {
    const city = await this.prisma.city.findUnique({ where: { id: input.homeCityId } });
    if (!city) throw new NotFoundException('City not found');

    const existing = await this.prisma.driver.findUnique({ where: { userId } });

    const driverId = await this.prisma.$transaction(async (tx) => {
      const driver = existing
        ? await tx.driver.update({
            where: { id: existing.id },
            data: { fullName: input.fullName, homeCityId: input.homeCityId, anyCountry: input.anyCountry },
          })
        : await tx.driver.create({
            data: {
              userId,
              fullName: input.fullName,
              homeCityId: input.homeCityId,
              anyCountry: input.anyCountry,
            },
          });

      await tx.driverDirection.deleteMany({ where: { driverId: driver.id } });
      if (!input.anyCountry && input.directionCountryIds.length > 0) {
        await tx.driverDirection.createMany({
          data: input.directionCountryIds.map((countryId) => ({ driverId: driver.id, countryId })),
        });
      }

      await tx.driverPermit.deleteMany({ where: { driverId: driver.id } });
      if (input.permitIds.length > 0) {
        await tx.driverPermit.createMany({
          data: input.permitIds.map((permitId) => ({ driverId: driver.id, permitId })),
        });
      }

      // Задача 031 — форма регистрации всё ещё редактирует «одну машину»
      // (настоящий гараж с несколькими тягачами/прицепами — Stage B), но
      // под капотом это теперь пара TRACTOR (госномер) + TRAILER (кузов/
      // тоннаж), как и у остальных водителей после миграции.
      const tractor = await tx.vehicle.findFirst({ where: { driverId: driver.id, kind: 'TRACTOR' } });
      if (tractor) {
        await tx.vehicle.update({ where: { id: tractor.id }, data: { plateNumber: input.plateNumber } });
      } else {
        await tx.vehicle.create({ data: { driverId: driver.id, kind: 'TRACTOR', plateNumber: input.plateNumber } });
      }

      const trailer = await tx.vehicle.findFirst({ where: { driverId: driver.id, kind: 'TRAILER' } });
      if (trailer) {
        await tx.vehicle.update({
          where: { id: trailer.id },
          data: { bodyTypeId: input.bodyTypeId, capacityTons: input.capacityTons },
        });
      } else {
        await tx.vehicle.create({
          data: { driverId: driver.id, kind: 'TRAILER', bodyTypeId: input.bodyTypeId, capacityTons: input.capacityTons },
        });
      }

      return driver.id;
    });

    const updated = await this.prisma.driver.findUniqueOrThrow({ where: { id: driverId } });
    return this.toDto(updated);
  }

  async submitVerificationDocument(userId: string, driverId: string, dto: CreateVerificationDocumentDto) {
    let vehicleId = dto.vehicleId ?? null;
    if (!vehicleId && (dto.type === 'VEHICLE_PASSPORT' || dto.type === 'TRAILER_PASSPORT')) {
      const vehicle = await this.prisma.vehicle.findFirst({
        where: { driverId, kind: dto.type === 'TRAILER_PASSPORT' ? 'TRAILER' : { in: ['TRACTOR', 'RIGID'] }, isArchived: false },
        orderBy: { createdAt: 'asc' },
      });
      vehicleId = vehicle?.id ?? null;
    }

    const doc = await this.prisma.verificationDocument.create({
      data: { userId, driverId, vehicleId, type: dto.type, fileUrl: dto.fileUrl, status: 'PENDING' },
    });
    return this.docToDto(doc);
  }

  async listVerificationDocuments(driverId: string) {
    const docs = await this.prisma.verificationDocument.findMany({
      where: { driverId },
      orderBy: { createdAt: 'desc' },
    });
    return docs.map((d) => this.docToDto(d));
  }

  private docToDto(doc: {
    id: string;
    type: string;
    fileUrl: string;
    status: string;
    rejectReason: string | null;
    createdAt: Date;
  }) {
    return {
      id: doc.id,
      type: doc.type,
      fileUrl: doc.fileUrl,
      status: doc.status,
      rejectReason: doc.rejectReason,
      createdAt: doc.createdAt,
    };
  }

  async updateLocation(userId: string, lat: number, lng: number) {
    const existing = await this.prisma.driver.findUnique({ where: { userId } });
    if (!existing) throw new NotFoundException('Driver profile not found');

    const updated = await this.prisma.driver.update({
      where: { id: existing.id },
      data: { currentLat: lat, currentLng: lng, locationUpdatedAt: new Date() },
    });
    return this.toDto(updated);
  }

  // -- Гараж (задача 031, этап B, макет 26) --------------------------------

  private vehicleToDto(v: {
    id: string;
    kind: string;
    bodyTypeId: string | null;
    plateNumber: string | null;
    vin: string | null;
    brand: string | null;
    capacityTons: unknown;
    lengthM: unknown;
    isOwner: boolean;
    isVerified: boolean;
    isArchived: boolean;
    createdAt: Date;
  }) {
    return {
      id: v.id,
      kind: v.kind,
      bodyTypeId: v.bodyTypeId,
      plateNumber: v.plateNumber,
      vin: v.vin,
      brand: v.brand,
      capacityTons: v.capacityTons != null ? Number(v.capacityTons) : null,
      lengthM: v.lengthM != null ? Number(v.lengthM) : null,
      isOwner: v.isOwner,
      isVerified: v.isVerified,
      isArchived: v.isArchived,
      createdAt: v.createdAt,
    };
  }

  async listVehicles(driverId: string) {
    const vehicles = await this.prisma.vehicle.findMany({
      where: { driverId, isArchived: false },
      orderBy: { createdAt: 'asc' },
    });
    return vehicles.map((v) => this.vehicleToDto(v));
  }

  async createVehicle(driverId: string, dto: CreateVehicleDto) {
    const vehicle = await this.prisma.vehicle.create({
      data: {
        driverId,
        kind: dto.kind,
        bodyTypeId: dto.kind === 'TRACTOR' ? null : dto.bodyTypeId,
        plateNumber: dto.plateNumber,
        vin: dto.vin,
        brand: dto.brand,
        capacityTons: dto.kind === 'TRACTOR' ? null : dto.capacityTons,
        lengthM: dto.kind === 'TRACTOR' ? null : dto.lengthM,
      },
    });
    return this.vehicleToDto(vehicle);
  }

  /// В архив, не удалить (п.10) — история сделок, где машина уже
  /// участвовала, не должна потерять ссылку.
  async archiveVehicle(driverId: string, vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle || vehicle.driverId !== driverId) throw new NotFoundException('Vehicle not found');

    const updated = await this.prisma.vehicle.update({ where: { id: vehicleId }, data: { isArchived: true } });
    return this.vehicleToDto(updated);
  }
}
