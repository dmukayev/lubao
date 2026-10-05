import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';
import * as bcrypt from 'bcryptjs';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SessionService } from '../auth/session.service';
import { UploadsService } from '../uploads/uploads.service';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { REQUIRED_DRIVER_DOC_TYPES } from '../drivers/drivers.service';
import { resolveCargoContactUserId } from '../cargos/resolve-contact';
import { NotificationsService } from '../notifications/notifications.service';
import { IdentifiersService } from '../identifiers/identifiers.service';
import { RecognitionService } from '../recognition/recognition.service';
import { decryptIdentifier, maskIdentifier } from '../identifiers/crypto';
import { normalizeIdentifier, type IdentifierTypeValue } from '../identifiers/normalize';
import { RECOGNIZED_FIELD_IDENTIFIER_TYPE } from '../recognition/extract-fields';
import {
  AdminChangeMemberEmailDto,
  AdminDealStatusDto,
  AdminSetMemberRoleDto,
  AdminUpdateCargoDto,
  AdminUpdateBodySizePresetDto,
  AdminUpdateCityDto,
  AdminUpdateCompanyDto,
  AdminUpdateDriverDto,
  AdminUpdatePointDto,
  AdminUpdateReferenceItemDto,
  BlockUserDto,
  CargoSearchQueryDto,
  CreateBodySizePresetDto,
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  DealSearchQueryDto,
  ModerateCityDto,
  ResolveComplaintDto,
  ReturnForReworkDto,
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
    private readonly appSettings?: AppSettingsService,
    private readonly notifications?: NotificationsService,
    private readonly identifiers?: IdentifiersService,
    private readonly recognition?: RecognitionService,
  ) {}

  private async logAudit(actorUserId: string, action: string, entityType: string, entityId: string, metadata?: object) {
    await this.prisma.auditLog.create({ data: { actorUserId, action, entityType, entityId, metadata } });
  }

  /// Настройки (п.22) — каждое изменение в audit_log со старым/новым
  /// значением, даже без причины (settings — не карточка конкретного
  /// человека/компании, где причина обязательна по общему паттерну, п.18).
  async setAppSetting(adminUserId: string, key: string, value: string, reason?: string) {
    const oldValue = await this.appSettings!.get(key);
    await this.appSettings!.set(key, value);
    await this.logAudit(adminUserId, 'SETTING_CHANGED', 'AppSetting', key, { reason, old: oldValue, new: value });
    return { success: true };
  }

  /// Настройки → Перевод (задача 010, п.8): включён/выключен (общий
  /// AppSetting 'translationEnabled', переключается через уже
  /// существующий PATCH /admin/settings/:key), провайдер/модель из .env,
  /// расход за 7 дней из TranslationLog.
  async translationStats() {
    const enabled = (await this.appSettings!.get('translationEnabled')) !== 'false';
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const logs = await this.prisma.translationLog.findMany({ where: { createdAt: { gte: since } } });
    const requests7d = logs.length;
    const successRequests7d = logs.filter((l) => l.success).length;
    const tokensUsed7d = logs.reduce((sum, l) => sum + (l.tokensUsed ?? 0), 0);

    return {
      enabled,
      provider: process.env.TRANSLATION_PROVIDER ?? 'noop',
      model: process.env.DEEPSEEK_MODEL ?? null,
      requests7d,
      successRequests7d,
      tokensUsed7d,
    };
  }

  private periodStart(period?: 'today' | '7d' | '30d'): Date {
    const now = new Date();
    if (period === '7d') return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    if (period === '30d') return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
  }

  /// Сводка — пульт, не витрина (задача 028, п.2): прирост за выбранный
  /// период + «на точке» сегодня/на неделе, поверх прежних абсолютных цифр.
  async stats(period?: 'today' | '7d' | '30d') {
    const since = this.periodStart(period);
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);
    const weekEnd = new Date(todayStart.getTime() + 7 * 24 * 60 * 60 * 1000);

    const [
      drivers,
      companies,
      cargosPublished,
      dealsActive,
      dealsDelivered,
      pendingDocs,
      openComplaints,
      newDrivers,
      newCompanies,
      newCargos,
      deliveredInPeriod,
      onSiteToday,
      onSiteWeek,
      cargosClosedTotal,
      cargosClosedOutside,
    ] = await Promise.all([
      this.prisma.driver.count(),
      this.prisma.company.count(),
      this.prisma.cargo.count({ where: { status: 'PUBLISHED' } }),
      this.prisma.deal.count({ where: { status: { notIn: ['DELIVERED', 'CANCELLED'] } } }),
      this.prisma.deal.count({ where: { status: 'DELIVERED' } }),
      this.prisma.verificationDocument.count({ where: { status: 'PENDING' } }),
      this.prisma.complaint.count({ where: { status: { in: ['OPEN', 'IN_REVIEW'] } } }),
      this.prisma.driver.count({ where: { createdAt: { gte: since } } }),
      this.prisma.company.count({ where: { createdAt: { gte: since } } }),
      this.prisma.cargo.count({ where: { createdAt: { gte: since } } }),
      this.prisma.deal.count({ where: { status: 'DELIVERED', deliveredAt: { gte: since } } }),
      this.prisma.arrival.count({
        where: { OR: [{ status: 'ON_SITE' }, { status: 'PLANNED', plannedAt: { gte: todayStart, lt: todayEnd } }] },
      }),
      this.prisma.arrival.count({
        where: { OR: [{ status: 'ON_SITE' }, { status: 'PLANNED', plannedAt: { gte: todayStart, lt: weekEnd } }] },
      }),
      // Метрика утечки сделок мимо приложения (задача 017, п.7 — рядом с
      // аналогичной метрикой анонсов из 014).
      this.prisma.cargo.count({ where: { closedAt: { gte: since }, closeOutcome: { not: null } } }),
      this.prisma.cargo.count({ where: { closedAt: { gte: since }, closeOutcome: 'FOUND_OUTSIDE' } }),
    ]);

    return {
      drivers,
      companies,
      cargosPublished,
      dealsActive,
      dealsDelivered,
      pendingDocs,
      openComplaints,
      period: period ?? 'today',
      growth: { drivers: newDrivers, companies: newCompanies, cargos: newCargos, delivered: deliveredInPeriod },
      onSiteToday,
      onSiteWeek,
      cargosClosedTotal,
      cargosClosedOutside,
      cargosClosedOutsideSharePct: cargosClosedTotal === 0 ? null : Math.round((cargosClosedOutside / cargosClosedTotal) * 100),
    };
  }

  /// Блок «Требует внимания» (задача 028, п.4) — с него админ начинает
  /// день: документы на проверке (людей, не документов — считаем
  /// distinct водителей/компаний с хотя бы одним PENDING), открытые
  /// жалобы, сделки без движения > 3 дней, непроверенные компании, новые
  /// города. `oldestAgeHours` — для красного счётчика, если старше 24 ч.
  async attention() {
    const staleBefore = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

    const [pendingDriverDocs, pendingCompanyDocs, oldestPendingDoc, openComplaints, staleDeals, unverifiedCompanies, pendingCities] =
      await Promise.all([
        this.prisma.verificationDocument.findMany({
          where: { status: 'PENDING', driverId: { not: null } },
          select: { driverId: true },
          distinct: ['driverId'],
        }),
        this.prisma.verificationDocument.findMany({
          where: { status: 'PENDING', companyId: { not: null } },
          select: { companyId: true },
          distinct: ['companyId'],
        }),
        this.prisma.verificationDocument.findFirst({
          where: { status: 'PENDING' },
          orderBy: { createdAt: 'asc' },
          select: { createdAt: true },
        }),
        this.prisma.complaint.count({ where: { status: { in: ['OPEN', 'IN_REVIEW'] } } }),
        this.prisma.deal.count({ where: { status: { notIn: ['DELIVERED', 'CANCELLED'] }, updatedAt: { lt: staleBefore } } }),
        this.prisma.company.count({ where: { isVerified: false } }),
        this.prisma.city.count({ where: { cityStatus: 'PENDING' } }),
      ]);

    const pendingPeopleCount = pendingDriverDocs.length + pendingCompanyDocs.length;
    const oldestAgeHours = oldestPendingDoc ? Math.floor((Date.now() - oldestPendingDoc.createdAt.getTime()) / (60 * 60 * 1000)) : 0;

    return {
      pendingVerification: { count: pendingPeopleCount, oldestAgeHours },
      openComplaints,
      staleDeals,
      unverifiedCompanies,
      pendingCities,
    };
  }

  /// Единая лента «Последние события» (задача 028, п.5) — audit_log
  /// смешан с регистрациями/новыми грузами/сменами статуса сделок,
  /// отсортирован по дате. Полный список — отдельный GET /admin/audit.
  async recentEvents(limit = 10) {
    const [auditEntries, newDrivers, newCompanies, newCargos, dealChanges] = await Promise.all([
      this.prisma.auditLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: limit,
        include: { actor: { select: { name: true, email: true } } },
      }),
      this.prisma.driver.findMany({ orderBy: { createdAt: 'desc' }, take: limit, select: { id: true, fullName: true, createdAt: true } }),
      this.prisma.company.findMany({ orderBy: { createdAt: 'desc' }, take: limit, select: { id: true, name: true, createdAt: true } }),
      this.prisma.cargo.findMany({
        orderBy: { createdAt: 'desc' },
        take: limit,
        select: { id: true, createdAt: true, point: { select: { name: true } } },
      }),
      this.prisma.deal.findMany({
        orderBy: { updatedAt: 'desc' },
        take: limit,
        select: { id: true, status: true, updatedAt: true, driver: { select: { fullName: true } } },
      }),
    ]);

    type Event = { type: string; title: string; entityId: string; createdAt: Date; metadata?: unknown };
    const events: Event[] = [
      ...auditEntries.map((a) => ({
        type: 'audit',
        title: `${a.action} · ${a.actor?.name ?? a.actor?.email ?? '—'}`,
        entityId: a.entityId ?? '',
        createdAt: a.createdAt,
        metadata: { entityType: a.entityType, action: a.action },
      })),
      ...newDrivers.map((d) => ({ type: 'driver_registered', title: d.fullName, entityId: d.id, createdAt: d.createdAt })),
      ...newCompanies.map((c) => ({ type: 'company_registered', title: c.name, entityId: c.id, createdAt: c.createdAt })),
      ...newCargos.map((c) => ({ type: 'cargo_published', title: JSON.stringify(c.point.name), entityId: c.id, createdAt: c.createdAt })),
      ...dealChanges.map((d) => ({
        type: 'deal_status',
        title: `${d.driver.fullName} · ${d.status}`,
        entityId: d.id,
        createdAt: d.updatedAt,
      })),
    ];

    events.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return events.slice(0, limit);
  }

  /// Полный журнал (кнопка «Журнал →», п.5) — только audit_log, с
  /// фильтрами; у «Последних событий» — смешанная лента, здесь — сырые
  /// записи для разбора конкретного действия.
  async auditLog(params: { actorUserId?: string; entityType?: string; since?: Date; limit?: number }) {
    const entries = await this.prisma.auditLog.findMany({
      where: {
        ...(params.actorUserId ? { actorUserId: params.actorUserId } : {}),
        ...(params.entityType ? { entityType: params.entityType } : {}),
        ...(params.since ? { createdAt: { gte: params.since } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: params.limit ?? 100,
      include: { actor: { select: { name: true, email: true } } },
    });
    return entries.map((a) => ({
      id: a.id,
      action: a.action,
      entityType: a.entityType,
      entityId: a.entityId,
      actorName: a.actor?.name ?? a.actor?.email ?? null,
      metadata: a.metadata,
      createdAt: a.createdAt,
    }));
  }

  /// Глобальный поиск сверху (п.6) — сгруппированные результаты по типам,
  /// до 5 на тип, только id+заголовок (переход — дело клиента).
  async search(q: string) {
    const query = q.trim();
    if (!query) return { drivers: [], companies: [], cargos: [], deals: [] };

    const [drivers, companies, cargos, deals] = await Promise.all([
      this.prisma.driver.findMany({
        where: {
          OR: [
            { fullName: { contains: query, mode: 'insensitive' } },
            { user: { phone: { contains: query, mode: 'insensitive' } } },
            { vehicles: { some: { plateNumber: { contains: query, mode: 'insensitive' } } } },
          ],
        },
        take: 5,
        select: { id: true, fullName: true },
      }),
      this.prisma.company.findMany({
        where: {
          OR: [
            { name: { contains: query, mode: 'insensitive' } },
            { nameRu: { contains: query, mode: 'insensitive' } },
            { taxId: { contains: query, mode: 'insensitive' } },
            { members: { some: { user: { email: { contains: query, mode: 'insensitive' } } } } },
          ],
        },
        take: 5,
        select: { id: true, name: true },
      }),
      this.prisma.cargo.findMany({
        where: { id: { contains: query, mode: 'insensitive' } },
        take: 5,
        select: { id: true, point: { select: { name: true } } },
      }),
      this.prisma.deal.findMany({
        where: { id: { contains: query, mode: 'insensitive' } },
        take: 5,
        select: { id: true, driver: { select: { fullName: true } } },
      }),
    ]);

    return {
      drivers: drivers.map((d) => ({ id: d.id, title: d.fullName })),
      companies: companies.map((c) => ({ id: c.id, title: c.name })),
      cargos: cargos.map((c) => ({ id: c.id, title: c.point.name })),
      deals: deals.map((d) => ({ id: d.id, title: d.driver.fullName })),
    };
  }

  // -- cargos / deals (задача 028, этап A/C) -------------------------------

  async searchCargos(query: CargoSearchQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const q = query.q?.trim();

    const where: Record<string, unknown> = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.companyId ? { companyId: query.companyId } : {}),
      ...(query.destinationCountryId ? { destinationCountryId: query.destinationCountryId } : {}),
      ...(q ? { id: { contains: q, mode: 'insensitive' } } : {}),
    };

    const [total, cargos] = await Promise.all([
      this.prisma.cargo.count({ where: where as never }),
      this.prisma.cargo.findMany({
        where: where as never,
        include: {
          point: { select: { name: true } },
          destinationCountry: { select: { name: true } },
          destinationCity: { select: { name: true } },
          bodyType: { select: { name: true } },
          company: { select: { id: true, name: true } },
          _count: { select: { responses: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const items = cargos.map((c) => ({
      id: c.id,
      pointName: c.point.name,
      destinationCountryName: c.destinationCountry.name,
      destinationCityName: c.destinationCity?.name ?? null,
      bodyTypeName: c.bodyType.name,
      weightKg: c.weightKg ? Number(c.weightKg) : null,
      price: Number(c.price),
      currency: c.currency,
      companyId: c.company.id,
      companyName: c.company.name,
      responseCount: c._count.responses,
      status: c.status,
      publishedAt: c.publishedAt,
    }));

    return { items, total };
  }

  async searchDeals(query: DealSearchQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const q = query.q?.trim();
    const staleBefore = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000);

    const statusFilter =
      query.status === 'active' ? { notIn: ['DELIVERED', 'CANCELLED'] } : query.status ? query.status : undefined;

    const where: Record<string, unknown> = {
      ...(statusFilter ? { status: statusFilter } : {}),
      ...(query.stale ? { status: statusFilter ?? { notIn: ['DELIVERED', 'CANCELLED'] }, updatedAt: { lt: staleBefore } } : {}),
      ...(query.driverId ? { driverId: query.driverId } : {}),
      ...(query.companyId ? { companyId: query.companyId } : {}),
      ...(q ? { id: { contains: q, mode: 'insensitive' } } : {}),
    };

    const [total, deals] = await Promise.all([
      this.prisma.deal.count({ where: where as never }),
      this.prisma.deal.findMany({
        where: where as never,
        include: {
          cargo: { select: { point: { select: { name: true } }, destinationCountry: { select: { name: true } }, price: true, currency: true } },
          driver: { select: { id: true, fullName: true } },
          company: { select: { id: true, name: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);

    const now = Date.now();
    const items = deals.map((d) => ({
      id: d.id,
      pointName: d.cargo.point.name,
      destinationCountryName: d.cargo.destinationCountry.name,
      driverId: d.driver.id,
      driverName: d.driver.fullName,
      companyId: d.company.id,
      companyName: d.company.name,
      price: Number(d.cargo.price),
      currency: d.cargo.currency,
      status: d.status,
      staleDays: d.status === 'DELIVERED' || d.status === 'CANCELLED' ? 0 : Math.floor((now - d.updatedAt.getTime()) / (24 * 60 * 60 * 1000)),
      createdAt: d.createdAt,
    }));

    return { items, total };
  }

  // -- cargo detail & actions (задача 028, п.15) --------------------------------

  private async kztRateFor(currency: string): Promise<number | null> {
    if (currency === 'KZT') return 1;
    const rate = await this.prisma.exchangeRate.findFirst({ where: { currency: currency as never }, orderBy: { effectiveDate: 'desc' } });
    return rate ? Number(rate.rateToKzt) : null;
  }

  async cargoDetail(id: string) {
    const cargo = await this.prisma.cargo.findUnique({
      where: { id },
      include: {
        point: { select: { name: true } },
        destinationCountry: { select: { name: true } },
        destinationCity: { select: { name: true } },
        bodyType: { select: { name: true } },
        company: { select: { id: true, name: true } },
        responses: { include: { driver: { select: { id: true, fullName: true } } }, orderBy: { createdAt: 'desc' } },
        deals: { select: { id: true, status: true, driverId: true, driver: { select: { fullName: true } } } },
      },
    });
    if (!cargo) throw new NotFoundException('Cargo not found');

    const auditLog = await this.prisma.auditLog.findMany({
      where: { entityType: 'Cargo', entityId: id },
      orderBy: { createdAt: 'desc' },
      take: 30,
      include: { actor: { select: { name: true, email: true } } },
    });

    const kztRate = await this.kztRateFor(cargo.currency);

    return {
      id: cargo.id,
      companyId: cargo.company.id,
      companyName: cargo.company.name,
      pointName: cargo.point.name,
      destinationCountryId: cargo.destinationCountryId,
      destinationCountryName: cargo.destinationCountry.name,
      destinationCityId: cargo.destinationCityId,
      destinationCityName: cargo.destinationCity?.name ?? null,
      bodyTypeId: cargo.bodyTypeId,
      bodyTypeName: cargo.bodyType.name,
      weightKg: cargo.weightKg ? Number(cargo.weightKg) : null,
      volumeM3: cargo.volumeM3 ? Number(cargo.volumeM3) : null,
      photoUrls: cargo.photoUrls,
      price: Number(cargo.price),
      currency: cargo.currency,
      priceInKzt: kztRate != null ? Number(cargo.price) * kztRate : null,
      readyDate: cargo.readyDate,
      description: cargo.description,
      status: cargo.status,
      publishedAt: cargo.publishedAt,
      expiresAt: cargo.expiresAt,
      archivedAt: cargo.archivedAt,
      createdAt: cargo.createdAt,
      responses: cargo.responses.map((r) => ({
        id: r.id,
        driverId: r.driver.id,
        driverName: r.driver.fullName,
        message: r.message,
        status: r.status,
        createdAt: r.createdAt,
      })),
      deal: cargo.deals[0] ? { id: cargo.deals[0].id, status: cargo.deals[0].status, driverName: cargo.deals[0].driver.fullName } : null,
      auditLog: auditLog.map((a) => ({
        id: a.id,
        action: a.action,
        actorName: a.actor?.name ?? a.actor?.email ?? null,
        metadata: a.metadata,
        createdAt: a.createdAt,
      })),
    };
  }

  /// «Исправить» (п.15) — те же поля, что при публикации, плюс обязательная
  /// причина; в audit_log пишем старое/новое по каждому изменённому полю
  /// (общий паттерн редактирования, задача 028, п.18).
  async updateCargo(id: string, adminUserId: string, dto: AdminUpdateCargoDto) {
    const existing = await this.prisma.cargo.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Cargo not found');

    const readyDate = dto.readyDate ? new Date(dto.readyDate) : existing.readyDate;
    const expiresAt = dto.readyDate != null ? new Date(readyDate.getTime() + 48 * 60 * 60 * 1000) : existing.expiresAt;

    const fields: Array<[keyof AdminUpdateCargoDto, unknown, unknown]> = [
      ['destinationCountryId', existing.destinationCountryId, dto.destinationCountryId],
      ['destinationCityId', existing.destinationCityId, dto.destinationCityId],
      ['bodyTypeId', existing.bodyTypeId, dto.bodyTypeId],
      ['weightKg', existing.weightKg ? Number(existing.weightKg) : null, dto.weightKg],
      ['volumeM3', existing.volumeM3 ? Number(existing.volumeM3) : null, dto.volumeM3],
      ['photoUrls', existing.photoUrls, dto.photoUrls],
      ['price', Number(existing.price), dto.price],
      ['currency', existing.currency, dto.currency],
      ['readyDate', existing.readyDate.toISOString(), dto.readyDate],
      ['description', existing.description, dto.description],
    ];
    const changes = Object.fromEntries(
      fields.filter(([, oldValue, newValue]) => newValue !== undefined && String(oldValue) !== String(newValue)).map(([key, oldValue, newValue]) => [key, { old: oldValue, new: newValue }]),
    );

    const updated = await this.prisma.cargo.update({
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
    });

    await this.logAudit(adminUserId, 'CARGO_UPDATED', 'Cargo', id, { reason: dto.reason, changes });
    return { id: updated.id };
  }

  /// «Снять с публикации» (п.15) — ARCHIVED, не CANCELLED: это не отмена
  /// груза логистом (тот путь уже есть в `cargos.service.remove`), а именно
  /// административное снятие с витрины — отклики/сделки не трогаем.
  async unpublishCargo(id: string, adminUserId: string, reason: string) {
    const cargo = await this.prisma.cargo.findUnique({ where: { id } });
    if (!cargo) throw new NotFoundException('Cargo not found');

    await this.prisma.cargo.update({ where: { id }, data: { status: 'ARCHIVED', archivedAt: new Date() } });
    await this.logAudit(adminUserId, 'CARGO_UNPUBLISHED', 'Cargo', id, { reason });
    const contactUserId = await resolveCargoContactUserId(this.prisma, cargo);
    if (contactUserId) {
      await this.notifications?.notify({ userIds: [contactUserId] }, 'CARGO_UNPUBLISHED', { cargoId: id, reason });
    }

    return { id, status: 'ARCHIVED' };
  }

  // -- deal detail & actions (задача 028, п.17) ----------------------------------

  private static readonly DEAL_PROGRESSION = ['SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'] as const;
  private static readonly DEAL_TIMESTAMP_FIELD: Record<string, string> = {
    CONFIRMED_BY_DRIVER: 'confirmedAt',
    LOADED: 'loadedAt',
    IN_TRANSIT: 'inTransitAt',
    DELIVERED: 'deliveredAt',
  };

  async dealDetail(id: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id },
      include: {
        cargo: { include: { point: { select: { name: true } }, destinationCountry: { select: { name: true } } } },
        driver: { select: { id: true, fullName: true } },
        company: { select: { id: true, name: true } },
        contactEvents: { orderBy: { createdAt: 'desc' } },
      },
    });
    if (!deal) throw new NotFoundException('Deal not found');

    const auditLog = await this.prisma.auditLog.findMany({
      where: { entityType: 'Deal', entityId: id },
      orderBy: { createdAt: 'desc' },
      take: 30,
      include: { actor: { select: { name: true, email: true } } },
    });
    const kztRate = await this.kztRateFor(deal.cargo.currency);

    const statusHistory = [
      { status: 'SELECTED', at: deal.createdAt },
      deal.confirmedAt ? { status: 'CONFIRMED_BY_DRIVER', at: deal.confirmedAt } : null,
      deal.loadedAt ? { status: 'LOADED', at: deal.loadedAt } : null,
      deal.inTransitAt ? { status: 'IN_TRANSIT', at: deal.inTransitAt } : null,
      deal.deliveredAt ? { status: 'DELIVERED', at: deal.deliveredAt } : null,
    ].filter((e): e is { status: string; at: Date } => e !== null);

    return {
      id: deal.id,
      cargoId: deal.cargoId,
      pointName: deal.cargo.point.name,
      destinationCountryName: deal.cargo.destinationCountry.name,
      price: Number(deal.cargo.price),
      currency: deal.cargo.currency,
      priceInKzt: kztRate != null ? Number(deal.cargo.price) * kztRate : null,
      driverId: deal.driver.id,
      driverName: deal.driver.fullName,
      companyId: deal.company.id,
      companyName: deal.company.name,
      status: deal.status,
      cancelReason: deal.cancelReason,
      cancelledByRole: deal.cancelledByRole,
      staleDays:
        deal.status === 'DELIVERED' || deal.status === 'CANCELLED'
          ? 0
          : Math.floor((Date.now() - deal.updatedAt.getTime()) / (24 * 60 * 60 * 1000)),
      statusHistory,
      calls: deal.contactEvents.map((e) => ({ id: e.id, type: e.type, createdAt: e.createdAt })),
      createdAt: deal.createdAt,
      auditLog: auditLog.map((a) => ({
        id: a.id,
        action: a.action,
        actorName: a.actor?.name ?? a.actor?.email ?? null,
        metadata: a.metadata,
        createdAt: a.createdAt,
      })),
    };
  }

  /// Переписка — только просмотр, без правки/удаления (п.17). Каждое
  /// открытие пишется в audit_log отдельно от загрузки самой карточки
  /// сделки — лог должен отражать именно обращение к личной переписке.
  async dealChat(id: string, adminUserId: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id } });
    if (!deal) throw new NotFoundException('Deal not found');

    const chat = await this.prisma.chat.findFirst({ where: { dealId: id } });
    const messages = chat
      ? await this.prisma.message.findMany({ where: { chatId: chat.id }, orderBy: { createdAt: 'asc' } })
      : [];

    await this.logAudit(adminUserId, 'ADMIN_VIEWED_CHAT', 'Deal', id, {});

    return messages.map((m) => ({
      id: m.id,
      senderUserId: m.senderUserId,
      originalText: m.originalText,
      originalLang: m.originalLang,
      translations: m.translations,
      createdAt: m.createdAt,
    }));
  }

  /// «Исправить статус» — только на соседний шаг, вперёд или назад (п.17).
  /// При движении назад снимаем отметку времени шага, который отменяем —
  /// иначе `loadedAt` остался бы висеть на сделке, которая снова LOADED не
  /// значит.
  async advanceDealStatusByAdmin(id: string, adminUserId: string, dto: AdminDealStatusDto) {
    const deal = await this.prisma.deal.findUnique({ where: { id } });
    if (!deal) throw new NotFoundException('Deal not found');

    const progression = AdminService.DEAL_PROGRESSION;
    const currentIndex = progression.indexOf(deal.status as (typeof progression)[number]);
    const nextIndex = progression.indexOf(dto.status as (typeof progression)[number]);
    if (currentIndex === -1 || nextIndex === -1 || Math.abs(nextIndex - currentIndex) !== 1) {
      throw new BadRequestException(`Can only move a deal to the adjacent status, not from ${deal.status} to ${dto.status}`);
    }

    const data: Record<string, unknown> = { status: dto.status };
    if (nextIndex > currentIndex) {
      const field = AdminService.DEAL_TIMESTAMP_FIELD[dto.status];
      if (field) data[field] = new Date();
    } else {
      const field = AdminService.DEAL_TIMESTAMP_FIELD[deal.status];
      if (field) data[field] = null;
    }

    await this.prisma.deal.update({ where: { id }, data });
    await this.logAudit(adminUserId, 'DEAL_STATUS_FIXED', 'Deal', id, { reason: dto.reason, from: deal.status, to: dto.status });
    await this.notifyDealStatusChange(deal, dto.status);

    return { id, status: dto.status };
  }

  /// Push/WeCom обеим сторонам при смене статуса сделки админом (задача
  /// 029, п.7 — заменяет старую NOTIFICATION_QUEUED-заглушку) — тот же
  /// канал/событие DEAL_STATUS, что и у обычной смены статуса (011), не
  /// отдельный шаблон: с точки зрения получателя разницы нет.
  private async notifyDealStatusChange(deal: { id: string; driverId: string; companyId: string; cargoId: string }, status: string) {
    const [driver, cargo] = await Promise.all([
      this.prisma.driver.findUnique({ where: { id: deal.driverId }, select: { userId: true } }),
      this.prisma.cargo.findUnique({ where: { id: deal.cargoId }, select: { companyId: true, publishedByUserId: true } }),
    ]);
    if (!driver) return;
    const contactUserId = cargo ? await resolveCargoContactUserId(this.prisma, cargo) : null;
    await this.notifications?.notify(
      { userIds: [driver.userId, ...(contactUserId ? [contactUserId] : [])], companyId: deal.companyId },
      'DEAL_STATUS',
      { dealId: deal.id, status },
    );
  }

  /// «Отменить сделку» админом (п.17) — причина обязательна,
  /// `cancelledByRole = ADMIN` (значение добавлено в `ReviewAuthorRole`
  /// миграцией). Рейтинг сторон не трогаем — он считается только из
  /// `Review`, сюда вообще не пишем.
  async cancelDealByAdmin(id: string, adminUserId: string, reason: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id } });
    if (!deal) throw new NotFoundException('Deal not found');
    if (deal.status === 'DELIVERED' || deal.status === 'CANCELLED') {
      throw new BadRequestException('This deal can no longer be cancelled');
    }

    await this.prisma.deal.update({
      where: { id },
      data: { status: 'CANCELLED', cancelReason: reason, cancelledByRole: 'ADMIN' },
    });
    await this.logAudit(adminUserId, 'DEAL_CANCELLED_BY_ADMIN', 'Deal', id, { reason });
    await this.notifyDealStatusChange(deal, 'CANCELLED');

    return { id, status: 'CANCELLED' };
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

  /// Поля распознавания, у которых есть соответствующий тип в чёрном
  /// Блок «Распознано» экрана проверки (макет 25, п.22) — распознанные
  /// поля + живая проверка по чёрному списку/дублям для полей, у которых
  /// есть тип идентификатора. Считается только для одного документа за
  /// раз (вызывается при открытии карточки на проверке), не для списков —
  /// checkMatches бьёт в базу на каждое поле.
  /// Задача 032, п.4 — ИИН/номер прав в document_recognitions.fields
  /// хранятся только маской+шифром (см. recognition.service.ts), `value`
  /// у таких полей нет. Везде, где раньше читали `field.value` для
  /// сопоставления с чёрным списком, нужно сперва расшифровать;
  /// не-чувствительные поля (ФИО, госномер, VIN...) остались как есть —
  /// там `value` и есть открытый текст, его читаем напрямую.
  private resolveRecognizedValue(field: { value?: string; valueEncrypted?: string } | undefined): string | null {
    if (!field) return null;
    if (typeof field.value === 'string') return field.value;
    if (typeof field.valueEncrypted === 'string') return decryptIdentifier(field.valueEncrypted);
    return null;
  }

  async documentRecognition(documentId: string) {
    const doc = await this.prisma.verificationDocument.findUnique({
      where: { id: documentId },
      include: { recognition: true },
    });
    if (!doc) throw new NotFoundException('Document not found');
    if (!doc.recognition) return { status: 'PENDING' as const, engineVersion: null, durationMs: null, fields: {} };

    const owner = doc.vehicleId
      ? ({ ownerType: 'VEHICLE', ownerId: doc.vehicleId } as const)
      : doc.driverId
        ? ({ ownerType: 'DRIVER', ownerId: doc.driverId } as const)
        : doc.companyId
          ? ({ ownerType: 'COMPANY', ownerId: doc.companyId } as const)
          : null;

    const rawFields = (doc.recognition.fields ?? {}) as Record<
      string,
      { value?: string; valueMasked?: string; valueEncrypted?: string; confidence: number; checksumOk: boolean | null; needsReview: boolean }
    >;
    const fields: Record<string, unknown> = {};
    for (const [key, field] of Object.entries(rawFields)) {
      const identifierType = RECOGNIZED_FIELD_IDENTIFIER_TYPE[key];
      let match: 'blacklisted' | 'duplicate' | 'ok' | null = null;
      if (identifierType && this.identifiers) {
        const rawValue = this.resolveRecognizedValue(field);
        if (rawValue) {
          const result = await this.identifiers.checkMatches(identifierType, rawValue, owner ?? undefined);
          match = result.blocked ? 'blacklisted' : result.duplicateOwner ? 'duplicate' : 'ok';
        }
      }
      // Клиенту — маска для чувствительных полей, не то, что хранится
      // под valueEncrypted; ciphertext наружу вообще не отдаём.
      fields[key] = { value: field.value ?? field.valueMasked, confidence: field.confidence, checksumOk: field.checksumOk, needsReview: field.needsReview, match };
    }

    return {
      status: doc.recognition.status,
      engineVersion: doc.recognition.engineVersion,
      durationMs: doc.recognition.durationMs,
      fields,
    };
  }

  /// Задача 032, п.7 — кнопка «Распознать заново»: нужна, когда
  /// распознавание закончилось `SKIPPED`/`FAILED` (контейнер был
  /// недоступен все 3 попытки, или документ почему-то нечитаем) — админ
  /// может повторить вручную, не дожидаясь новой загрузки документа.
  async retryRecognition(documentId: string): Promise<{ id: string }> {
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id: documentId } });
    if (!doc) throw new NotFoundException('Document not found');
    await this.recognition?.enqueue(documentId);
    return { id: documentId };
  }

  /// Задача 032, п.4 — полное значение чувствительного распознанного поля
  /// (ИИН/номер прав) ДО одобрения документа — та же пара
  /// «расшифровать + записать в журнал», что у revealIdentifier, но
  /// источник — document_recognitions.fields, не identifiers (строки туда
  /// ещё нет, документ не одобрен).
  async revealRecognizedField(documentId: string, field: string, adminUserId: string): Promise<{ value: string | null }> {
    if (!this.identifiers) return { value: null };
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id: documentId }, include: { recognition: true } });
    if (!doc) throw new NotFoundException('Document not found');
    const fields = (doc.recognition?.fields ?? {}) as Record<string, { valueEncrypted?: string } | undefined>;
    const valueEncrypted = fields[field]?.valueEncrypted;
    if (!valueEncrypted) return { value: null };
    const value = await this.identifiers.decryptAndAudit(valueEncrypted, adminUserId, 'DOCUMENT_FIELD_REVEALED', 'VerificationDocument', documentId, { field });
    return { value };
  }

  /// Задача 032, п.2 — последняя проверка перед «Подтвердить», не только в
  /// момент одобрения отдельного документа: собирает ⛔-совпадения и среди
  /// уже ПОДТВЕРЖДЁННЫХ идентификаторов владельца (`identifiers`), и среди
  /// РАСПОЗНАННЫХ, но ещё не подтверждённых полей его документов (OCR мог
  /// найти ⛔-ИИН на правах, которые админ одобрил после селфи — тогда
  /// identifiers уже содержит телефон, но не ИИН; без этой проверки
  /// подтверждение прошло бы).
  private async blacklistBlocksForOwner(
    ownerType: 'DRIVER' | 'COMPANY',
    ownerId: string,
    documentsWhere: Prisma.VerificationDocumentWhereInput,
  ): Promise<Array<{ type: string; valueMasked: string; reason: string }>> {
    if (!this.identifiers) return [];

    const confirmed = await this.identifiers.findActiveBlocksForOwner(ownerType, ownerId);

    const docs = await this.prisma.verificationDocument.findMany({
      where: { ...documentsWhere, recognition: { isNot: null } },
      include: { recognition: true },
    });
    const recognizedChecks: Array<{ type: IdentifierTypeValue; value: string }> = [];
    for (const doc of docs) {
      const fields = (doc.recognition?.fields ?? {}) as Record<string, { value?: string; valueEncrypted?: string } | undefined>;
      for (const [key, field] of Object.entries(fields)) {
        const type = RECOGNIZED_FIELD_IDENTIFIER_TYPE[key];
        const value = type ? this.resolveRecognizedValue(field) : null;
        if (type && value) recognizedChecks.push({ type, value });
      }
    }
    const recognizedBlocks = await Promise.all(
      recognizedChecks.map(async (check) => {
        const match = await this.identifiers!.checkMatches(check.type, check.value, { ownerType, ownerId });
        // Задача 032, п.4 — valueMasked в НАХОДКЕ блокировки тоже не должен
        // быть открытым текстом: та же маска, что и у подтверждённых
        // identifiers (эта находка попадёт в 409-ответ и в audit_log).
        return match.blocked
          ? { type: check.type, valueMasked: maskIdentifier(check.type, normalizeIdentifier(check.type, check.value)), reason: match.blocked.reason }
          : null;
      }),
    );

    return [...confirmed, ...recognizedBlocks.filter((b): b is { type: IdentifierTypeValue; valueMasked: string; reason: string } => b !== null)];
  }

  /// Задача 032, п.3 — общая часть для «текущего документа» и «добора» по
  /// остальным одобренным документам того же водителя: ИИН/номер прав не
  /// имеют колонки на Driver, подтверждаются только через identifiers.
  /// `overrides` — правка админа (dto.confirmedFields), есть только у
  /// документа, который проверяется прямо сейчас.
  private async confirmFieldlessDriverIdentifiers(
    fields: Record<string, { value?: string; valueEncrypted?: string } | undefined>,
    overrides: Record<string, string> | undefined,
    driverId: string,
    sourceDocumentId: string,
    adminUserId: string,
  ): Promise<{ reason: string } | null> {
    if (!this.identifiers) return null;
    let blacklistHit: { reason: string } | null = null;
    for (const [field, type] of [['iin', 'IIN'], ['licenseNumber', 'DRIVER_LICENSE_NO']] as const) {
      const value = overrides?.[field] ?? this.resolveRecognizedValue(fields[field]);
      if (!value) continue;
      const match = await this.identifiers.checkMatches(type, value, { ownerType: 'DRIVER', ownerId: driverId });
      if (match.blocked) blacklistHit = match.blocked;
      await this.identifiers.confirmIdentifier({
        type,
        rawValue: value,
        ownerType: 'DRIVER',
        ownerId: driverId,
        sourceDocumentId,
        confirmedByUserId: adminUserId,
      });
    }
    return blacklistHit;
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
      include: {
        driver: { include: { user: true } },
        company: true,
        vehicle: true,
        recognition: true,
        reviewedBy: { select: { id: true, name: true, email: true } },
      },
    });

    // Задача 031, п.23 — правка админа (поле без своей колонки в БД — ИИН,
    // номер прав) по сравнению с тем, что распознал OCR, идёт в audit_log
    // отдельной записью «распознано X → исправлено Y», до записи самого
    // подтверждённого значения. Задача 032, п.4 — в сам журнал полные
    // значения не пишем, только маски (audit_log не настолько защищён,
    // как identifiers.valueEncrypted).
    const recognizedFields = (updated.recognition?.fields ?? {}) as Record<string, { value?: string; valueEncrypted?: string } | undefined>;
    for (const [field, confirmedValue] of Object.entries(dto.confirmedFields ?? {})) {
      const recognizedValue = this.resolveRecognizedValue(recognizedFields[field]);
      if (recognizedValue && recognizedValue !== confirmedValue) {
        const identifierType = RECOGNIZED_FIELD_IDENTIFIER_TYPE[field];
        await this.logAudit(adminUserId, 'DOCUMENT_FIELD_CORRECTED', 'VerificationDocument', id, {
          field,
          recognized: identifierType ? maskIdentifier(identifierType, normalizeIdentifier(identifierType, recognizedValue)) : recognizedValue,
          corrected: identifierType ? maskIdentifier(identifierType, normalizeIdentifier(identifierType, confirmedValue)) : confirmedValue,
        });
      }
    }

    await this.logAudit(adminUserId, dto.status === 'APPROVED' ? 'DOCUMENT_APPROVED' : 'DOCUMENT_REJECTED', 'VerificationDocument', id, {
      rejectReason: dto.rejectReason,
    });

    // Задача 031, этап C, п.15 — совпадение с чёрным списком останавливает
    // автоматическое подтверждение: ниже `isVerified` выставляется только
    // когда `!blacklistHit`, явного решения админа это не требует — сам
    // документ может быть одобрен (это оценка его подлинности), а вот
    // субъект (водитель/машина/компания) ⛔ не верифицируется молча.
    // Дубль у другого активного владельца — только предупреждение,
    // подтверждению не мешает.
    let blacklistHit: { reason: string } | null = null;

    if (dto.status === 'APPROVED') {
      if (updated.driverId && updated.driver) {
        const phone = updated.driver.user.phone;
        if (phone && this.identifiers) {
          const match = await this.identifiers.checkMatches('PHONE', phone, { ownerType: 'DRIVER', ownerId: updated.driverId });
          if (match.blocked) blacklistHit = match.blocked;
          await this.identifiers.confirmIdentifier({
            type: 'PHONE',
            rawValue: phone,
            ownerType: 'DRIVER',
            ownerId: updated.driverId,
            sourceDocumentId: id,
            confirmedByUserId: adminUserId,
          });
        }

        // Задача 032, п.3 — другие уже одобренные документы этого водителя
        // могли быть проверены ДО того, как это подтверждение появилось
        // (или без правки — п.23 раньше сохранял ИИН/номер прав только
        // когда админ их редактировал, молчаливое согласие терялось).
        // Добираем их здесь же — confirmIdentifier делает upsert по
        // (ownerType, ownerId, type), повторный вызов безопасен.
        const otherApprovedDocs = await this.prisma.verificationDocument.findMany({
          where: { driverId: updated.driverId, status: 'APPROVED', id: { not: id }, recognition: { isNot: null } },
          include: { recognition: true },
        });
        for (const otherDoc of otherApprovedDocs) {
          const otherFields = (otherDoc.recognition?.fields ?? {}) as Record<string, { value: string } | undefined>;
          const hit = await this.confirmFieldlessDriverIdentifiers(otherFields, undefined, updated.driverId, otherDoc.id, adminUserId);
          if (hit) blacklistHit = hit;
        }

        // ИИН/номер прав (задача 031, п.23) — без своей колонки на Driver,
        // живут только в identifiers; подтверждаются значением, с которым
        // согласился админ: правкой (dto.confirmedFields), а если он просто
        // согласился молча — тем, что распознал OCR (задача 032, п.3).
        const hit = await this.confirmFieldlessDriverIdentifiers(recognizedFields, dto.confirmedFields, updated.driverId, id, adminUserId);
        if (hit) blacklistHit = hit;

        // Верифицирован, только когда одобрены ВСЕ обязательные документы
        // личности (селфи + права) — задача 031, этап A: машины (техпаспорта
        // тягача/прицепа) проверяются отдельно, см. блок ниже.
        const approved = await this.prisma.verificationDocument.findMany({
          where: { driverId: updated.driverId, status: 'APPROVED' },
          select: { type: true },
        });
        const approvedTypes = new Set(approved.map((d) => d.type));
        const allRequiredApproved = REQUIRED_DRIVER_DOC_TYPES.every((type) => approvedTypes.has(type));
        if (allRequiredApproved && !blacklistHit) {
          await this.prisma.driver.update({ where: { id: updated.driverId }, data: { isVerified: true } });
        }
      }
      // Задача 031, этап A, п.3-4 — техпаспорт принадлежит конкретной машине
      // гаража; её одобрение подтверждает именно эту машину, не всего
      // водителя и не остальные машины в гараже.
      if (updated.vehicleId && updated.vehicle && (updated.type === 'VEHICLE_PASSPORT' || updated.type === 'TRAILER_PASSPORT')) {
        const vehicle = updated.vehicle;
        if (this.identifiers) {
          const checks: Array<{ type: 'PLATE' | 'VIN'; value: string }> = [
            ...(vehicle.plateNumber ? [{ type: 'PLATE' as const, value: vehicle.plateNumber }] : []),
            ...(vehicle.vin ? [{ type: 'VIN' as const, value: vehicle.vin }] : []),
          ];
          for (const check of checks) {
            const match = await this.identifiers.checkMatches(check.type, check.value, { ownerType: 'VEHICLE', ownerId: vehicle.id });
            // Госномер меняет владельца при перепродаже машины — дубль там
            // не блокирует; только настоящий чёрный список.
            if (match.blocked) blacklistHit = match.blocked;
            await this.identifiers.confirmIdentifier({
              type: check.type,
              rawValue: check.value,
              ownerType: 'VEHICLE',
              ownerId: vehicle.id,
              sourceDocumentId: id,
              confirmedByUserId: adminUserId,
            });
          }
        }
        if (!blacklistHit) {
          await this.prisma.vehicle.update({ where: { id: updated.vehicleId }, data: { isVerified: true } });
        }
      }
      if (updated.companyId && updated.company) {
        if (updated.company.taxId && this.identifiers) {
          const country = await this.prisma.country.findUnique({ where: { id: updated.company.countryId }, select: { code: true } });
          const type = country?.code === 'CN' ? 'USCC' : 'BIN';
          const match = await this.identifiers.checkMatches(type, updated.company.taxId, { ownerType: 'COMPANY', ownerId: updated.companyId });
          if (match.blocked) blacklistHit = match.blocked;
          await this.identifiers.confirmIdentifier({
            type,
            rawValue: updated.company.taxId,
            ownerType: 'COMPANY',
            ownerId: updated.companyId,
            sourceDocumentId: id,
            confirmedByUserId: adminUserId,
          });
        }

        const approved = await this.prisma.verificationDocument.findMany({
          where: { companyId: updated.companyId, status: 'APPROVED' },
          select: { type: true },
        });
        const approvedTypes = new Set(approved.map((d) => d.type));
        const allRequiredApproved = REQUIRED_COMPANY_DOC_TYPES.every((type) => approvedTypes.has(type));
        if (allRequiredApproved && !blacklistHit) {
          await this.prisma.company.update({ where: { id: updated.companyId }, data: { isVerified: true } });
        }
      }
    }

    return { ...(await this.docToDto(updated)), blacklistHit };
  }

  /// Прокси вместо presigned-ссылки (задача 028, п.12) — см. комментарий
  /// у [UploadsService.getDocumentStream]. Легаси-документы (сид/старые
  /// загрузки) хранят готовый http(s)-URL — для них просто редирект.
  async documentFileSource(id: string): Promise<{ redirectUrl: string } | { stream: NodeJS.ReadableStream; contentType: string }> {
    const doc = await this.prisma.verificationDocument.findUnique({ where: { id } });
    if (!doc) throw new NotFoundException('Document not found');
    if (/^https?:\/\//.test(doc.fileUrl)) return { redirectUrl: doc.fileUrl };
    return this.uploads.getDocumentStream(doc.fileUrl);
  }

  /// Полное значение идентификатора по кнопке «Показать» (п.16/24) — через
  /// IdentifiersService, который и пишет запись в audit_log.
  async revealIdentifier(identifierId: string, adminUserId: string): Promise<{ value: string | null }> {
    if (!this.identifiers) return { value: null };
    return { value: await this.identifiers.revealIdentifier(identifierId, adminUserId) };
  }

  /// Карточка «Идентификаторы» (п.24) — подтверждённые значения (маски) и
  /// история блокировок конкретного владельца.
  private async identifiersCard(ownerType: 'DRIVER' | 'COMPANY' | 'VEHICLE', ownerId: string) {
    if (!this.identifiers) return { identifiers: [], blockHistory: [] };
    const [identifiers, blockHistory] = await Promise.all([
      this.identifiers.listForOwner(ownerType, ownerId),
      this.identifiers.listBlockHistory(ownerType, ownerId),
    ]);
    return {
      identifiers: identifiers.map((i) => ({ id: i.id, type: i.type, valueMasked: i.valueMasked, confirmedAt: i.createdAt })),
      blockHistory: blockHistory.map((b) => ({
        id: b.id,
        type: b.type,
        valueMasked: b.valueMasked,
        reason: b.reason,
        blockedByName: b.blockedBy.name ?? b.blockedBy.email,
        createdAt: b.createdAt,
        liftedAt: b.liftedAt,
        liftedByName: b.liftedBy?.name ?? b.liftedBy?.email ?? null,
        liftReason: b.liftReason,
      })),
    };
  }

  // -- verification queue by subject (задача 028, этап B) ----------------------

  /// Очередь по людям/компаниям, а не по документам (п.7): карточка —
  /// субъект, у которого есть хотя бы один PENDING документ, с причиной
  /// («Новый» / «Повторно» / «Сменил машину») и сортировкой по тому, кто
  /// ждёт дольше.
  async verificationQueue(type: 'driver' | 'company') {
    if (type === 'company') return this.verificationQueueCompanies();
    return this.verificationQueueDrivers();
  }

  private async verificationQueueDrivers() {
    const pending = await this.prisma.verificationDocument.findMany({
      where: { driverId: { not: null }, status: 'PENDING' },
    });
    if (pending.length === 0) return [];

    const driverIds = [...new Set(pending.map((d) => d.driverId as string))];
    const [drivers, allDocs] = await Promise.all([
      this.prisma.driver.findMany({ where: { id: { in: driverIds } }, select: { id: true, fullName: true, isVerified: true } }),
      this.prisma.verificationDocument.findMany({ where: { driverId: { in: driverIds } } }),
    ]);
    const driverMap = new Map(drivers.map((d) => [d.id, d]));

    return driverIds
      .map((id) => {
        const driver = driverMap.get(id);
        const docsForSubject = allDocs.filter((d) => d.driverId === id);
        const pendingForSubject = docsForSubject.filter((d) => d.status === 'PENDING');
        const oldestPendingAt = pendingForSubject.reduce((a, b) => (a.createdAt < b.createdAt ? a : b)).createdAt;
        const vehiclePending = pendingForSubject.some((d) => d.type === 'VEHICLE_PASSPORT' || d.type === 'TRAILER_PASSPORT');
        const resubmittedType = pendingForSubject.find((d) =>
          docsForSubject.some((prior) => prior.type === d.type && prior.status === 'REJECTED'),
        )?.type;

        let reason: 'NEW' | 'RESUBMITTED' | 'VEHICLE_CHANGED';
        if (driver?.isVerified && vehiclePending) reason = 'VEHICLE_CHANGED';
        else if (resubmittedType) reason = 'RESUBMITTED';
        else reason = 'NEW';

        return {
          subjectId: id,
          subjectName: driver?.fullName ?? '—',
          pendingCount: pendingForSubject.length,
          oldestPendingAt,
          reason,
          resubmittedType: reason === 'RESUBMITTED' ? resubmittedType : null,
        };
      })
      .sort((a, b) => a.oldestPendingAt.getTime() - b.oldestPendingAt.getTime());
  }

  private async verificationQueueCompanies() {
    const pending = await this.prisma.verificationDocument.findMany({
      where: { companyId: { not: null }, status: 'PENDING' },
    });
    if (pending.length === 0) return [];

    const companyIds = [...new Set(pending.map((d) => d.companyId as string))];
    const [companies, allDocs] = await Promise.all([
      this.prisma.company.findMany({ where: { id: { in: companyIds } }, select: { id: true, name: true, isVerified: true } }),
      this.prisma.verificationDocument.findMany({ where: { companyId: { in: companyIds } } }),
    ]);
    const companyMap = new Map(companies.map((c) => [c.id, c]));

    return companyIds
      .map((id) => {
        const company = companyMap.get(id);
        const docsForSubject = allDocs.filter((d) => d.companyId === id);
        const pendingForSubject = docsForSubject.filter((d) => d.status === 'PENDING');
        const oldestPendingAt = pendingForSubject.reduce((a, b) => (a.createdAt < b.createdAt ? a : b)).createdAt;
        const resubmittedType = pendingForSubject.find((d) =>
          docsForSubject.some((prior) => prior.type === d.type && prior.status === 'REJECTED'),
        )?.type;

        return {
          subjectId: id,
          subjectName: company?.name ?? '—',
          pendingCount: pendingForSubject.length,
          oldestPendingAt,
          reason: (resubmittedType ? 'RESUBMITTED' : 'NEW') as 'NEW' | 'RESUBMITTED',
          resubmittedType: resubmittedType ?? null,
        };
      })
      .sort((a, b) => a.oldestPendingAt.getTime() - b.oldestPendingAt.getTime());
  }

  /// Профиль для сверки (п.8) — не весь driverDetail (там лишнее для этого
  /// экрана: сделки, отзывы, сессии), только то, что сверяется с
  /// документами, + ВСЕ документы (включая уже одобренные — для сравнения
  /// селфи/прав между собой).
  async verificationDriverProfile(id: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { id },
      include: { vehicles: { include: { bodyType: true }, orderBy: [{ kind: 'asc' }, { createdAt: 'asc' }] } },
    });
    if (!driver) throw new NotFoundException('Driver not found');

    const documents = await this.prisma.verificationDocument.findMany({
      where: { driverId: id },
      orderBy: { createdAt: 'desc' },
      include: { reviewedBy: { select: { id: true, name: true, email: true } } },
    });

    return {
      id: driver.id,
      fullName: driver.fullName,
      isVerified: driver.isVerified,
      vehicles: driver.vehicles.map((v) => ({
        id: v.id,
        kind: v.kind,
        isVerified: v.isVerified,
        isArchived: v.isArchived,
        plateNumber: v.plateNumber,
        vin: v.vin,
        brand: v.brand,
        bodyTypeName: v.bodyType?.name ?? null,
        capacityTons: v.capacityTons ? Number(v.capacityTons) : null,
        lengthM: v.lengthM ? Number(v.lengthM) : null,
      })),
      documents: documents.map((d) => ({
        id: d.id,
        type: d.type,
        fileUrl: `/admin/documents/${d.id}/file`,
        status: d.status,
        rejectReason: d.rejectReason,
        reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
        reviewedAt: d.reviewedAt,
        createdAt: d.createdAt,
      })),
    };
  }

  async verificationCompanyProfile(id: string) {
    const company = await this.prisma.company.findUnique({ where: { id } });
    if (!company) throw new NotFoundException('Company not found');

    const documents = await this.prisma.verificationDocument.findMany({
      where: { companyId: id },
      orderBy: { createdAt: 'desc' },
      include: { reviewedBy: { select: { id: true, name: true, email: true } } },
    });

    return {
      id: company.id,
      name: company.name,
      nameRu: company.nameRu,
      taxId: company.taxId,
      isVerified: company.isVerified,
      documents: documents.map((d) => ({
        id: d.id,
        type: d.type,
        fileUrl: `/admin/documents/${d.id}/file`,
        status: d.status,
        rejectReason: d.rejectReason,
        reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
        reviewedAt: d.reviewedAt,
        createdAt: d.createdAt,
      })),
    };
  }

  /// «Вернуть на доработку» (п.10) — итог один на человека: отклоняет сразу
  /// несколько отмеченных документов и шлёт ОДНО уведомление со списком
  /// «что переснять», а не по уведомлению на документ.
  async returnDriverForRework(id: string, adminUserId: string, dto: ReturnForReworkDto) {
    const driver = await this.prisma.driver.findUnique({ where: { id } });
    if (!driver) throw new NotFoundException('Driver not found');
    if (dto.decisions.length === 0) throw new BadRequestException('At least one document decision is required');

    const docs = await this.prisma.verificationDocument.findMany({
      where: { id: { in: dto.decisions.map((d) => d.documentId) }, driverId: id },
    });
    if (docs.length !== dto.decisions.length) throw new BadRequestException('Some documents do not belong to this driver');

    await this.prisma.$transaction(
      dto.decisions.map((d) =>
        this.prisma.verificationDocument.update({
          where: { id: d.documentId },
          data: { status: 'REJECTED', rejectReason: d.rejectReason, reviewedByUserId: adminUserId, reviewedAt: new Date() },
        }),
      ),
    );
    await this.prisma.driver.update({ where: { id }, data: { isVerified: false } });

    await this.logAudit(adminUserId, 'DRIVER_RETURNED_FOR_REWORK', 'Driver', id, { note: dto.note, decisions: dto.decisions, crossChecks: dto.crossChecks });
    // Задача 029, п.7 — push должен содержать список документов и причин
    // (formatVerificationReturnedBody), а не только общую заметку; docs
    // уже загружены выше для проверки принадлежности.
    const docsById = new Map(docs.map((d) => [d.id, d]));
    await this.notifications?.notify({ userIds: [driver.userId] }, 'VERIFICATION_RETURNED', {
      note: dto.note,
      documents: dto.decisions.map((d) => ({ type: docsById.get(d.documentId)!.type, reason: d.rejectReason })),
    });

    return { id, isVerified: false };
  }

  async returnCompanyForRework(id: string, adminUserId: string, dto: ReturnForReworkDto) {
    const company = await this.prisma.company.findUnique({ where: { id } });
    if (!company) throw new NotFoundException('Company not found');
    if (dto.decisions.length === 0) throw new BadRequestException('At least one document decision is required');

    const docs = await this.prisma.verificationDocument.findMany({
      where: { id: { in: dto.decisions.map((d) => d.documentId) }, companyId: id },
    });
    if (docs.length !== dto.decisions.length) throw new BadRequestException('Some documents do not belong to this company');

    await this.prisma.$transaction(
      dto.decisions.map((d) =>
        this.prisma.verificationDocument.update({
          where: { id: d.documentId },
          data: { status: 'REJECTED', rejectReason: d.rejectReason, reviewedByUserId: adminUserId, reviewedAt: new Date() },
        }),
      ),
    );
    await this.prisma.company.update({ where: { id }, data: { isVerified: false } });

    await this.logAudit(adminUserId, 'COMPANY_RETURNED_FOR_REWORK', 'Company', id, { note: dto.note, decisions: dto.decisions, crossChecks: dto.crossChecks });
    const owner = await this.prisma.companyMember.findFirst({ where: { companyId: id, role: 'OWNER' }, orderBy: { createdAt: 'asc' } });
    if (owner) {
      const docsById = new Map(docs.map((d) => [d.id, d]));
      await this.notifications?.notify({ userIds: [owner.userId] }, 'VERIFICATION_RETURNED', {
        note: dto.note,
        documents: dto.decisions.map((d) => ({ type: docsById.get(d.documentId)!.type, reason: d.rejectReason })),
      });
    }

    return { id, isVerified: false };
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

  private readonly complaintSelect = {
    id: true,
    reporterUserId: true,
    reporter: { select: { id: true, phone: true, email: true } },
    targetType: true,
    targetId: true,
    reason: true,
    description: true,
    status: true,
    assignedToUserId: true,
    assignedTo: { select: { name: true, email: true } },
    takenAt: true,
    resolution: true,
    resolutionNote: true,
    resolvedByUserId: true,
    resolvedBy: { select: { name: true, email: true } },
    resolvedAt: true,
    createdAt: true,
  } as const;

  private async complaintToDto(c: {
    id: string;
    reporterUserId: string;
    reporter: { phone: string | null; email: string | null; id: string };
    targetType: string;
    targetId: string;
    reason: string;
    description: string | null;
    status: string;
    assignedToUserId: string | null;
    assignedTo: { name: string | null; email: string | null } | null;
    takenAt: Date | null;
    resolution: string | null;
    resolutionNote: string | null;
    resolvedByUserId: string | null;
    resolvedBy: { name: string | null; email: string | null } | null;
    resolvedAt: Date | null;
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
      assignedToUserId: c.assignedToUserId,
      assignedToName: c.assignedTo?.name ?? c.assignedTo?.email ?? null,
      takenAt: c.takenAt,
      resolution: c.resolution,
      resolutionNote: c.resolutionNote,
      resolvedByName: c.resolvedBy?.name ?? c.resolvedBy?.email ?? null,
      resolvedAt: c.resolvedAt,
      createdAt: c.createdAt,
    };
  }

  /// Вкладки «Новые / В работе / Закрытые» (п.24a) — раньше список спрашивал
  /// только `status=OPEN`, и жалоба после «В работе» (`IN_REVIEW`) исчезала
  /// из очереди, хотя не была закрыта.
  async complaints(params: { tab?: 'NEW' | 'IN_REVIEW' | 'CLOSED'; mine?: string } = {}) {
    const statusFilter =
      params.tab === 'NEW' ? 'OPEN' : params.tab === 'IN_REVIEW' ? 'IN_REVIEW' : params.tab === 'CLOSED' ? { in: ['RESOLVED', 'REJECTED'] } : undefined;

    const complaints = await this.prisma.complaint.findMany({
      where: {
        ...(statusFilter ? { status: statusFilter as never } : {}),
        ...(params.mine ? { assignedToUserId: params.mine } : {}),
      },
      select: this.complaintSelect,
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(complaints.map((c) => this.complaintToDto(c)));
  }

  async complaintCounts() {
    const [newCount, inReviewCount, closedCount] = await Promise.all([
      this.prisma.complaint.count({ where: { status: 'OPEN' } }),
      this.prisma.complaint.count({ where: { status: 'IN_REVIEW' } }),
      this.prisma.complaint.count({ where: { status: { in: ['RESOLVED', 'REJECTED'] } } }),
    ]);
    return { newCount, inReviewCount, closedCount };
  }

  /// Карточка жалобы с контекстом (п.24c): груз (с ценой), сообщение из
  /// чата (оригинал + перевод), сделка — что применимо к `targetType`, и
  /// «ещё N жалоб за месяц» на того же нарушителя (без текущей жалобы).
  async complaintDetail(id: string) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id }, select: this.complaintSelect });
    if (!complaint) throw new NotFoundException('Complaint not found');

    const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const violatorComplaintsLastMonth = await this.prisma.complaint.count({
      where: { targetType: complaint.targetType, targetId: complaint.targetId, createdAt: { gte: since }, id: { not: id } },
    });

    let context: Record<string, unknown> = {};
    if (complaint.targetType === 'CARGO' || complaint.targetType === 'DEAL') {
      const cargoId =
        complaint.targetType === 'CARGO'
          ? complaint.targetId
          : (await this.prisma.deal.findUnique({ where: { id: complaint.targetId }, select: { cargoId: true } }))?.cargoId;
      if (cargoId) {
        const cargo = await this.prisma.cargo.findUnique({
          where: { id: cargoId },
          select: { id: true, price: true, currency: true, point: { select: { name: true } }, company: { select: { name: true } } },
        });
        if (cargo) context.cargo = { id: cargo.id, pointName: cargo.point.name, price: Number(cargo.price), currency: cargo.currency, companyName: cargo.company.name };
      }
    }
    if (complaint.targetType === 'DEAL') {
      const deal = await this.prisma.deal.findUnique({
        where: { id: complaint.targetId },
        select: { id: true, status: true, driver: { select: { fullName: true } }, company: { select: { name: true } } },
      });
      if (deal) context.deal = { id: deal.id, status: deal.status, driverName: deal.driver.fullName, companyName: deal.company.name };
    }
    if (complaint.targetType === 'CHAT_MESSAGE') {
      const message = await this.prisma.message.findUnique({ where: { id: complaint.targetId } });
      if (message) context.message = { id: message.id, originalText: message.originalText, originalLang: message.originalLang, translations: message.translations };
    }

    return { ...(await this.complaintToDto(complaint)), violatorComplaintsLastMonth, context };
  }

  /// «Взять в работу» (п.24e) — назначает на текущего админа и переводит в
  /// `IN_REVIEW` (та же операция, одна причина не нужна — не правка данных
  /// нарушителя, а внутренняя маршрутизация очереди).
  async assignComplaint(id: string, adminUserId: string) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id } });
    if (!complaint) throw new NotFoundException('Complaint not found');

    const updated = await this.prisma.complaint.update({
      where: { id },
      data: { assignedToUserId: adminUserId, takenAt: new Date(), status: 'IN_REVIEW' },
      select: this.complaintSelect,
    });
    await this.logAudit(adminUserId, 'COMPLAINT_ASSIGNED', 'Complaint', id, {});
    return this.complaintToDto(updated);
  }

  /// «Вернуть в новые» — снимает назначение.
  async unassignComplaint(id: string, adminUserId: string) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id } });
    if (!complaint) throw new NotFoundException('Complaint not found');

    const updated = await this.prisma.complaint.update({
      where: { id },
      data: { assignedToUserId: null, takenAt: null, status: 'OPEN' },
      select: this.complaintSelect,
    });
    await this.logAudit(adminUserId, 'COMPLAINT_UNASSIGNED', 'Complaint', id, {});
    return this.complaintToDto(updated);
  }

  /// Кого реально затрагивает решение «Снять груз»/«Заблокировать» —
  /// отдельно от `complaintTarget` (который строит только текст карточки):
  /// здесь нужны именно action-ready id для вызова существующих методов.
  /// На DEAL всегда 2 стороны (задача 029, п.17: раньше блокировка по
  /// жалобе на сделку ВСЕГДА била компанию — даже если логист жаловался
  /// на водителя). Сторону, НА которую жалоба, определяем от обратного
  /// по reporterUserId: если жаловался сам водитель этой сделки — жалоба
  /// на компанию (как раньше); если жаловался кто-то другой (сотрудник
  /// компании) — жалоба на водителя. Другого способа различить нет —
  /// Complaint не хранит отдельно «на кого» для DEAL/CARGO.
  private async resolveComplaintActionTargets(targetType: string, targetId: string, reporterUserId: string): Promise<{ userId?: string; companyId?: string; cargoId?: string }> {
    switch (targetType) {
      case 'USER':
        return { userId: targetId };
      case 'COMPANY':
        return { companyId: targetId };
      case 'CARGO': {
        const cargo = await this.prisma.cargo.findUnique({ where: { id: targetId }, select: { companyId: true } });
        return cargo ? { companyId: cargo.companyId, cargoId: targetId } : {};
      }
      case 'DEAL': {
        const deal = await this.prisma.deal.findUnique({
          where: { id: targetId },
          select: { companyId: true, cargoId: true, driver: { select: { userId: true } } },
        });
        if (!deal) return {};
        if (reporterUserId === deal.driver.userId) {
          return { companyId: deal.companyId, cargoId: deal.cargoId };
        }
        return { userId: deal.driver.userId, cargoId: deal.cargoId };
      }
      case 'CHAT_MESSAGE': {
        const message = await this.prisma.message.findUnique({ where: { id: targetId }, select: { senderUserId: true } });
        return message ? { userId: message.senderUserId } : {};
      }
      default:
        return {};
    }
  }

  /// Решение по жалобе (п.24d) — один из 4 вариантов, ответ автору
  /// обязателен всегда. «Снять груз»/«Заблокировать» вызывают те же методы,
  /// что в карточках груза/пользователя/компании, с причиной = текст жалобы.
  async resolveComplaint(id: string, adminUserId: string, dto: ResolveComplaintDto) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id } });
    if (!complaint) throw new NotFoundException('Complaint not found');

    const actionTargets = await this.resolveComplaintActionTargets(complaint.targetType, complaint.targetId, complaint.reporterUserId);

    if (dto.resolution === 'CARGO_UNPUBLISHED') {
      if (!actionTargets.cargoId) throw new BadRequestException('This complaint has no cargo to unpublish');
      await this.unpublishCargo(actionTargets.cargoId, adminUserId, complaint.reason);
    }
    if (dto.resolution === 'BLOCKED') {
      if (actionTargets.userId) await this.blockUser(actionTargets.userId, adminUserId, { reason: complaint.reason });
      else if (actionTargets.companyId) await this.blockCompany(actionTargets.companyId, adminUserId, { reason: complaint.reason });
      else throw new BadRequestException('This complaint has no one to block');
    }

    const status = dto.resolution === 'DISMISSED' ? 'REJECTED' : 'RESOLVED';
    const updated = await this.prisma.complaint.update({
      where: { id },
      data: { status, resolution: dto.resolution, resolutionNote: dto.resolutionNote, resolvedByUserId: adminUserId, resolvedAt: new Date() },
      select: this.complaintSelect,
    });
    await this.logAudit(adminUserId, 'COMPLAINT_RESOLVED', 'Complaint', id, { resolution: dto.resolution, resolutionNote: dto.resolutionNote });
    // Экрана «Мои жалобы» в профиле пока нет (028) — push всё равно
    // долетит, просто deep link пока открывает профиль, не карточку жалобы.
    await this.notifications?.notify({ userIds: [complaint.reporterUserId] }, 'COMPLAINT_RESOLVED', {
      complaintId: id,
      resolutionNote: dto.resolutionNote,
    });
    if (dto.resolution === 'WARNED' && actionTargets.userId) {
      await this.notifications?.notify({ userIds: [actionTargets.userId] }, 'COMPLAINT_WARNED', { reason: complaint.reason });
    }

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
      ...(query.onSite ? { arrivals: { some: { status: 'ON_SITE' } } } : {}),
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
          // Задача 031 — кузов/тоннаж теперь у TRAILER/RIGID, не у тягача.
          vehicles: { where: { kind: { in: ['TRAILER', 'RIGID'] } }, select: { bodyType: { select: { name: true } }, capacityTons: true }, take: 1 },
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
        ? { bodyTypeName: d.vehicles[0].bodyType?.name ?? null, capacityTons: d.vehicles[0].capacityTons ? Number(d.vehicles[0].capacityTons) : null }
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
        vehicles: { include: { bodyType: { select: { name: true } } }, orderBy: [{ kind: 'asc' }, { createdAt: 'asc' }] },
      },
    });
    if (!driver) throw new NotFoundException('Driver not found');

    const [documents, lastSession, dealsByStatus, cancellations, reviews, calls, whatsapp, complaintsAgainst, complaintsBy, arrivals, deals, sessions, auditLog, driverIdentifiers, vehicleIdentifiers] =
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
        this.identifiersCard('DRIVER', id),
        Promise.all(driver.vehicles.map((v) => this.identifiersCard('VEHICLE', v.id))),
      ]);

    return {
      id: driver.id,
      fullName: driver.fullName,
      isVerified: driver.isVerified,
      identifiers: driverIdentifiers.identifiers,
      identifierBlockHistory: driverIdentifiers.blockHistory,
      user: {
        id: driver.userId,
        phone: driver.user.phone,
        locale: driver.user.locale,
        createdAt: driver.user.createdAt,
        isBlocked: driver.user.isBlocked,
        lastLoginAt: lastSession?.lastUsedAt ?? driver.user.createdAt,
      },
      homeCityId: driver.homeCityId,
      homeCityName: driver.homeCity.name,
      anyCountry: driver.anyCountry,
      directions: driver.directions.map((d) => ({ countryId: d.countryId, name: d.country.name })),
      permits: driver.permits.map((p) => ({ permitId: p.permitId, name: p.permit.name })),
      vehicles: driver.vehicles.map((v, i) => ({
        id: v.id,
        kind: v.kind,
        isVerified: v.isVerified,
        isArchived: v.isArchived,
        bodyTypeId: v.bodyTypeId,
        bodyTypeName: v.bodyType?.name ?? null,
        capacityTons: v.capacityTons ? Number(v.capacityTons) : null,
        lengthM: v.lengthM ? Number(v.lengthM) : null,
        // Задача 033, п.11 — размер кузова в карточке машины.
        volumeM3: v.volumeM3 != null ? Number(v.volumeM3) : null,
        palletsEuro: v.palletsEuro ?? null,
        plateNumber: v.plateNumber,
        vin: v.vin,
        brand: v.brand,
        identifiers: vehicleIdentifiers[i].identifiers,
        identifierBlockHistory: vehicleIdentifiers[i].blockHistory,
      })),
      // Задача 029, п.15 — карточка (не только экран проверки) тоже должна
      // грузить документы через прокси /admin/documents/:id/file, а не
      // presigned MinIO URL напрямую (CORS/сеть MinIO не видна клиенту).
      documents: documents.map((d) => ({
        id: d.id,
        type: d.type,
        fileUrl: `/admin/documents/${d.id}/file`,
        status: d.status,
        rejectReason: d.rejectReason,
        reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
        reviewedAt: d.reviewedAt,
        createdAt: d.createdAt,
      })),
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

    const [documents, members, invites, cargos, deals, reviews, complaints, auditLog, companyIdentifiers] = await Promise.all([
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
      this.identifiersCard('COMPANY', id),
    ]);

    return {
      id: company.id,
      name: company.name,
      nameRu: company.nameRu,
      countryId: company.countryId,
      countryName: company.country.name,
      city: company.city,
      legalAddress: company.legalAddress,
      taxId: company.taxId,
      isVerified: company.isVerified,
      isBlocked: company.isBlocked,
      ratingAvg: Number(company.ratingAvg),
      ratingCount: company.ratingCount,
      identifiers: companyIdentifiers.identifiers,
      identifierBlockHistory: companyIdentifiers.blockHistory,
      // Задача 029, п.15 — карточка (не только экран проверки) тоже должна
      // грузить документы через прокси /admin/documents/:id/file, а не
      // presigned MinIO URL напрямую (CORS/сеть MinIO не видна клиенту).
      documents: documents.map((d) => ({
        id: d.id,
        type: d.type,
        fileUrl: `/admin/documents/${d.id}/file`,
        status: d.status,
        rejectReason: d.rejectReason,
        reviewedByName: d.reviewedBy?.name ?? d.reviewedBy?.email ?? null,
        reviewedAt: d.reviewedAt,
        createdAt: d.createdAt,
      })),
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
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: { driver: { include: { vehicles: true } } } });
    if (!user) throw new NotFoundException('User not found');

    await this.prisma.user.update({ where: { id: userId }, data: { isBlocked: true } });
    await this.sessions.revokeAllForUser(userId);
    await this.logAudit(adminUserId, 'USER_BLOCKED', 'User', userId, { reason: dto.reason });

    // Задача 031, п.14 — блокируем идентификаторы, а не только аккаунт: ИИН,
    // права, телефон водителя и VIN/госномера всех его машин (по умолчанию
    // все подтверждённые — явный выбор отдельных типов делает Stage E).
    if (user.driver) {
      await this.identifiers?.blockDriverAndVehicles({
        driverId: user.driver.id,
        vehicleIds: user.driver.vehicles.map((v) => v.id),
        reason: dto.reason,
        blockedByUserId: adminUserId,
      });
    }
    return { id: userId, isBlocked: true };
  }

  async unblockUser(userId: string, adminUserId: string, dto: BlockUserDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: { driver: { include: { vehicles: true } } } });
    if (!user) throw new NotFoundException('User not found');

    await this.prisma.user.update({ where: { id: userId }, data: { isBlocked: false } });
    await this.logAudit(adminUserId, 'USER_UNBLOCKED', 'User', userId, { reason: dto.reason });

    if (user.driver) {
      await this.identifiers?.liftDriverAndVehicles({
        driverId: user.driver.id,
        vehicleIds: user.driver.vehicles.map((v) => v.id),
        reason: dto.reason,
        liftedByUserId: adminUserId,
      });
    }
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
    // Задача 031, п.14 — БИН/统一社会信用代码 компании тоже в чёрный список.
    await this.identifiers?.blockOwnerIdentifiers({ ownerType: 'COMPANY', ownerId: companyId, reason: dto.reason, blockedByUserId: adminUserId });
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
    await this.identifiers?.liftOwnerIdentifierBlocks({ ownerType: 'COMPANY', ownerId: companyId, reason: dto.reason, liftedByUserId: adminUserId });
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

    // Задача 032, п.2 — чёрный список больше не обходится обычной кнопкой
    // «Подтвердить»: проверяем и уже подтверждённые идентификаторы, и
    // распознанные-но-не-подтверждённые значения из документов компании.
    // Считаем блоки независимо от force, чтобы при подтверждении «вопреки»
    // они попали в audit_log, а не просто молча пропустились.
    const blocks = dto.isVerified ? await this.blacklistBlocksForOwner('COMPANY', id, { companyId: id }) : [];
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
      if (blocks.length > 0) {
        throw new ConflictException({ code: 'BLACKLIST_MATCH', message: 'Identifiers matching the blacklist found — pass force:true with a reason to override', blocks });
      }
    }

    const updated = await this.prisma.company.update({ where: { id }, data: { isVerified: dto.isVerified } });
    await this.logAudit(adminUserId, dto.isVerified ? 'COMPANY_VERIFIED' : 'COMPANY_UNVERIFIED', 'Company', id, {
      reason: dto.reason,
      force: dto.force ?? false,
      crossChecks: dto.crossChecks,
      ...(blocks.length > 0 ? { blacklistOverride: blocks } : {}),
    });
    if (dto.isVerified) {
      const owner = await this.prisma.companyMember.findFirst({ where: { companyId: id, role: 'OWNER' }, orderBy: { createdAt: 'asc' } });
      if (owner) await this.notifications?.notify({ userIds: [owner.userId] }, 'VERIFICATION_APPROVED', {});
    }
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

  /// Общая панель редактирования компании (п.18/20).
  async updateCompany(id: string, adminUserId: string, dto: AdminUpdateCompanyDto) {
    const company = await this.prisma.company.findUnique({ where: { id } });
    if (!company) throw new NotFoundException('Company not found');

    const fields: Array<[string, unknown, unknown]> = [
      ['name', company.name, dto.name],
      ['nameRu', company.nameRu, dto.nameRu],
      ['countryId', company.countryId, dto.countryId],
      ['city', company.city, dto.city],
      ['legalAddress', company.legalAddress, dto.legalAddress],
      ['taxId', company.taxId, dto.taxId],
    ];
    const changes = Object.fromEntries(
      fields.filter(([, oldValue, newValue]) => newValue !== undefined && oldValue !== newValue).map(([key, oldValue, newValue]) => [key, { old: oldValue, new: newValue }]),
    );

    await this.prisma.company.update({
      where: { id },
      data: { name: dto.name, nameRu: dto.nameRu, countryId: dto.countryId, city: dto.city, legalAddress: dto.legalAddress, taxId: dto.taxId },
    });
    await this.logAudit(adminUserId, 'COMPANY_UPDATED', 'Company', id, { reason: dto.reason, changes });

    return { id };
  }

  /// Сменить роль сотрудника (п.20) — «передать владение» делается этим же
  /// методом: назначить LOGIST → OWNER, старого OWNER вызывающая сторона
  /// отдельным вызовом переводит в LOGIST (на пилоте почти всегда один
  /// владелец, две роли — проще двух разных эндпоинтов «transfer»/«demote»).
  async setMemberRole(companyId: string, userId: string, adminUserId: string, dto: AdminSetMemberRoleDto) {
    const member = await this.prisma.companyMember.findFirst({ where: { companyId, userId } });
    if (!member) throw new NotFoundException('Member not found');

    if (member.role === 'OWNER' && dto.role === 'LOGIST') {
      const owners = await this.prisma.companyMember.count({ where: { companyId, role: 'OWNER' } });
      if (owners <= 1) throw new BadRequestException('Cannot demote the last owner — assign another owner first');
    }

    await this.prisma.companyMember.update({ where: { id: member.id }, data: { role: dto.role } });
    await this.logAudit(adminUserId, 'COMPANY_MEMBER_ROLE_CHANGED', 'Company', companyId, { reason: dto.reason, userId, from: member.role, to: dto.role });

    return { userId, role: dto.role };
  }

  /// Удалить сотрудника из компании (п.20) — не последнего владельца.
  async removeMember(companyId: string, userId: string, adminUserId: string, reason: string) {
    const member = await this.prisma.companyMember.findFirst({ where: { companyId, userId } });
    if (!member) throw new NotFoundException('Member not found');

    if (member.role === 'OWNER') {
      const owners = await this.prisma.companyMember.count({ where: { companyId, role: 'OWNER' } });
      if (owners <= 1) throw new BadRequestException('Cannot remove the last owner');
    }

    await this.prisma.$transaction(async (tx) => {
      // Задача 012, п.7 — удалённый логист не оставляет свои грузы без
      // хозяина: переходят владельцу (decisions.md «Компания: проверка,
      // роли, контакты»). Для OWNER это не нужно — его грузы остаются при
      // компании, и выше уже гарантирован хотя бы один оставшийся OWNER.
      if (member.role === 'LOGIST') {
        const owner = await tx.companyMember.findFirst({ where: { companyId, role: 'OWNER' }, orderBy: { createdAt: 'asc' } });
        if (owner) {
          await tx.cargo.updateMany({ where: { companyId, publishedByUserId: userId }, data: { publishedByUserId: owner.userId } });
        }
      }
      await tx.companyMember.delete({ where: { id: member.id } });
    });
    await this.logAudit(adminUserId, 'COMPANY_MEMBER_REMOVED', 'Company', companyId, { reason, userId });

    return { userId };
  }

  /// Email сотрудника — с отзывом сессий (п.20): логин идёт по email+пароль
  /// у компании (задача 025), смена email должна выгнать со старых сессий.
  async changeMemberEmail(companyId: string, userId: string, adminUserId: string, dto: AdminChangeMemberEmailDto) {
    const member = await this.prisma.companyMember.findFirst({ where: { companyId, userId }, include: { user: true } });
    if (!member) throw new NotFoundException('Member not found');

    const taken = await this.prisma.user.findFirst({ where: { email: dto.email, id: { not: userId } } });
    if (taken) throw new ConflictException('Email is already in use');

    await this.prisma.user.update({ where: { id: userId }, data: { email: dto.email } });
    await this.sessions.revokeAllForUser(userId);
    await this.logAudit(adminUserId, 'COMPANY_MEMBER_EMAIL_CHANGED', 'Company', companyId, { reason: dto.reason, userId, old: member.user.email, new: dto.email });

    return { userId, email: dto.email };
  }

  /// Аналог setCompanyVerified для водителя — та же логика force/reason,
  /// те же 4 обязательных документа, что и в reviewVerificationDocument.
  async setDriverVerified(id: string, adminUserId: string, dto: SetVerifiedDto) {
    const driver = await this.prisma.driver.findUnique({ where: { id } });
    if (!driver) throw new NotFoundException('Driver not found');

    // Задача 032, п.2 — та же финальная проверка, что и для компании.
    const blocks = dto.isVerified ? await this.blacklistBlocksForOwner('DRIVER', id, { driverId: id }) : [];
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
      if (blocks.length > 0) {
        throw new ConflictException({ code: 'BLACKLIST_MATCH', message: 'Identifiers matching the blacklist found — pass force:true with a reason to override', blocks });
      }
    }

    const updated = await this.prisma.driver.update({ where: { id }, data: { isVerified: dto.isVerified } });
    await this.logAudit(adminUserId, dto.isVerified ? 'DRIVER_VERIFIED' : 'DRIVER_UNVERIFIED', 'Driver', id, {
      reason: dto.reason,
      force: dto.force ?? false,
      crossChecks: dto.crossChecks,
      ...(blocks.length > 0 ? { blacklistOverride: blocks } : {}),
    });
    if (dto.isVerified) {
      await this.notifications?.notify({ userIds: [driver.userId] }, 'VERIFICATION_APPROVED', {});
    }
    return { id: updated.id, isVerified: updated.isVerified };
  }

  /// Общая панель редактирования водителя (п.18/19) — одна причина, один
  /// audit_log с old/new по каждому изменённому полю. Правит только
  /// `vehicles[0]` — на пилоте у водителя одна машина, хотя схема допускает
  /// несколько; та же осознанная упрощение, что у сверки в задаче 028, п.9.
  async updateDriver(id: string, adminUserId: string, dto: AdminUpdateDriverDto) {
    const driver = await this.prisma.driver.findUnique({
      where: { id },
      include: { user: true, vehicles: { orderBy: [{ kind: 'asc' }, { createdAt: 'asc' }] }, directions: true, permits: true },
    });
    if (!driver) throw new NotFoundException('Driver not found');

    const changes: Record<string, { old: unknown; new: unknown }> = {};
    let phoneChanged = false;

    if (dto.fullName !== undefined && dto.fullName !== driver.fullName) {
      changes.fullName = { old: driver.fullName, new: dto.fullName };
    }
    if (dto.phone !== undefined && dto.phone !== driver.user.phone) {
      const taken = await this.prisma.user.findFirst({ where: { phone: dto.phone, id: { not: driver.userId } } });
      if (taken) throw new ConflictException('Phone number is already in use');
      changes.phone = { old: driver.user.phone, new: dto.phone };
      phoneChanged = true;
    }
    if (dto.homeCityId !== undefined && dto.homeCityId !== driver.homeCityId) {
      const city = await this.prisma.city.findUnique({ where: { id: dto.homeCityId } });
      if (!city) throw new NotFoundException('City not found');
      changes.homeCityId = { old: driver.homeCityId, new: dto.homeCityId };
    }
    if (dto.anyCountry !== undefined && dto.anyCountry !== driver.anyCountry) {
      changes.anyCountry = { old: driver.anyCountry, new: dto.anyCountry };
    }
    if (dto.countryIds !== undefined) {
      const old = driver.directions.map((d) => d.countryId).sort();
      const next = [...dto.countryIds].sort();
      if (JSON.stringify(old) !== JSON.stringify(next)) changes.countryIds = { old, new: next };
    }
    if (dto.permitIds !== undefined) {
      const old = driver.permits.map((p) => p.permitId).sort();
      const next = [...dto.permitIds].sort();
      if (JSON.stringify(old) !== JSON.stringify(next)) changes.permitIds = { old, new: next };
    }

    // Задача 031, этап A — Vehicle разделена на TRACTOR (госномер/марка) и
    // TRAILER (кузов/тоннаж/длина). Задача 032, п.6 — раньше оба блока
    // читали из ОДНОЙ dto.vehicle; теперь у каждой машины своя часть DTO
    // (tractorVehicle/trailerVehicle), перепутать нечем независимо от
    // порядка driver.vehicles.
    const tractor = driver.vehicles.find((v) => v.kind === 'TRACTOR' || v.kind === 'RIGID');
    const trailer = driver.vehicles.find((v) => v.kind === 'TRAILER');
    let vehicleIdentityChanged = false;
    const vehicleChanges: Record<string, { old: unknown; new: unknown }> = {};
    if (dto.trailerVehicle && trailer) {
      const v = dto.trailerVehicle;
      if (v.bodyTypeId !== undefined && v.bodyTypeId !== trailer.bodyTypeId) {
        vehicleChanges.trailerBodyTypeId = { old: trailer.bodyTypeId, new: v.bodyTypeId };
        vehicleIdentityChanged = true;
      }
      if (v.capacityTons !== undefined && v.capacityTons !== (trailer.capacityTons ? Number(trailer.capacityTons) : null)) {
        vehicleChanges.trailerCapacityTons = { old: trailer.capacityTons ? Number(trailer.capacityTons) : null, new: v.capacityTons };
      }
      if (v.lengthM !== undefined && v.lengthM !== (trailer.lengthM ? Number(trailer.lengthM) : null)) {
        vehicleChanges.trailerLengthM = { old: trailer.lengthM ? Number(trailer.lengthM) : null, new: v.lengthM };
      }
    }
    if (dto.tractorVehicle && tractor) {
      const v = dto.tractorVehicle;
      if (v.plateNumber !== undefined && v.plateNumber !== tractor.plateNumber) {
        vehicleChanges.tractorPlateNumber = { old: tractor.plateNumber, new: v.plateNumber };
        vehicleIdentityChanged = true;
      }
      if (v.brand !== undefined && v.brand !== tractor.brand) {
        vehicleChanges.tractorBrand = { old: tractor.brand, new: v.brand };
      }
    }
    if (Object.keys(vehicleChanges).length > 0) changes.vehicle = { old: null, new: vehicleChanges };

    await this.prisma.$transaction(async (tx) => {
      // Задача 031 — смена машины больше не сбрасывает верификацию
      // водителя (селфи+права); сбрасывается isVerified только у самой
      // изменившейся машины (см. блоки tractor/trailer ниже).
      await tx.driver.update({
        where: { id },
        data: { fullName: dto.fullName, homeCityId: dto.homeCityId, anyCountry: dto.anyCountry },
      });
      if (dto.phone !== undefined) {
        await tx.user.update({ where: { id: driver.userId }, data: { phone: dto.phone } });
      }
      if (dto.countryIds !== undefined) {
        await tx.driverDirection.deleteMany({ where: { driverId: id } });
        if (dto.countryIds.length > 0) {
          await tx.driverDirection.createMany({ data: dto.countryIds.map((countryId) => ({ driverId: id, countryId })) });
        }
      }
      if (dto.permitIds !== undefined) {
        await tx.driverPermit.deleteMany({ where: { driverId: id } });
        if (dto.permitIds.length > 0) {
          await tx.driverPermit.createMany({ data: dto.permitIds.map((permitId) => ({ driverId: id, permitId })) });
        }
      }
      if (dto.trailerVehicle && trailer) {
        await tx.vehicle.update({
          where: { id: trailer.id },
          data: {
            bodyTypeId: dto.trailerVehicle.bodyTypeId,
            capacityTons: dto.trailerVehicle.capacityTons,
            lengthM: dto.trailerVehicle.lengthM,
            ...(dto.trailerVehicle.bodyTypeId !== undefined && dto.trailerVehicle.bodyTypeId !== trailer.bodyTypeId ? { isVerified: false } : {}),
          },
        });
      }
      if (dto.tractorVehicle && tractor) {
        await tx.vehicle.update({
          where: { id: tractor.id },
          data: {
            plateNumber: dto.tractorVehicle.plateNumber,
            brand: dto.tractorVehicle.brand,
            ...(dto.tractorVehicle.plateNumber !== undefined && dto.tractorVehicle.plateNumber !== tractor.plateNumber ? { isVerified: false } : {}),
          },
        });
      }
      if (vehicleIdentityChanged) {
        // Смена кузова прицепа или госномера тягача — соответствующий
        // техпаспорт нужно переснять и проверить заново (решение 2026-10-04);
        // селфи и права водителя не трогаем. Задача 031 — сбрасываем
        // техпаспорт именно изменившейся машины, не обеих разом.
        await tx.verificationDocument.updateMany({
          where: {
            status: 'APPROVED',
            OR: [
              ...(trailer && dto.trailerVehicle?.bodyTypeId !== undefined && dto.trailerVehicle.bodyTypeId !== trailer.bodyTypeId
                ? [{ vehicleId: trailer.id, type: 'TRAILER_PASSPORT' as const }]
                : []),
              ...(tractor && dto.tractorVehicle?.plateNumber !== undefined && dto.tractorVehicle.plateNumber !== tractor.plateNumber
                ? [{ vehicleId: tractor.id, type: 'VEHICLE_PASSPORT' as const }]
                : []),
            ],
          },
          data: { status: 'PENDING', reviewedByUserId: null, reviewedAt: null, rejectReason: null },
        });
      }
    });

    if (phoneChanged) await this.sessions.revokeAllForUser(driver.userId);
    await this.logAudit(adminUserId, 'DRIVER_UPDATED', 'Driver', id, { reason: dto.reason, changes, phoneChanged, vehicleIdentityChanged });

    return { id, phoneChanged, vehicleIdentityChanged };
  }

  // -- reference data management ------------------------------------------------

  async createBodyType(dto: CreateBodyTypeDto) {
    return this.prisma.bodyType.create({
      data: { code: dto.code, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } },
    });
  }

  async createPermit(dto: CreatePermitDto) {
    return this.prisma.permit.create({
      data: { code: dto.code, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } },
    });
  }

  /// Шаблоны размеров кузова (задача 033, п.11) — CRUD без релиза;
  /// значения шаблона КОПИРУЮТСЯ в машину при выборе, так что правка
  /// шаблона прошлые машины не трогает (это зафиксировано в задаче).
  async createBodySizePreset(dto: CreateBodySizePresetDto) {
    return this.prisma.bodySizePreset.create({
      data: {
        code: dto.code,
        name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en },
        bodyTypeIds: dto.bodyTypeIds ?? [],
        innerLengthM: dto.innerLengthM,
        innerWidthM: dto.innerWidthM,
        innerHeightM: dto.innerHeightM,
        volumeM3: dto.volumeM3,
        palletsEuro: dto.palletsEuro,
        palletsStandard: dto.palletsStandard,
        sortOrder: dto.sortOrder ?? 0,
      },
    });
  }

  async updateBodySizePreset(id: string, adminUserId: string, dto: AdminUpdateBodySizePresetDto) {
    const existing = await this.prisma.bodySizePreset.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Body size preset not found');

    const changes: Record<string, { old: unknown; new: unknown }> = {};
    for (const key of ['bodyTypeIds', 'innerLengthM', 'innerWidthM', 'innerHeightM', 'volumeM3', 'palletsEuro', 'palletsStandard', 'sortOrder', 'isActive'] as const) {
      const next = dto[key];
      if (next !== undefined) changes[key] = { old: (existing as Record<string, unknown>)[key], new: next };
    }
    if (dto.name !== undefined) changes.name = { old: existing.name, new: dto.name };

    await this.prisma.bodySizePreset.update({
      where: { id },
      data: {
        name: dto.name ? { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } : undefined,
        bodyTypeIds: dto.bodyTypeIds,
        innerLengthM: dto.innerLengthM,
        innerWidthM: dto.innerWidthM,
        innerHeightM: dto.innerHeightM,
        volumeM3: dto.volumeM3,
        palletsEuro: dto.palletsEuro,
        palletsStandard: dto.palletsStandard,
        sortOrder: dto.sortOrder,
        isActive: dto.isActive,
      },
    });
    await this.logAudit(adminUserId, 'BODY_SIZE_PRESET_UPDATED', 'BodySizePreset', id, { reason: dto.reason, changes });
    return { id };
  }

  async createPoint(dto: CreatePointDto) {
    return this.prisma.point.create({
      data: { cityId: dto.cityId, name: { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en }, isActive: true },
    });
  }

  /// Правка уже созданного body-type/permit (п.21) — названия на 4 языках,
  /// включить/выключить, порядок. Удалять нельзя — только выключать, если
  /// запись используется (здесь просто не даём удалить вовсе: ни у одной
  /// из них сегодня нет DELETE-эндпоинта).
  async updateBodyType(id: string, adminUserId: string, dto: AdminUpdateReferenceItemDto) {
    return this.updateReferenceItem('bodyType', 'BodyType', id, adminUserId, dto);
  }

  async updatePermit(id: string, adminUserId: string, dto: AdminUpdateReferenceItemDto) {
    return this.updateReferenceItem('permit', 'Permit', id, adminUserId, dto);
  }

  private async updateReferenceItem(
    model: 'bodyType' | 'permit',
    entityType: 'BodyType' | 'Permit',
    id: string,
    adminUserId: string,
    dto: AdminUpdateReferenceItemDto,
  ) {
    const delegate = this.prisma[model] as { findUnique: (args: unknown) => Promise<{ name: unknown; isActive: boolean; sortOrder: number } | null>; update: (args: unknown) => Promise<unknown> };
    const existing = await delegate.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException(`${entityType} not found`);

    const changes: Record<string, { old: unknown; new: unknown }> = {};
    if (dto.name !== undefined) changes.name = { old: existing.name, new: dto.name };
    if (dto.isActive !== undefined && dto.isActive !== existing.isActive) changes.isActive = { old: existing.isActive, new: dto.isActive };
    if (dto.sortOrder !== undefined && dto.sortOrder !== existing.sortOrder) changes.sortOrder = { old: existing.sortOrder, new: dto.sortOrder };

    await delegate.update({
      where: { id },
      data: {
        name: dto.name ? { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } : undefined,
        isActive: dto.isActive,
        sortOrder: dto.sortOrder,
      },
    });
    await this.logAudit(adminUserId, `${entityType.toUpperCase()}_UPDATED`, entityType, id, { reason: dto.reason, changes });

    return { id };
  }

  /// Правка точки (п.21) — названия на 4 языках, город, координаты,
  /// включить/выключить; замена узкого `setPointActive` — теперь то же
  /// общее «Редактировать» с обязательной причиной (п.18), а не голый
  /// переключатель без следа в журнале.
  async updatePoint(id: string, adminUserId: string, dto: AdminUpdatePointDto) {
    const existing = await this.prisma.point.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Point not found');

    const changes: Record<string, { old: unknown; new: unknown }> = {};
    if (dto.name !== undefined) changes.name = { old: existing.name, new: dto.name };
    if (dto.cityId !== undefined && dto.cityId !== existing.cityId) changes.cityId = { old: existing.cityId, new: dto.cityId };
    if (dto.isActive !== undefined && dto.isActive !== existing.isActive) changes.isActive = { old: existing.isActive, new: dto.isActive };
    if (dto.lat !== undefined) changes.lat = { old: existing.lat ? Number(existing.lat) : null, new: dto.lat };
    if (dto.lng !== undefined) changes.lng = { old: existing.lng ? Number(existing.lng) : null, new: dto.lng };

    await this.prisma.point.update({
      where: { id },
      data: {
        name: dto.name ? { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } : undefined,
        cityId: dto.cityId,
        lat: dto.lat,
        lng: dto.lng,
        isActive: dto.isActive,
      },
    });
    await this.logAudit(adminUserId, 'POINT_UPDATED', 'Point', id, { reason: dto.reason, changes });

    return { id };
  }

  /// Правка уже APPROVED города (п.21) — область и координаты нужны для
  /// «Близко к дому» (задача 016). Отдельно от `moderateCity`, который
  /// только для очереди PENDING.
  async updateCity(id: string, adminUserId: string, dto: AdminUpdateCityDto) {
    const existing = await this.prisma.city.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('City not found');

    const changes: Record<string, { old: unknown; new: unknown }> = {};
    if (dto.name !== undefined) changes.name = { old: existing.name, new: dto.name };
    if (dto.regionId !== undefined && dto.regionId !== existing.regionId) changes.regionId = { old: existing.regionId, new: dto.regionId };
    if (dto.lat !== undefined) changes.lat = { old: existing.lat ? Number(existing.lat) : null, new: dto.lat };
    if (dto.lng !== undefined) changes.lng = { old: existing.lng ? Number(existing.lng) : null, new: dto.lng };

    await this.prisma.city.update({
      where: { id },
      data: {
        name: dto.name ? { kk: dto.name.kk, ru: dto.name.ru, zh: dto.name.zh, en: dto.name.en } : undefined,
        regionId: dto.regionId,
        lat: dto.lat,
        lng: dto.lng,
      },
    });
    await this.logAudit(adminUserId, 'CITY_UPDATED', 'City', id, { reason: dto.reason, changes });

    return { id };
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
