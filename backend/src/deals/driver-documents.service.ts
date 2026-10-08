import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DealStatus, VerificationDocType, VerificationDocument } from '@prisma/client';
import { RequestContext } from '../common/request-context';
import { decryptIdentifier } from '../identifiers/crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import { randomBytes } from 'crypto';
import { RedisService } from '../redis/redis.service';
import { I18nName, pickLocaleText } from '../notifications/notification-events';
import { PdfImage, buildDriverDocumentsPdf } from './driver-documents.pdf';

/// Пакет открыт, пока сделка обоюдная (водитель подтвердил) и ещё 30 дней после доставки.
const OPEN_STATUSES: DealStatus[] = ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'CANCEL_REQUESTED', 'DISPUTED', 'DELIVERED'];
export const DOCS_AFTER_DELIVERY_MS = 30 * 24 * 60 * 60 * 1000;
const PDF_LINK_TTL_SECONDS = 5 * 60;

const PERSON_DOC_TYPES: VerificationDocType[] = ['SELFIE', 'DRIVER_LICENSE', 'IDENTITY'];
const VEHICLE_DOC_TYPES: VerificationDocType[] = ['VEHICLE_PASSPORT', 'TRAILER_PASSPORT', 'VEHICLE_PHOTO_FRONT', 'VEHICLE_PHOTO_SIDE'];

export type DocsAuditAction = 'DRIVER_DOCS_VIEWED' | 'DRIVER_DOCS_DOWNLOADED';

