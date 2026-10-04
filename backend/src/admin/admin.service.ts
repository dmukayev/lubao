import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../auth/session.service';
import { UploadsService } from '../uploads/uploads.service';
import { REQUIRED_DRIVER_DOC_TYPES } from '../drivers/drivers.service';
import {
  BlockUserDto,
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  ModerateCityDto,
  ReviewVerificationDocumentDto,
  SearchQueryDto,
  SetVerifiedDto,
} from './dto/admin.dto';

/// Единственный обязательный документ компании на пилоте — свидетельство о
/// регистрации (营业执照 / справка с БИН), см. decisions.md «Компания:
/// проверка, роли, контакты» (задача 012). Аналог REQUIRED_DRIVER_DOC_TYPES.
const REQUIRED_COMPANY_DOC_TYPES = ['COMPANY_REGISTRATION'] as const;

const DEFAULT_PAGE_SIZE = 50;

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sessions: SessionService,
    private readonly uploads: UploadsService,
  ) {}

  private async logAudit(actorUserId: string, action: string, entityType: string, entityId: string, metadata?: object) {
    await this.prisma.auditLog.create({ data: { actorUserId, action, entityType, entityId, metadata } });
  }

  async stats() {
    const [drivers, companies, cargosPublished, dealsActive, dealsDelivered, pendingDocs, openComplaints] =
      await Promise.all([
        this.prisma.driver.count(),
        this.prisma.company.count(),
        this.prisma.cargo.count({ where: { status: 'PUBLISHED' } }),
        this.prisma.deal.count({ where: { status: { notIn: ['DELIVERED', 'CANCELLED'] } } }),
        this.prisma.deal.count({ where: { status: 'DELIVERED' } }),
        this.prisma.verificationDocument.count({ where: { status: 'PENDING' } }),
        this.prisma.complaint.count({ where: { status: 'OPEN' } }),
      ]);
    return { drivers, companies, cargosPublished, dealsActive, dealsDelivered, pendingDocs, openComplaints };
  }

  // -- verification documents ------------------------------------------------

  private async docToDto(doc: {
    id: string;
    userId: string | null;
    driverId: string | null;
    companyId: string | null;
    type: string;
    fileUrl: string;
    status: string;
    rejectReason: string | null;
    createdAt: Date;
    reviewedByUserId?: string | null;
    reviewedBy?: { id: string; name: string | null; email: string | null } | null;
    reviewedAt?: Date | null;
    driver?: { fullName: string } | null;
    company?: { name: string } | null;
  }) {
    return {
      id: doc.id,
      subjectName: doc.driver?.fullName ?? doc.company?.name ?? '—',
      driverId: doc.driverId,
      companyId: doc.companyId,
      type: doc.type,
      fileUrl: await this.uploads.presignDocumentUrl(doc.fileUrl),
      status: doc.status,
      rejectReason: doc.rejectReason,
      reviewedByUserId: doc.reviewedByUserId ?? null,
      reviewedByName: doc.reviewedBy?.name ?? doc.reviewedBy?.email ?? null,
      reviewedAt: doc.reviewedAt ?? null,
      createdAt: doc.createdAt,
    };
  }

  async verificationDocuments(status?: string) {
    const docs = await this.prisma.verificationDocument.findMany({
      where: status ? { status: status as never } : undefined,
      include: { driver: true, company: true, reviewedBy: { select: { id: true, name: true, email: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(docs.map((d) => this.docToDto(d)));
  }

  async reviewVerificationDocument(id: string, adminUserId: string, dto: ReviewVerificationDocumentDto) {
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id } });
    if (!doc) throw new NotFoundException('Document not found');

    const updated = await this.prisma.verificationDocument.update({
      where: { id },
      data: {
        status: dto.status,
        rejectReason: dto.status === 'REJECTED' ? dto.rejectReason : null,
        reviewedByUserId: adminUserId,
        reviewedAt: new Date(),
      },
      include: { driver: true, company: true, reviewedBy: { select: { id: true, name: true, email: true } } },
    });

    await this.logAudit(adminUserId, dto.status === 'APPROVED' ? 'DOCUMENT_APPROVED' : 'DOCUMENT_REJECTED', 'VerificationDocument', id, {
      rejectReason: dto.rejectReason,
    });

    if (dto.status === 'APPROVED') {
      if (updated.driverId) {
        // Верифицирован, только когда одобрены ВСЕ обязательные документы
        // (селфи + техпаспорта тягача и прицепа + права), а не любой один.
        const approved = await this.prisma.verificationDocument.findMany({
          where: { driverId: updated.driverId, status: 'APPROVED' },
          select: { type: true },
        });
        const approvedTypes = new Set(approved.map((d) => d.type));
        const allRequiredApproved = REQUIRED_DRIVER_DOC_TYPES.every((type) => approvedTypes.has(type));
        if (allRequiredApproved) {
          await this.prisma.driver.update({ where: { id: updated.driverId }, data: { isVerified: true } });
        }
      }
      if (updated.companyId) {
        const approved = await this.prisma.verificationDocument.findMany({
          where: { companyId: updated.companyId, status: 'APPROVED' },
          select: { type: true },
        });
        const approvedTypes = new Set(approved.map((d) => d.type));
        const allRequiredApproved = REQUIRED_COMPANY_DOC_TYPES.every((type) => approvedTypes.has(type));
        if (allRequiredApproved) {
          await this.prisma.company.update({ where: { id: updated.companyId }, data: { isVerified: true } });
        }
      }
    }

    return this.docToDto(updated);
  }

  // -- complaints --------------------------------------------------------------

  /// Цель жалобы (задача 026, п.7) — кто реально нарушитель, чтобы из
  /// жалобы можно было перейти на карточку водителя/компании. Для CARGO —
  /// владелец (компания); для DEAL/CHAT_MESSAGE — обе стороны (водитель и
  /// компания), для USER/COMPANY — сам объект.
  private async complaintTarget(targetType: string, targetId: string) {
    switch (targetType) {
      case 'USER': {
        const user = await this.prisma.user.findUnique({
          where: { id: targetId },
          select: {
            id: true,
            name: true,
            phone: true,
            email: true,
            driver: { select: { id: true } },
            companyMember: { select: { companyId: true } },
          },
        });
        if (!user) return null;
        return {
          type: 'USER',
          id: user.id,
          title: user.name ?? user.phone ?? user.email ?? user.id,
          driverId: user.driver?.id,
          companyId: user.companyMember?.companyId,
        };
      }
      case 'COMPANY': {
        const company = await this.prisma.company.findUnique({ where: { id: targetId }, select: { id: true, name: true } });
        if (!company) return null;
        return { type: 'COMPANY', id: company.id, title: company.name, companyId: company.id };
      }
      case 'CARGO': {
        const cargo = await this.prisma.cargo.findUnique({
          where: { id: targetId },
          select: { id: true, companyId: true, company: { select: { name: true } } },
        });
        if (!cargo) return null;
        return { type: 'CARGO', id: cargo.id, title: cargo.company.name, companyId: cargo.companyId };
      }
      case 'DEAL': {
        const deal = await this.prisma.deal.findUnique({
          where: { id: targetId },
          select: { id: true, driverId: true, companyId: true, driver: { select: { fullName: true } } },
        });
        if (!deal) return null;
        return { type: 'DEAL', id: deal.id, title: deal.driver.fullName, driverId: deal.driverId, companyId: deal.companyId };
      }
      case 'CHAT_MESSAGE': {
        const message = await this.prisma.message.findUnique({
          where: { id: targetId },
          select: {
            id: true,
            sender: { select: { name: true, phone: true, email: true, driver: { select: { id: true } }, companyMember: { select: { companyId: true } } } },
          },
        });
        if (!message) return null;
        return {
          type: 'CHAT_MESSAGE',
          id: message.id,
          title: message.sender.name ?? message.sender.phone ?? message.sender.email ?? message.id,
          driverId: message.sender.driver?.id,
          companyId: message.sender.companyMember?.companyId,
        };
      }
      default:
        return null;
    }
  }

  private async complaintToDto(c: {
    id: string;
    reporterUserId: string;
    reporter: { phone: string | null; email: string | null; id: string };
    targetType: string;
    targetId: string;
    reason: string;
    description: string | null;
    status: string;
    createdAt: Date;
  }) {
    return {
      id: c.id,
      reporterUserId: c.reporterUserId,
      reporterName: c.reporter.phone ?? c.reporter.email ?? c.reporter.id,
      targetType: c.targetType,
      targetId: c.targetId,
      target: await this.complaintTarget(c.targetType, c.targetId),
      // Чтобы из жалобы перейти и на карточку заявителя, не только
      // нарушителя (задача 026, п.14) — тот же резолвер, что и для target.
      reporter: await this.complaintTarget('USER', c.reporterUserId),
      reason: c.reason,
      description: c.description,
      status: c.status,
      createdAt: c.createdAt,
    };
  }

  async complaints(status?: string) {
    const complaints = await this.prisma.complaint.findMany({
      where: status ? { status: status as never } : undefined,
      // select, не include: true — иначе в ответ утекает passwordHash (п.8).
      select: {
        id: true,
        reporterUserId: true,
        reporter: { select: { id: true, phone: true, email: true } },
        targetType: true,
        targetId: true,
        reason: true,
        description: true,
        status: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(complaints.map((c) => this.complaintToDto(c)));
  }

  async resolveComplaint(id: string, adminUserId: string, status: 'IN_REVIEW' | 'RESOLVED' | 'REJECTED') {
    const complaint = await this.prisma.complaint.findUnique({ where: { id } });
    if (!complaint) throw new NotFoundException('Complaint not found');

    const updated = await this.prisma.complaint.update({
      where: { id },
      data: {
        status,
        resolvedByUserId: status === 'RESOLVED' || status === 'REJECTED' ? adminUserId : null,
        resolvedAt: status === 'RESOLVED' || status === 'REJECTED' ? new Date() : null,
      },
      select: {
        id: true,
        reporterUserId: true,
        reporter: { select: { id: true, phone: true, email: true } },
        targetType: true,
        targetId: true,
        reason: true,
        description: true,
        status: true,
        createdAt: true,
      },
    });
    await this.logAudit(adminUserId, 'COMPLAINT_STATUS_CHANGED', 'Complaint', id, { status });
    return this.complaintToDto(updated);
  }

  // -- search / list -------------------------------------------------------

  async searchDrivers(query: SearchQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const q = query.q?.trim();

    const where: Record<string, unknown> = {
      ...(query.verified !== undefined ? { isVerified: query.verified } : {}),
      ...(query.blocked !== undefined ? { user: { isBlocked: query.blocked } } : {}),
      ...(q
        ? {
            OR: [
              { fullName: { contains: q, mode: 'insensitive' } },
              { user: { phone: { contains: q, mode: 'insensitive' } } },
              { vehicles: { some: { plateNumber: { contains: q, mode: 'insensitive' } } } },
            ],
          }
        : {}),
    };

    const [total, drivers] = await Promise.all([
      this.prisma.driver.count({ where: where as never }),
      this.prisma.driver.findMany({
        where: where as never,
        include: {
          user: { select: { phone: true, isBlocked: true, createdAt: true } },
          homeCity: { select: { name: true } },
          vehicles: { select: { bodyType: { select: { name: true } }, capacityTons: true }, take: 1 },
          verificationDocuments: { where: { status: 'PENDING' }, select: { id: true } },
          arrivals: { orderBy: { createdAt: 'desc' }, take: 1, select: { status: true, plannedAt: true, arrivedAt: true } },
          _count: { select: { deals: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const items = drivers.map((d) => ({
      id: d.id,
      fullName: d.fullName,
      phone: d.user.phone,
      homeCityName: d.homeCity.name,
      vehicle: d.vehicles[0]
        ? { bodyTypeName: d.vehicles[0].bodyType.name, capacityTons: d.vehicles[0].capacityTons ? Number(d.vehicles[0].capacityTons) : null }
        : null,
      isVerified: d.isVerified,
      pendingDocsCount: d.verificationDocuments.length,
      ratingAvg: Number(d.ratingAvg),
      ratingCount: d.ratingCount,
      completedDeals: d._count.deals,
      isBlocked: d.user.isBlocked,
      registeredAt: d.user.createdAt,
      lastArrival: d.arrivals[0] ?? null,
    }));

    return { items, total };
  }

  async searchCompanies(query: SearchQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const q = query.q?.trim();

    const where: Record<string, unknown> = {
      ...(query.verified !== undefined ? { isVerified: query.verified } : {}),
      ...(query.blocked !== undefined ? { isBlocked: query.blocked } : {}),
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' } },
              { nameRu: { contains: q, mode: 'insensitive' } },
              { taxId: { contains: q, mode: 'insensitive' } },
              { members: { some: { user: { email: { contains: q, mode: 'insensitive' } } } } },
            ],
          }
        : {}),
    };

    const [total, companies] = await Promise.all([
      this.prisma.company.count({ where: where as never }),
      this.prisma.company.findMany({
        where: where as never,
        include: {
          members: { where: { role: 'OWNER' }, include: { user: { select: { name: true, email: true } } }, take: 1 },
          verificationDocuments: { where: { status: 'PENDING' }, select: { id: true } },
          _count: { select: { members: true, cargos: true, deals: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const items = companies.map((c) => ({
      id: c.id,
      name: c.name,
      nameRu: c.nameRu,
      countryId: c.countryId,
      owner: c.members[0] ? { name: c.members[0].user.name, email: c.members[0].user.email } : null,
      employeeCount: c._count.members,
      activeCargoCount: c._count.cargos,
      dealCount: c._count.deals,
      isVerified: c.isVerified,
      pendingDocsCount: c.verificationDocuments.length,
      isBlocked: c.isBlocked,
      ratingAvg: Number(c.ratingAvg),
      ratingCount: c.ratingCount,
    }));

    return { items, total };
  }

  // -- detail ------------------------------------------------------------

  async driverDetail(id: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { id },
      include: {
        user: true,
        homeCity: { select: { name: true } },
        directions: { include: { country: { select: { name: true } } } },
        permits: { include: { permit: { select: { name: true } } } },
        vehicles: { include: { bodyType: { select: { name: true } } } },
      },
    });
    if (!driver) throw new NotFoundException('Driver not found');

    const [documents, lastSession, dealsByStatus, cancellations, reviews, calls, whatsapp, complaintsAgainst, complaintsBy, arrivals, deals, sessions, auditLog] =
      await Promise.all([
        this.prisma.verificationDocument.findMany({
          where: { driverId: id },
          include: { reviewedBy: { select: { id: true, name: true, email: true } } },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.session.findFirst({ where: { userId: driver.userId }, orderBy: { lastUsedAt: 'desc' } }),
        this.prisma.deal.groupBy({ by: ['status'], where: { driverId: id }, _count: true }),
        this.prisma.deal.count({ where: { driverId: id, status: 'CANCELLED' } }),
        this.prisma.review.findMany({
          where: { deal: { driverId: id }, authorRole: 'COMPANY' },
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: { id: true, rating: true, comment: true, createdAt: true, dealId: true },
        }),
        this.prisma.contactEvent.count({ where: { driverId: id, type: 'CALL' } }),
        this.prisma.contactEvent.count({ where: { driverId: id, type: 'WHATSAPP' } }),
        this.prisma.complaint.count({ where: { targetType: 'USER', targetId: driver.userId } }),
        this.prisma.complaint.count({ where: { reporterUserId: driver.userId } }),
        this.prisma.arrival.findMany({ where: { driverId: id }, orderBy: { createdAt: 'desc' }, take: 20 }),
        this.prisma.deal.findMany({
          where: { driverId: id },
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: { id: true, status: true, companyId: true, company: { select: { name: true } }, createdAt: true },
        }),
        this.prisma.session.findMany({ where: { userId: driver.userId, revokedAt: null, expiresAt: { gt: new Date() } } }),
        this.prisma.auditLog.findMany({
          where: { OR: [{ entityType: 'User', entityId: driver.userId }, { entityType: 'Driver', entityId: id }] },
          orderBy: { createdAt: 'desc' },
          take: 30,
          include: { actor: { select: { name: true, email: true } } },
        }),
      ]);

    return {
      id: driver.id,
      fullName: driver.fullName,
      isVerified: driver.isVerified,
      user: {
        id: driver.userId,
        phone: driver.user.phone,
        locale: driver.user.locale,
        createdAt: driver.user.createdAt,
        isBlocked: driver.user.isBlocked,
        lastLoginAt: lastSession?.lastUsedAt ?? driver.user.createdAt,
      },
      homeCityName: driver.homeCity.name,
      anyCountry: driver.anyCountry,
      directions: driver.directions.map((d) => ({ countryId: d.countryId, name: d.country.name })),
      permits: driver.permits.map((p) => ({ permitId: p.permitId, name: p.permit.name })),
      vehicles: driver.vehicles.map((v) => ({
        id: v.id,
        bodyTypeName: v.bodyType.name,
        capacityTons: v.capacityTons ? Number(v.capacityTons) : null,
        lengthM: v.lengthM ? Number(v.lengthM) : null,
        plateNumber: v.plateNumber,
        brand: v.brand,
      })),
      documents: await Promise.all(
        documents.map(async (d) => ({
          id: d.id,
          type: d.type,
          fileUrl: await this.uploads.presignDocumentUrl(d.fileUrl),
          status: d.status,
          rejectReason: d.rejectReason,
          reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
          reviewedAt: d.reviewedAt,
          createdAt: d.createdAt,
        })),
      ),
      stats: {
        dealsByStatus: Object.fromEntries(dealsByStatus.map((g) => [g.status, g._count])),
        cancellations,
        ratingAvg: Number(driver.ratingAvg),
        ratingCount: driver.ratingCount,
        reviews,
        calls,
        whatsapp,
        complaintsAgainst,
        complaintsBy,
      },
      arrivals,
      deals: deals.map((d) => ({ id: d.id, status: d.status, companyId: d.companyId, companyName: d.company.name, createdAt: d.createdAt })),
      sessions: sessions.map((s) => ({ id: s.id, deviceName: s.deviceName, platform: s.platform, lastUsedAt: s.lastUsedAt, createdAt: s.createdAt })),
      auditLog: auditLog.map((a) => ({
        id: a.id,
        action: a.action,
        actorName: a.actor?.name ?? a.actor?.email ?? null,
        metadata: a.metadata,
        createdAt: a.createdAt,
      })),
    };
  }

  async companyDetail(id: string) {
    const company = await this.prisma.company.findUnique({ where: { id }, include: { country: { select: { name: true } } } });
    if (!company) throw new NotFoundException('Company not found');

    const [documents, members, invites, cargos, deals, reviews, complaints, auditLog] = await Promise.all([
      this.prisma.verificationDocument.findMany({
        where: { companyId: id },
        include: { reviewedBy: { select: { id: true, name: true, email: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.companyMember.findMany({
        where: { companyId: id },
        include: { user: { select: { id: true, name: true, email: true, isBlocked: true, sessions: { orderBy: { lastUsedAt: 'desc' }, take: 1 } } } },
      }),
      this.prisma.companyInvite.findMany({ where: { companyId: id }, orderBy: { createdAt: 'desc' }, take: 20 }),
      this.prisma.cargo.findMany({
        where: { companyId: id },
        orderBy: { createdAt: 'desc' },
        take: 20,
        include: { point: { select: { name: true } }, destinationCountry: { select: { name: true } }, _count: { select: { responses: true } } },
      }),
      this.prisma.deal.findMany({
        where: { companyId: id },
        orderBy: { createdAt: 'desc' },
        take: 20,
        select: { id: true, status: true, driverId: true, driver: { select: { fullName: true } }, createdAt: true },
      }),
      this.prisma.review.findMany({
        where: { deal: { companyId: id }, authorRole: 'DRIVER' },
        orderBy: { createdAt: 'desc' },
        take: 10,
        select: { id: true, rating: true, comment: true, createdAt: true, dealId: true },
      }),
      this.prisma.complaint.count({ where: { targetType: 'COMPANY', targetId: id } }),
      this.prisma.auditLog.findMany({
        where: { entityType: 'Company', entityId: id },
        orderBy: { createdAt: 'desc' },
        take: 30,
        include: { actor: { select: { name: true, email: true } } },
      }),
    ]);

    return {
      id: company.id,
      name: company.name,
      nameRu: company.nameRu,
      countryName: company.country.name,
      city: company.city,
      legalAddress: company.legalAddress,
      taxId: company.taxId,
      isVerified: company.isVerified,
      isBlocked: company.isBlocked,
      ratingAvg: Number(company.ratingAvg),
      ratingCount: company.ratingCount,
      documents: await Promise.all(
        documents.map(async (d) => ({
          id: d.id,
          type: d.type,
          fileUrl: await this.uploads.presignDocumentUrl(d.fileUrl),
          status: d.status,
          rejectReason: d.rejectReason,
          reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
          reviewedAt: d.reviewedAt,
          createdAt: d.createdAt,
        })),
      ),
      employees: members.map((m) => ({
        userId: m.userId,
        name: m.user.name,
        email: m.user.email,
        role: m.role,
        isBlocked: m.user.isBlocked,
        lastLoginAt: m.user.sessions[0]?.lastUsedAt ?? null,
      })),
      invites: invites.map((i) => ({ email: i.email, role: i.role, expiresAt: i.expiresAt, usedAt: i.usedAt })),
      cargos: cargos.map((c) => ({
        id: c.id,
        pointName: c.point.name,
        destinationCountryName: c.destinationCountry.name,
        price: Number(c.price),
        currency: c.currency,
        status: c.status,
        responseCount: c._count.responses,
        createdAt: c.createdAt,
      })),
      deals: deals.map((d) => ({ id: d.id, status: d.status, driverId: d.driverId, driverName: d.driver.fullName, createdAt: d.createdAt })),
      reviews,
      complaintsAgainst: complaints,
      auditLog: auditLog.map((a) => ({
        id: a.id,
        action: a.action,
        actorName: a.actor?.name ?? a.actor?.email ?? null,
        metadata: a.metadata,
        createdAt: a.createdAt,
      })),
    };
  }

  // -- block / unblock / sessions -----------------------------------------

  async blockUser(userId: string, adminUserId: string, dto: BlockUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    await this.prisma.user.update({ where: { id: userId }, data: { isBlocked: true } });
    await this.sessions.revokeAllForUser(userId);
    await this.logAudit(adminUserId, 'USER_BLOCKED', 'User', userId, { reason: dto.reason });
    return { id: userId, isBlocked: true };
  }

  async unblockUser(userId: string, adminUserId: string, dto: BlockUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    await this.prisma.user.update({ where: { id: userId }, data: { isBlocked: false } });
    await this.logAudit(adminUserId, 'USER_UNBLOCKED', 'User', userId, { reason: dto.reason });
    return { id: userId, isBlocked: false };
  }

  /// Блокировка компании целиком (задача 026, п.5) — блокирует всех
  /// сотрудников (каждый теряет доступ и все сессии) и помечает саму
  /// компанию, чтобы её активные грузы ушли из ленты водителя
  /// (см. CargosService.feed — фильтр по company.isBlocked).
  async blockCompany(companyId: string, adminUserId: string, dto: BlockUserDto) {
    const company = await this.prisma.company.findUnique({ where: { id: companyId }, include: { members: true } });
    if (!company) throw new NotFoundException('Company not found');

    await this.prisma.$transaction([
      this.prisma.company.update({ where: { id: companyId }, data: { isBlocked: true } }),
      this.prisma.user.updateMany({ where: { id: { in: company.members.map((m) => m.userId) } }, data: { isBlocked: true } }),
    ]);
    await Promise.all(company.members.map((m) => this.sessions.revokeAllForUser(m.userId)));
    await this.logAudit(adminUserId, 'COMPANY_BLOCKED', 'Company', companyId, { reason: dto.reason });
    return { id: companyId, isBlocked: true };
  }

  async unblockCompany(companyId: string, adminUserId: string, dto: BlockUserDto) {
    const company = await this.prisma.company.findUnique({ where: { id: companyId }, include: { members: true } });
    if (!company) throw new NotFoundException('Company not found');

    await this.prisma.$transaction([
      this.prisma.company.update({ where: { id: companyId }, data: { isBlocked: false } }),
      this.prisma.user.updateMany({ where: { id: { in: company.members.map((m) => m.userId) } }, data: { isBlocked: false } }),
    ]);
    await this.logAudit(adminUserId, 'COMPANY_UNBLOCKED', 'Company', companyId, { reason: dto.reason });
    return { id: companyId, isBlocked: false };
  }

  async revokeSessions(userId: string, adminUserId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    await this.sessions.revokeAllForUser(userId);
    await this.logAudit(adminUserId, 'SESSIONS_REVOKED', 'User', userId, {});
    return { success: true };
  }

  // -- companies / drivers verification ------------------------------------

  /// Поставить/снять «Проверена» — п.5 задачи 026: `true` разрешено только
  /// когда все обязательные документы компании APPROVED, иначе — только с
  /// явным `force: true` и причиной («проверил лично» на пилоте). Причина
  /// обязательна всегда, пишется в audit_log.
  async setCompanyVerified(id: string, adminUserId: string, dto: SetVerifiedDto) {
    const company = await this.prisma.company.findUnique({ where: { id } });
    if (!company) throw new NotFoundException('Company not found');

    if (dto.isVerified && !dto.force) {
      const approved = await this.prisma.verificationDocument.findMany({
        where: { companyId: id, status: 'APPROVED' },
        select: { type: true },
      });
      const approvedTypes = new Set(approved.map((d) => d.type));
      const allRequiredApproved = REQUIRED_COMPANY_DOC_TYPES.every((type) => approvedTypes.has(type));
      if (!allRequiredApproved) {
        throw new BadRequestException('Not all required documents are approved — pass force:true to override');
      }
    }

    const updated = await this.prisma.company.update({ where: { id }, data: { isVerified: dto.isVerified } });
    await this.logAudit(adminUserId, dto.isVerified ? 'COMPANY_VERIFIED' : 'COMPANY_UNVERIFIED', 'Company', id, {
      reason: dto.reason,
      force: dto.force ?? false,
    });
    return { id: updated.id, isVerified: updated.isVerified };
  }

  /// «Сбросить пароль» (задача 025, п. 10) — для владельца, который не
  /// получил письмо восстановления. Генерирует временный пароль, завершает
  /// все его сессии. Упрощение: не форсируем смену пароля при следующем
  /// входе (отдельное поле/флаг) — админ один раз сообщает временный
  /// пароль лично, типичный сценарий на пилоте.
  async resetCompanyPassword(companyId: string, adminUserId: string) {
    const member = await this.prisma.companyMember.findFirst({ where: { companyId, role: 'OWNER' } });
    if (!member) throw new NotFoundException('Company owner not found');

    const tempPassword = crypto.randomBytes(6).toString('base64url');
    const passwordHash = await bcrypt.hash(tempPassword, 10);
    await this.prisma.user.update({ where: { id: member.userId }, data: { passwordHash } });
    await this.sessions.revokeAllForUser(member.userId);
    await this.logAudit(adminUserId, 'COMPANY_PASSWORD_RESET', 'Company', companyId, {});

    return { tempPassword };
  }

  /// Аналог setCompanyVerified для водителя — та же логика force/reason,
  /// те же 4 обязательных документа, что и в reviewVerificationDocument.
  async setDriverVerified(id: string, adminUserId: string, dto: SetVerifiedDto) {
    const driver = await this.prisma.driver.findUnique({ where: { id } });
    if (!driver) throw new NotFoundException('Driver not found');

    if (dto.isVerified && !dto.force) {
      const approved = await this.prisma.verificationDocument.findMany({
        where: { driverId: id, status: 'APPROVED' },
        select: { type: true },
      });
      const approvedTypes = new Set(approved.map((d) => d.type));
      const allRequiredApproved = REQUIRED_DRIVER_DOC_TYPES.every((type) => approvedTypes.has(type));
      if (!allRequiredApproved) {
        throw new BadRequestException('Not all required documents are approved — pass force:true to override');
      }
    }

    const updated = await this.prisma.driver.update({ where: { id }, data: { isVerified: dto.isVerified } });
    await this.logAudit(adminUserId, dto.isVerified ? 'DRIVER_VERIFIED' : 'DRIVER_UNVERIFIED', 'Driver', id, {
      reason: dto.reason,
      force: dto.force ?? false,
    });
    return { id: updated.id, isVerified: updated.isVerified };
  }

  // -- reference data management ------------------------------------------------

  async createBodyType(dto: CreateBodyTypeDto) {
    return this.prisma.bodyType.create({
      data: { code: dto.code, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh } },
    });
  }

  async createPermit(dto: CreatePermitDto) {
    return this.prisma.permit.create({
      data: { code: dto.code, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh } },
    });
  }

  async createPoint(dto: CreatePointDto) {
    return this.prisma.point.create({
      data: { cityId: dto.cityId, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh }, isActive: true },
    });
  }

  async setPointActive(id: string, isActive: boolean) {
    const point = await this.prisma.point.update({ where: { id }, data: { isActive } });
    return { id: point.id, isActive: point.isActive };
  }

  async pendingCities() {
    return this.prisma.city.findMany({
      where: { cityStatus: 'PENDING' },
      include: {
        region: true,
        // select, не include: true — иначе в ответ утекает passwordHash.
        submittedBy: { select: { id: true, phone: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /// Очередь модерации городов, предложенных водителями/логистами через
  /// «Нет моего города» (задача 021): APPROVE — админ переводит название на
  /// kk/ru/zh(/en) и подтверждает; MERGE — это дубликат уже существующего
  /// города, все водители/грузы переподвешиваются на канонический id;
  /// REJECT — город остаётся как есть (на него уже может ссылаться водитель),
  /// просто больше не предлагается новым сабмитам и уходит из очереди.
  async moderateCity(id: string, adminUserId: string, dto: ModerateCityDto) {
    const city = await this.prisma.city.findUnique({ where: { id } });
    if (!city) throw new NotFoundException('City not found');

    if (dto.action === 'APPROVE') {
      if (!dto.name) throw new BadRequestException('name is required for APPROVE');
      return this.prisma.city.update({
        where: { id },
        data: {
          name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, ...(dto.name.en ? { en: dto.name.en } : {}) },
          cityStatus: 'APPROVED',
          reviewedByUserId: adminUserId,
          reviewedAt: new Date(),
        },
      });
    }

    if (dto.action === 'MERGE') {
      if (!dto.mergeIntoCityId) throw new BadRequestException('mergeIntoCityId is required for MERGE');
      const target = await this.prisma.city.findUnique({ where: { id: dto.mergeIntoCityId } });
      if (!target) throw new NotFoundException('Target city not found');

      return this.prisma.$transaction(async (tx) => {
        await tx.driver.updateMany({ where: { homeCityId: id }, data: { homeCityId: target.id } });
        await tx.cargo.updateMany({ where: { destinationCityId: id }, data: { destinationCityId: target.id } });
        await tx.point.updateMany({ where: { cityId: id }, data: { cityId: target.id } });
        await tx.city.delete({ where: { id } });
        return target;
      });
    }

    // REJECT
    return this.prisma.city.update({
      where: { id },
      data: {
        cityStatus: 'REJECTED',
        rejectReason: dto.rejectReason,
        reviewedByUserId: adminUserId,
        reviewedAt: new Date(),
      },
    });
  }
}
