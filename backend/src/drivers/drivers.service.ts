import { Injectable, NotFoundException } from '@nestjs/common';
import { Driver } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVerificationDocumentDto } from './dto/create-verification-document.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';

/// 4 обязательных документа для подтверждения личности водителя: селфи,
/// техпаспорта тягача и прицепа, права. Без всех четырёх — водитель не
/// верифицирован, даже если часть уже одобрена (см. admin.service.ts).
export const REQUIRED_DRIVER_DOC_TYPES = ['SELFIE', 'VEHICLE_PASSPORT', 'TRAILER_PASSPORT', 'DRIVER_LICENSE'] as const;

@Injectable()
export class DriversService {
  constructor(private readonly prisma: PrismaService) {}

  private async verificationStatus(userId: string, isVerified: boolean): Promise<'NONE' | 'PENDING' | 'APPROVED'> {
    if (isVerified) return 'APPROVED';
    const anyDoc = await this.prisma.verificationDocument.findFirst({ where: { userId } });
    return anyDoc ? 'PENDING' : 'NONE';
  }

  async toDto(driver: Driver) {
    const [directions, permits, vehicle, verificationStatus] = await Promise.all([
      this.prisma.driverDirection.findMany({ where: { driverId: driver.id } }),
      this.prisma.driverPermit.findMany({ where: { driverId: driver.id } }),
      this.prisma.vehicle.findFirst({ where: { driverId: driver.id }, orderBy: { createdAt: 'asc' } }),
      this.verificationStatus(driver.userId, driver.isVerified),
    ]);

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
            bodyTypeId: vehicle.bodyTypeId,
            plateNumber: vehicle.plateNumber,
            brand: vehicle.brand,
            capacityTons: vehicle.capacityTons ? Number(vehicle.capacityTons) : null,
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

      const vehicle = await tx.vehicle.findFirst({ where: { driverId: driver.id } });
      if (vehicle) {
        await tx.vehicle.update({
          where: { id: vehicle.id },
          data: { bodyTypeId: input.bodyTypeId, plateNumber: input.plateNumber, capacityTons: input.capacityTons },
        });
      } else {
        await tx.vehicle.create({
          data: {
            driverId: driver.id,
            bodyTypeId: input.bodyTypeId,
            plateNumber: input.plateNumber,
            capacityTons: input.capacityTons,
          },
        });
      }

      return driver.id;
    });

    const updated = await this.prisma.driver.findUniqueOrThrow({ where: { id: driverId } });
    return this.toDto(updated);
  }

  async submitVerificationDocument(userId: string, driverId: string, dto: CreateVerificationDocumentDto) {
    const doc = await this.prisma.verificationDocument.create({
      data: { userId, driverId, type: dto.type, fileUrl: dto.fileUrl, status: 'PENDING' },
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
}
