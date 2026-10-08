import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Driver, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { leaveTerminalIfOutside } from '../arrivals/arrival-lifecycle';
import { IdentifiersService } from '../identifiers/identifiers.service';
import { RecognitionService } from '../recognition/recognition.service';
import { UploadsService } from '../uploads/uploads.service';
import { calculatePalletsEuro, calculateVolumeM3 } from './body-size';
import { CreateVehicleDto, SetVehicleSizeDto } from './dto/create-vehicle.dto';
import { CreateVerificationDocumentDto } from './dto/create-verification-document.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';
import { bodyFields, validateSpecs } from '../body-types/specs';

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
  constructor(
    private readonly prisma: PrismaService,
    private readonly identifiers?: IdentifiersService,
    private readonly recognition?: RecognitionService,
    private readonly uploads?: UploadsService,
  ) {}

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
      directionRegionIds: directions.flatMap((d) => d.regionIds),
      licenseFullName: driver.licenseFullName && driver.licenseFullName !== driver.fullName ? driver.licenseFullName : null,
      permitIds: permits.map((p) => p.permitId),
      preferredBodyTypeId: driver.preferredBodyTypeId,
      preferredCapacityTons: driver.preferredCapacityTons != null ? Number(driver.preferredCapacityTons) : null,
      preferredSpecs: driver.preferredSpecs ?? null,
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
        // 045 п.7: области — только внутри выбранных стран; чужие молча отбрасываем.
        const regions = input.directionRegionIds?.length
          ? await tx.region.findMany({ where: { id: { in: input.directionRegionIds } }, select: { id: true, countryId: true } })
          : [];
        await tx.driverDirection.createMany({
          data: input.directionCountryIds.map((countryId) => ({
            driverId: driver.id,
            countryId,
            regionIds: regions.filter((r) => r.countryId === countryId).map((r) => r.id),
          })),
        });
      }

      await tx.driverPermit.deleteMany({ where: { driverId: driver.id } });
      if (input.permitIds.length > 0) {
        await tx.driverPermit.createMany({
          data: input.permitIds.map((permitId) => ({ driverId: driver.id, permitId })),
        });
      }

      // 045 п.5: машины при регистрации НЕ создаются — заглушки «Тягач/Прицеп»
      // без номера и документов только путали. Кузов и тоннаж из мастера —
      // предпочтение водителя (лента, «Кто свободен»), пока нет настоящей машины.
      if (!existing && !input.bodyTypeId) throw new BadRequestException('bodyTypeId is required for registration');
      if (input.bodyTypeId !== undefined || input.capacityTons !== undefined || input.preferredSpecs !== undefined) {
        // 048 п.7: тоннаж — только если он поле профиля (у автовоза и
        // контейнеровоза его нет); остальная «основа» — в preferredSpecs.
        const bodyTypeId = input.bodyTypeId ?? driver.preferredBodyTypeId;
        const bodyType = bodyTypeId ? await tx.bodyType.findUnique({ where: { id: bodyTypeId }, select: { fields: true } }) : null;
        const fields = bodyFields(bodyType?.fields);
        const hasCapacity = fields.length === 0 || fields.some((f) => f.key === 'capacityTons');
        const specs = fields.length ? validateSpecs(fields, { capacityTons: input.capacityTons, ...(input.preferredSpecs ?? {}) }, 'preferred') : {};
        const capacity = typeof specs.capacityTons === 'number' ? specs.capacityTons : input.capacityTons;
        await tx.driver.update({
          where: { id: driver.id },
          data: {
            ...(input.bodyTypeId !== undefined ? { preferredBodyTypeId: input.bodyTypeId } : {}),
            preferredCapacityTons: hasCapacity ? (capacity ?? null) : null,
            preferredSpecs: Object.keys(specs).length ? specs : Prisma.JsonNull,
          },
        });
      }

      return driver.id;
    });

    // Задача 031, этап C, п.15 — проверка при регистрации: новый профиль
    // водителя с телефоном из чёрного списка сразу получает подтверждённый
    // идентификатор, который дальнейшие проверки (см. admin.service.ts
    // reviewVerificationDocument) уже видят как ⛔ — регистрацию саму не
    // блокируем (решение 2026-10-05), просто не даём её потом тихо одобрить.
    if (!existing && this.identifiers) {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (user?.phone) {
        await this.identifiers.confirmIdentifier({
          type: 'PHONE',
          rawValue: user.phone,
          ownerType: 'DRIVER',
          ownerId: driverId,
          confirmedByUserId: userId,
        });
      }
      await this.applyPhoneBlacklist(userId);
    }

    const updated = await this.prisma.driver.findUniqueOrThrow({ where: { id: driverId } });
    return this.toDto(updated);
  }

  /// «Да, это я» на ФИО из прав (045 п.10): подставляем в профиль.
  async acceptLicenseName(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new NotFoundException('Driver profile not found');
    if (!driver.licenseFullName) throw new BadRequestException({ code: 'NO_LICENSE_NAME', message: 'No full name from the licence yet' });
    const updated = await this.prisma.driver.update({ where: { id: driver.id }, data: { fullName: driver.licenseFullName } });
    return this.toDto(updated);
  }

  /// Задача 039, п.2 (032 п.11) — телефон водителя сверяется с чёрным
  /// списком при КАЖДОМ входе по SMS и при регистрации: совпал → у профиля
  /// гарантированно есть подтверждённый PHONE-идентификатор (его видит
  /// «Требует внимания» и проверка ⛔) и снят «Проверен» — без него
  /// откликаться и подтверждать перевозку нельзя (гейт DRIVER_NOT_VERIFIED).
  /// Вход сам не блокируем (решение 2026-10-05): аккаунт не теряет доступ к
  /// просмотру, но не может действовать, пока админ не решит иначе.
  async applyPhoneBlacklist(userId: string): Promise<boolean> {
    if (!this.identifiers) return false;
    const driver = await this.prisma.driver.findUnique({ where: { userId }, include: { user: { select: { phone: true } } } });
    const phone = driver?.user.phone;
    if (!driver || !phone) return false;

    const match = await this.identifiers.checkMatches('PHONE', phone, { ownerType: 'DRIVER', ownerId: driver.id });
    if (!match.blocked) return false;

    await this.identifiers.confirmIdentifier({ type: 'PHONE', rawValue: phone, ownerType: 'DRIVER', ownerId: driver.id, confirmedByUserId: userId });
    if (driver.isVerified) await this.prisma.driver.update({ where: { id: driver.id }, data: { isVerified: false } });
    return true;
  }

  async submitVerificationDocument(userId: string, driverId: string, dto: CreateVerificationDocumentDto) {
    // Задача 032, п.1 — fileUrl раньше принимался как произвольная строка
    // и шёл в OCR как URL (SSRF во внутреннюю сеть докера). Теперь это
    // строго ключ из нашего же POST /uploads/document, загруженный этим
    // же пользователем.
    if (this.uploads && !(await this.uploads.verifyDocumentOwnership(dto.fileUrl, userId))) {
      throw new BadRequestException('fileUrl must be a key returned by POST /uploads/document for this user');
    }

    // Задача 032, п.12 (038) — vehicleId из запроса раньше принимался на
    // веру: техпаспорт можно было прицепить к ЧУЖОЙ машине, и её одобрение
    // верифицировало чужой транспорт.
    let vehicleId = dto.vehicleId ?? null;
    if (vehicleId) {
      const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId }, select: { driverId: true, isArchived: true, kind: true } });
      if (!vehicle || vehicle.driverId !== driverId) {
        throw new BadRequestException('vehicleId does not belong to this driver');
      }
      // 039, п.5: не к архивной машине и тип документа = тип машины.
      if (vehicle.isArchived) throw new BadRequestException('vehicle is archived');
      if (requiredVehicleDocType(vehicle.kind) !== dto.type && (dto.type === 'VEHICLE_PASSPORT' || dto.type === 'TRAILER_PASSPORT')) {
        throw new BadRequestException(`document type ${dto.type} does not match vehicle kind ${vehicle.kind}`);
      }
    }
    if (!vehicleId && (dto.type === 'VEHICLE_PASSPORT' || dto.type === 'TRAILER_PASSPORT')) {
      const vehicle = await this.prisma.vehicle.findFirst({
        where: { driverId, kind: dto.type === 'TRAILER_PASSPORT' ? 'TRAILER' : { in: ['TRACTOR', 'RIGID'] }, isArchived: false },
        orderBy: { createdAt: 'asc' },
      });
      vehicleId = vehicle?.id ?? null;
    }

    // Фото машины (044 п.7): только к своей машине, на проверку не идут и не
    // распознаются; новое фото того же ракурса заменяет старое (файл удаляется).
    if (dto.type === 'VEHICLE_PHOTO_FRONT' || dto.type === 'VEHICLE_PHOTO_SIDE') {
      if (!vehicleId) throw new BadRequestException('vehicleId is required for a vehicle photo');
      const previous = await this.prisma.verificationDocument.findMany({ where: { vehicleId, type: dto.type }, select: { id: true, fileUrl: true } });
      const photo = await this.prisma.$transaction(async (tx) => {
        if (previous.length) await tx.verificationDocument.deleteMany({ where: { id: { in: previous.map((p) => p.id) } } });
        return tx.verificationDocument.create({ data: { userId, driverId, vehicleId, type: dto.type, fileUrl: dto.fileUrl, status: 'APPROVED' } });
      });
      for (const p of previous) await this.uploads?.removeDocument(p.fileUrl).catch(() => undefined);
      return this.docToDto(photo);
    }

    const doc = await this.prisma.verificationDocument.create({
      data: { userId, driverId, vehicleId, type: dto.type, fileUrl: dto.fileUrl, status: 'PENDING' },
    });
    await this.recognition?.enqueue(doc.id);
    return this.docToDto(doc);
  }

  async listVerificationDocuments(driverId: string) {
    const docs = await this.prisma.verificationDocument.findMany({
      // Фото машины (044 п.7) — не документы проверки, у них свой показ в гараже.
      where: { driverId, type: { notIn: ['VEHICLE_PHOTO_FRONT', 'VEHICLE_PHOTO_SIDE'] } },
      orderBy: { createdAt: 'desc' },
    });
    return docs.map((d) => this.docToDto(d));
  }

  /// Блок «Распознано» на мобильной проверке (задача 031, п.25) — только
  /// значения/уверенность, БЕЗ сверки с чёрным списком/дублями (это знание
  /// админа о других владельцах, не для самопроверки водителем).
  async documentRecognition(driverId: string, documentId: string) {
    const doc = await this.prisma.verificationDocument.findUnique({
      where: { id: documentId },
      include: { recognition: true },
    });
    if (!doc || doc.driverId !== driverId) throw new NotFoundException('Document not found');
    if (!doc.recognition) return { status: 'PENDING' as const, fields: {} };

    // ИИН/номер прав хранятся как valueMasked + valueEncrypted (задача 032):
    // водителю — маска, шифртекст наружу не отдаём (и клиенту нужен `value`).
    const raw = (doc.recognition.fields ?? {}) as Record<
      string,
      { value?: string; valueMasked?: string; confidence: number; checksumOk: boolean | null; needsReview: boolean }
    >;
    const fields: Record<string, unknown> = {};
    for (const [key, f] of Object.entries(raw)) {
      fields[key] = { value: f.value ?? f.valueMasked ?? '', confidence: f.confidence, checksumOk: f.checksumOk, needsReview: f.needsReview };
    }
    return { status: doc.recognition.status, fields };
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
    // Терминал с геозоной: вышел за радиус — анонс «на месте» гаснет (040, п.4).
    await leaveTerminalIfOutside(this.prisma, existing.id, { lat, lng });
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
    sizePresetId?: string | null;
    innerLengthM?: unknown;
    innerWidthM?: unknown;
    innerHeightM?: unknown;
    volumeM3?: unknown;
    palletsEuro?: number | null;
    specs?: unknown;
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
      sizePresetId: v.sizePresetId ?? null,
      innerLengthM: v.innerLengthM != null ? Number(v.innerLengthM) : null,
      innerWidthM: v.innerWidthM != null ? Number(v.innerWidthM) : null,
      innerHeightM: v.innerHeightM != null ? Number(v.innerHeightM) : null,
      volumeM3: v.volumeM3 != null ? Number(v.volumeM3) : null,
      palletsEuro: v.palletsEuro ?? null,
      specs: v.specs ?? null,
      isOwner: v.isOwner,
      isVerified: v.isVerified,
      isArchived: v.isArchived,
      createdAt: v.createdAt,
    };
  }

  /// Задача 033, п.3 — поля размера для записи в Vehicle: шаблон КОПИРУЕТСЯ
  /// (правка шаблона в админке не меняет задним числом чужие машины), «свой
  /// размер» — объём и паллеты считаются из Д/Ш/В.
  /// 048: specs машины по профилю её кузова + проекция в колонки 033/037 у
  /// объёмных (у остальных объём/паллеты/размер не хранятся).
  private async vehicleBodyData(dto: CreateVehicleDto, sizeFields: Record<string, unknown>) {
    const bodyType = dto.bodyTypeId ? await this.prisma.bodyType.findUnique({ where: { id: dto.bodyTypeId }, select: { profile: true, fields: true } }) : null;
    const num = (v: unknown) => (v == null ? undefined : Number(v));
    const legacy: Record<string, unknown> = {
      capacityTons: dto.capacityTons,
      volumeM3: num(sizeFields.volumeM3),
      palletsEuro: num(sizeFields.palletsEuro),
      innerLengthM: num(sizeFields.innerLengthM),
      innerWidthM: num(sizeFields.innerWidthM),
      innerHeightM: num(sizeFields.innerHeightM),
    };
    const fields = bodyFields(bodyType?.fields);
    if (!bodyType || fields.length === 0) {
      // Тип без полей (новый из админки) — как раньше, колонками.
      return { capacityTons: dto.capacityTons ?? null, ...sizeFields };
    }
    const specs = validateSpecs(fields, { ...legacy, ...(dto.specs ?? {}) }, 'vehicle');
    const capacityTons = typeof specs.capacityTons === 'number' ? specs.capacityTons : null;
    if (bodyType.profile !== 'VOLUME') {
      return { specs, capacityTons, volumeM3: null, palletsEuro: null, innerLengthM: null, innerWidthM: null, innerHeightM: null, sizePresetId: null };
    }
    return {
      specs,
      capacityTons,
      sizePresetId: (sizeFields.sizePresetId as string | null | undefined) ?? null,
      volumeM3: (specs.volumeM3 as number | undefined) ?? null,
      palletsEuro: (specs.palletsEuro as number | undefined) ?? null,
      innerLengthM: (specs.innerLengthM as number | undefined) ?? null,
      innerWidthM: (specs.innerWidthM as number | undefined) ?? null,
      innerHeightM: (specs.innerHeightM as number | undefined) ?? null,
    };
  }

  private async resolveSizeFields(dto: { sizePresetId?: string; innerLengthM?: number; innerWidthM?: number; innerHeightM?: number }) {
    if (dto.sizePresetId) {
      const preset = await this.prisma.bodySizePreset.findUnique({ where: { id: dto.sizePresetId } });
      if (!preset || !preset.isActive) throw new NotFoundException('Size preset not found');
      return {
        sizePresetId: preset.id,
        innerLengthM: preset.innerLengthM,
        innerWidthM: preset.innerWidthM,
        innerHeightM: preset.innerHeightM,
        volumeM3: preset.volumeM3,
        palletsEuro: preset.palletsEuro,
      };
    }
    if (dto.innerLengthM != null && dto.innerWidthM != null && dto.innerHeightM != null) {
      return {
        sizePresetId: null,
        innerLengthM: dto.innerLengthM,
        innerWidthM: dto.innerWidthM,
        innerHeightM: dto.innerHeightM,
        volumeM3: calculateVolumeM3(dto.innerLengthM, dto.innerWidthM, dto.innerHeightM),
        palletsEuro: calculatePalletsEuro(dto.innerLengthM, dto.innerWidthM),
      };
    }
    return {};
  }

  async listVehicles(driverId: string) {
    const vehicles = await this.prisma.vehicle.findMany({
      where: { driverId, isArchived: false },
      orderBy: { createdAt: 'asc' },
    });
    // «Нужен документ» (041, п.6): машина без загруженного техпаспорта
    // (создана мастером регистрации) — в гараже у неё кнопка «Добавить документ».
    const withDocs = vehicles.length
      ? await this.prisma.verificationDocument.findMany({
          where: { vehicleId: { in: vehicles.map((v) => v.id) }, status: { in: ['PENDING', 'APPROVED'] } },
          select: { vehicleId: true, type: true },
        })
      : [];
    // «Нужен документ» — только техпаспорт; фото машины (044 п.7) — отдельные признаки.
    const has = (vehicleId: string, types: string[]) => withDocs.some((d) => d.vehicleId === vehicleId && types.includes(d.type));
    return vehicles.map((v) => ({
      ...this.vehicleToDto(v),
      hasDocument: has(v.id, ['VEHICLE_PASSPORT', 'TRAILER_PASSPORT']),
      hasPhotoFront: has(v.id, ['VEHICLE_PHOTO_FRONT']),
      hasPhotoSide: has(v.id, ['VEHICLE_PHOTO_SIDE']),
    }));
  }

  async createVehicle(userId: string, driverId: string, dto: CreateVehicleDto) {
    // Задача 032, п.12 (038) — файл техпаспорта проверяется ДО создания
    // машины (тот же гейт, что у submitVerificationDocument), а машина и
    // документ создаются одной транзакцией: никакой машины-сироты, если
    // клиент упал между «создать машину» и «приложить документ».
    if (dto.documentFileUrl && this.uploads && !(await this.uploads.verifyDocumentOwnership(dto.documentFileUrl, userId))) {
      throw new BadRequestException('documentFileUrl must be a key returned by POST /uploads/document for this user');
    }

    const sizeFields = dto.kind === 'TRACTOR' ? {} : await this.resolveSizeFields(dto);
    const body = dto.kind === 'TRACTOR' ? null : await this.vehicleBodyData(dto, sizeFields);
    const { vehicle, document } = await this.prisma.$transaction(async (tx) => {
      const vehicle = await tx.vehicle.create({
        data: {
          driverId,
          kind: dto.kind,
          bodyTypeId: dto.kind === 'TRACTOR' ? null : dto.bodyTypeId,
          plateNumber: dto.plateNumber,
          vin: dto.vin,
          brand: dto.brand,
          lengthM: dto.kind === 'TRACTOR' ? null : dto.lengthM,
          ...(body ?? { capacityTons: null }),
        },
      });
      const document = dto.documentFileUrl
        ? await tx.verificationDocument.create({
            data: {
              userId,
              driverId,
              vehicleId: vehicle.id,
              type: dto.kind === 'TRAILER' ? 'TRAILER_PASSPORT' : 'VEHICLE_PASSPORT',
              fileUrl: dto.documentFileUrl,
              status: 'PENDING',
            },
          })
        : null;
      return { vehicle, document };
    });
    if (document) await this.recognition?.enqueue(document.id);
    return this.vehicleToDto(vehicle);
  }

  /// Задача 033, п.5/6 — размер кузова существующей машины (у машин,
  /// созданных до 033, его нет — водитель выбирает при следующем открытии
  /// гаража). Только TRAILER/RIGID.
  async setVehicleSize(driverId: string, vehicleId: string, dto: SetVehicleSizeDto) {
    const vehicle = await this.prisma.vehicle.findUnique({ where: { id: vehicleId } });
    if (!vehicle || vehicle.driverId !== driverId) throw new NotFoundException('Vehicle not found');
    if (vehicle.kind === 'TRACTOR') throw new BadRequestException('A tractor unit has no cargo body size');

    const sizeFields = await this.resolveSizeFields(dto);
    if (Object.keys(sizeFields).length === 0) throw new BadRequestException('Either sizePresetId or all of innerLengthM/innerWidthM/innerHeightM are required');

    const updated = await this.prisma.vehicle.update({ where: { id: vehicleId }, data: sizeFields });
    return this.vehicleToDto(updated);
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
