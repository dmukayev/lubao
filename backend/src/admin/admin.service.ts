import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../auth/session.service';
import { REQUIRED_DRIVER_DOC_TYPES } from '../drivers/drivers.service';
import {
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  ModerateCityDto,
  ReviewVerificationDocumentDto,
} from './dto/admin.dto';

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sessions: SessionService,
  ) {}

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

  private docToDto(doc: {
    id: string;
    userId: string | null;
    driverId: string | null;
    companyId: string | null;
    type: string;
    fileUrl: string;
    status: string;
    rejectReason: string | null;
    createdAt: Date;
    driver?: { fullName: string } | null;
    company?: { name: string } | null;
  }) {
    return {
      id: doc.id,
      subjectName: doc.driver?.fullName ?? doc.company?.name ?? '—',
      driverId: doc.driverId,
      companyId: doc.companyId,
      type: doc.type,
      fileUrl: doc.fileUrl,
      status: doc.status,
      rejectReason: doc.rejectReason,
      createdAt: doc.createdAt,
    };
  }

  async verificationDocuments(status?: string) {
    const docs = await this.prisma.verificationDocument.findMany({
      where: status ? { status: status as never } : undefined,
      include: { driver: true, company: true },
      orderBy: { createdAt: 'desc' },
    });
    return docs.map((d) => this.docToDto(d));
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
      include: { driver: true, company: true },
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
        await this.prisma.company.update({ where: { id: updated.companyId }, data: { isVerified: true } });
      }
    }

    return this.docToDto(updated);
  }

  // -- complaints --------------------------------------------------------------

  async complaints(status?: string) {
    const complaints = await this.prisma.complaint.findMany({
      where: status ? { status: status as never } : undefined,
      include: { reporter: true },
      orderBy: { createdAt: 'desc' },
    });
    return complaints.map((c) => ({
      id: c.id,
      reporterName: c.reporter.phone ?? c.reporter.email ?? c.reporter.id,
      targetType: c.targetType,
      targetId: c.targetId,
      reason: c.reason,
      description: c.description,
      status: c.status,
      createdAt: c.createdAt,
    }));
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
      include: { reporter: true },
    });
    return {
      id: updated.id,
      reporterName: updated.reporter.phone ?? updated.reporter.email ?? updated.reporter.id,
      targetType: updated.targetType,
      targetId: updated.targetId,
      reason: updated.reason,
      description: updated.description,
      status: updated.status,
      createdAt: updated.createdAt,
    };
  }

  // -- companies / drivers verification toggle ---------------------------------

  async companies() {
    const companies = await this.prisma.company.findMany({ orderBy: { name: 'asc' } });
    return companies.map((c) => ({
      id: c.id,
      name: c.name,
      countryId: c.countryId,
      city: c.city,
      isVerified: c.isVerified,
      ratingAvg: Number(c.ratingAvg),
      ratingCount: c.ratingCount,
    }));
  }

  async setCompanyVerified(id: string, isVerified: boolean) {
    const company = await this.prisma.company.update({ where: { id }, data: { isVerified } });
    return { id: company.id, isVerified: company.isVerified };
  }

  /// «Сбросить пароль» (задача 025, п. 10) — для владельца, который не
  /// получил письмо восстановления. Генерирует временный пароль, завершает
  /// все его сессии. Упрощение: не форсируем смену пароля при следующем
  /// входе (отдельное поле/флаг) — админ один раз сообщает временный
  /// пароль лично, типичный сценарий на пилоте.
  async resetCompanyPassword(companyId: string) {
    const member = await this.prisma.companyMember.findFirst({ where: { companyId, role: 'OWNER' } });
    if (!member) throw new NotFoundException('Company owner not found');

    const tempPassword = crypto.randomBytes(6).toString('base64url');
    const passwordHash = await bcrypt.hash(tempPassword, 10);
    await this.prisma.user.update({ where: { id: member.userId }, data: { passwordHash } });
    await this.sessions.revokeAllForUser(member.userId);

    return { tempPassword };
  }

  async drivers() {
    const drivers = await this.prisma.driver.findMany({ orderBy: { fullName: 'asc' } });
    return drivers.map((d) => ({
      id: d.id,
      fullName: d.fullName,
      isVerified: d.isVerified,
      ratingAvg: Number(d.ratingAvg),
      ratingCount: d.ratingCount,
    }));
  }

  async setDriverVerified(id: string, isVerified: boolean) {
    const driver = await this.prisma.driver.update({ where: { id }, data: { isVerified } });
    return { id: driver.id, isVerified: driver.isVerified };
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
