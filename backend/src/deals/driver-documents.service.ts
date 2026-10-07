import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DealStatus, VerificationDocType, VerificationDocument } from '@prisma/client';
import { RequestContext } from '../common/request-context';
import { decryptIdentifier } from '../identifiers/crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';

/// Пакет открыт, пока сделка обоюдная (водитель подтвердил) и ещё 30 дней после доставки.
const OPEN_STATUSES: DealStatus[] = ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'];
export const DOCS_AFTER_DELIVERY_MS = 30 * 24 * 60 * 60 * 1000;

const PERSON_DOC_TYPES: VerificationDocType[] = ['SELFIE', 'DRIVER_LICENSE', 'IDENTITY'];
const VEHICLE_DOC_TYPES: VerificationDocType[] = ['VEHICLE_PASSPORT', 'TRAILER_PASSPORT'];

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
  ) {}

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
        isVerified: v.isVerified,
        passport: ref(latest(vehicleDocs.filter((d) => d.vehicleId === v.id), v.kind === 'TRAILER' ? 'TRAILER_PASSPORT' : 'VEHICLE_PASSPORT')),
      })),
      cargo: { pointId: deal.cargo.pointId, destinationCityId: deal.cargo.destinationCityId, destinationCountryId: deal.cargo.destinationCountryId, readyDate: deal.cargo.readyDate },
      companyName: deal.company.name,
      issuedTo: ctx.companyMember?.fullName ?? ctx.user.name ?? ctx.user.email,
      issuedAt: new Date(),
    };
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