/// Документы водителя логисту по обоюдной сделке (044, decisions.md
/// 2026-10-07): только сотрудникам компании-владельца груза, только после
/// «Подтверждаю перевозку», до доставки + 30 дней; каждое открытие и
/// скачивание — в audit_log, водитель видит, когда логист их открыл.
@Injectable()
export class DriverDocumentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: UploadsService,
    private readonly redis: RedisService,
  ) {}

  /// Одноразовая ссылка на PDF (044 п.2): приложение открывает её в браузере/
  /// системном просмотрщике без своих заголовков авторизации — так одинаково на
  /// вебе, iOS и Android. Живёт 5 минут, срабатывает один раз; права проверяются
  /// и при выдаче ссылки, и при скачивании.
  async createPdfLink(dealId: string, ctx: RequestContext): Promise<{ token: string; expiresInSeconds: number }> {
    await this.accessibleDeal(dealId, ctx);
    const token = randomBytes(24).toString('base64url');
    await this.redis.client.set(`docs-pdf:${token}`, JSON.stringify({ dealId, userId: ctx.user.id }), 'EX', PDF_LINK_TTL_SECONDS);
    return { token, expiresInSeconds: PDF_LINK_TTL_SECONDS };
  }

  /// Контекст по одноразовой ссылке — тот же, что у вошедшего логиста.
  async consumePdfLink(dealId: string, token: string): Promise<RequestContext> {
    const key = `docs-pdf:${token}`;
    const raw = await this.redis.client.get(key);
    if (!raw) throw new ForbiddenException({ code: 'LINK_EXPIRED', message: 'Download link expired' });
    await this.redis.client.del(key);
    const { dealId: linkDeal, userId } = JSON.parse(raw) as { dealId: string; userId: string };
    if (linkDeal !== dealId) throw new ForbiddenException({ code: 'LINK_EXPIRED', message: 'Download link expired' });
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const companyMember = await this.prisma.companyMember.findUnique({ where: { userId }, include: { company: true } });
    if (!user || !user.isActive || user.isBlocked) throw new ForbiddenException({ code: 'LINK_EXPIRED', message: 'Download link expired' });
    return { user, driver: null, companyMember, sessionId: 'pdf-link' };
  }

  async accessibleDeal(dealId: string, ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException({ code: 'COMPANY_ONLY', message: 'Only the cargo company sees driver documents' });
    const deal = await this.prisma.deal.findUnique({
      where: { id: dealId },
      include: {
        driver: { select: { id: true, fullName: true, isVerified: true } },
        company: { select: { name: true } },
        cargo: { select: { pointId: true, destinationCityId: true, destinationCountryId: true, readyDate: true } },
      },
    });
    if (!deal) throw new NotFoundException('Deal not found');
    if (deal.companyId !== ctx.companyMember.companyId) throw new ForbiddenException({ code: 'NOT_YOUR_DEAL', message: 'Not your deal' });
    if (!OPEN_STATUSES.includes(deal.status)) {
      throw new ForbiddenException({ code: 'DOCS_NOT_YET', message: 'Documents open after the driver confirms the haul' });
    }
    if (deal.status === 'DELIVERED' && deal.deliveredAt && Date.now() - deal.deliveredAt.getTime() > DOCS_AFTER_DELIVERY_MS) {
      throw new ForbiddenException({ code: 'DOCS_EXPIRED', message: 'Documents are closed 30 days after delivery' });
    }
    return deal;
  }

  async package(dealId: string, ctx: RequestContext, action: DocsAuditAction = 'DRIVER_DOCS_VIEWED') {
    const deal = await this.accessibleDeal(dealId, ctx);
    const vehicleIds = [deal.tractorId, deal.trailerId].filter((id): id is string => !!id);
    const [personDocs, vehicles, vehicleDocs, identifiers] = await Promise.all([
      this.prisma.verificationDocument.findMany({
        where: { driverId: deal.driverId, type: { in: PERSON_DOC_TYPES }, status: { not: 'REJECTED' } },
        orderBy: { createdAt: 'desc' },
        include: { recognition: { select: { fields: true } } },
      }),
      this.prisma.vehicle.findMany({ where: { id: { in: vehicleIds } } }),
      this.prisma.verificationDocument.findMany({
        where: { vehicleId: { in: vehicleIds }, type: { in: VEHICLE_DOC_TYPES }, status: { not: 'REJECTED' } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.identifier.findMany({
        where: { ownerType: 'DRIVER', ownerId: deal.driverId, type: { in: ['IIN', 'DRIVER_LICENSE_NO'] } },
        select: { type: true, valueEncrypted: true, valueMasked: true },
      }),
    ]);
    const latest = <T extends Pick<VerificationDocument, 'type' | 'status'>>(docs: T[], type: VerificationDocType) =>
      docs.find((d) => d.type === type && d.status === 'APPROVED') ?? docs.find((d) => d.type === type) ?? null;
    const reveal = (type: 'IIN' | 'DRIVER_LICENSE_NO') => {
      const row = identifiers.find((i) => i.type === type);
      if (!row) return null;
      return row.valueEncrypted ? decryptIdentifier(row.valueEncrypted) : row.valueMasked;
    };
    const license = latest(personDocs, 'DRIVER_LICENSE');
    const licenseFields = (license?.recognition?.fields ?? {}) as Record<string, { value?: string } | undefined>;

    await this.prisma.auditLog.create({
      data: { actorUserId: ctx.user.id, action, entityType: 'Deal', entityId: dealId, metadata: { driverId: deal.driverId, companyId: deal.companyId } },
    });

    const ref = (doc: Pick<VerificationDocument, 'id' | 'status'> | null) => (doc ? { id: doc.id, status: doc.status } : null);
    // Тягач первым, прицеп вторым — как в связке сделки.
    const ordered = vehicleIds.map((id) => vehicles.find((v) => v.id === id)).filter((v): v is NonNullable<typeof v> => !!v);
    return {
      dealId,
      driver: { id: deal.driver.id, fullName: deal.driver.fullName, isVerified: deal.driver.isVerified, iin: reveal('IIN') },
      selfie: ref(latest(personDocs, 'SELFIE')),
      identity: ref(latest(personDocs, 'IDENTITY')),
      license: { number: reveal('DRIVER_LICENSE_NO'), expiryDate: licenseFields.expiryDate?.value ?? null, document: ref(license) },
      vehicles: ordered.map((v) => ({
        id: v.id,
        kind: v.kind,
        plateNumber: v.plateNumber,
        vin: v.vin,
        brand: v.brand,
        bodyTypeId: v.bodyTypeId,
        specs: v.specs ?? null,
        isVerified: v.isVerified,
        passport: ref(latest(vehicleDocs.filter((d) => d.vehicleId === v.id), v.kind === 'TRAILER' ? 'TRAILER_PASSPORT' : 'VEHICLE_PASSPORT')),
        // 044 п.7: фото машины — «Фото нет», если водитель не добавил.
        photoFront: ref(latest(vehicleDocs.filter((d) => d.vehicleId === v.id), 'VEHICLE_PHOTO_FRONT')),
        photoSide: ref(latest(vehicleDocs.filter((d) => d.vehicleId === v.id), 'VEHICLE_PHOTO_SIDE')),
      })),
      cargo: { pointId: deal.cargo.pointId, destinationCityId: deal.cargo.destinationCityId, destinationCountryId: deal.cargo.destinationCountryId, readyDate: deal.cargo.readyDate },
      companyName: deal.company.name,
      issuedTo: ctx.companyMember?.fullName ?? ctx.user.name ?? ctx.user.email,
      issuedAt: new Date(),
    };
  }

  /// Один PDF «Документы на рейс» (044 п.1) — каждое скачивание в журнал.
  async pdf(dealId: string, ctx: RequestContext): Promise<{ buffer: Buffer; filename: string }> {
    const pkg = await this.package(dealId, ctx, 'DRIVER_DOCS_DOWNLOADED');
    const locale = ctx.user.locale;
    const [point, destination] = await Promise.all([
      this.prisma.point.findUnique({ where: { id: pkg.cargo.pointId }, select: { name: true } }),
      pkg.cargo.destinationCityId ? this.prisma.city.findUnique({ where: { id: pkg.cargo.destinationCityId }, select: { name: true } }) : null,
    ]);
    const name = (json: unknown) => (json ? pickLocaleText(json as I18nName, locale) : '…');
    const ids = [pkg.selfie?.id, pkg.identity?.id, pkg.license.document?.id, ...pkg.vehicles.flatMap((v) => [v.passport?.id, v.photoFront?.id, v.photoSide?.id])].filter((id): id is string => !!id);
    const docs = await this.prisma.verificationDocument.findMany({ where: { id: { in: ids } }, select: { id: true, fileUrl: true } });
    const images = new Map<string, PdfImage>();
    for (const d of docs) {
      try {
        images.set(
          d.id,
          /^https?:\/\//.test(d.fileUrl)
            ? await fetch(d.fileUrl).then(async (r) => ({ buffer: Buffer.from(await r.arrayBuffer()), contentType: r.headers.get('content-type') || 'image/jpeg' }))
            : await this.uploads.getDocumentBuffer(d.fileUrl),
        );
      } catch {
        // Файла нет в хранилище — страница будет «Фото нет», PDF всё равно выдаём.
      }
    }
    const buffer = await buildDriverDocumentsPdf({
      locale,
      route: `${name(point?.name)} → ${name(destination?.name)}`,
      readyDate: pkg.cargo.readyDate ? pkg.cargo.readyDate.toISOString().slice(0, 10) : null,
      driver: { fullName: pkg.driver.fullName, iin: pkg.driver.iin },
      license: { number: pkg.license.number, expiryDate: pkg.license.expiryDate, documentId: pkg.license.document?.id ?? null },
      selfieId: pkg.selfie?.id ?? null,
      identityId: pkg.identity?.id ?? null,
      vehicles: pkg.vehicles.map((v) => ({ kind: v.kind, plateNumber: v.plateNumber, vin: v.vin, brand: v.brand, isVerified: v.isVerified, passportId: v.passport?.id ?? null, photoFrontId: v.photoFront?.id ?? null, photoSideId: v.photoSide?.id ?? null })),
      issuedTo: pkg.issuedTo ?? '',
      companyName: pkg.companyName,
      issuedAt: pkg.issuedAt,
      images,
    });
    return { buffer, filename: `lubao-documents-${dealId.slice(0, 8)}.pdf` };
  }

  /// Файл документа из пакета — только тот, что действительно в пакете этой сделки.
  async file(dealId: string, documentId: string, ctx: RequestContext) {
    const deal = await this.accessibleDeal(dealId, ctx);
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id: documentId } });
    const vehicleIds = [deal.tractorId, deal.trailerId].filter((id): id is string => !!id);
    const inPackage =
      !!doc &&
      doc.status !== 'REJECTED' &&
      ((doc.driverId === deal.driverId && PERSON_DOC_TYPES.includes(doc.type)) ||
        (!!doc.vehicleId && vehicleIds.includes(doc.vehicleId) && VEHICLE_DOC_TYPES.includes(doc.type)));
    if (!inPackage) throw new NotFoundException('Document is not in this deal package');
    if (/^https?:\/\//.test(doc.fileUrl)) return { redirectUrl: doc.fileUrl };
    return this.uploads.getDocumentStream(doc.fileUrl);
  }

  /// Водителю — когда и кто из логистов открывал его документы по сделке.
  async accessLog(dealId: string, ctx: RequestContext) {
    const deal = await this.prisma.deal.findUnique({ where: { id: dealId }, select: { driverId: true } });
    if (!deal) throw new NotFoundException('Deal not found');
    if (ctx.driver?.id !== deal.driverId) throw new ForbiddenException('Only the driver of the deal');
    const rows = await this.prisma.auditLog.findMany({
      where: { entityType: 'Deal', entityId: dealId, action: { in: ['DRIVER_DOCS_VIEWED', 'DRIVER_DOCS_DOWNLOADED'] } },
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: { actor: { select: { name: true, companyMember: { select: { fullName: true } } } } },
    });
    return rows.map((r) => ({ at: r.createdAt, action: r.action, by: r.actor?.companyMember?.fullName ?? r.actor?.name ?? null }));
  }
}
