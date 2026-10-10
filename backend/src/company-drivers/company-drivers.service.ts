import { BadRequestException, ConflictException, ForbiddenException, HttpException, HttpStatus, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestContext } from '../common/request-context';
import { ShareService } from '../share/share.service';
import { avatarVersion } from '../drivers/avatar-version';

/// Лимит «Создать водителя» — на компанию в сутки (058 п.6).
export const CREATE_DRIVER_DAILY_LIMIT = 50;

/// «+7 701 123-45-67» → «+77011234567»; номер без «+» и короче 10 цифр — null.
export function normalizeInvitePhone(raw: string): string | null {
  const phone = raw.trim().replace(/[^\d+]/g, '');
  return /^\+\d{10,15}$/.test(phone) ? phone : null;
}

type ListEntry = {
  rowId: string | null;
  driverId: string | null;
  name: string;
  status: 'ACTIVE' | 'PENDING';
  saved: boolean;
  createdByCompany: boolean;
  fromDeals: boolean;
  isVerified: boolean;
  ratingAvg: number;
  ratingCount: number;
  avatarVersion: string | null;
  lastSeenAt: Date | null;
  searching: boolean;
  onSite: boolean;
};

/// 058 п.6: «Мои водители» компании — с кем были сделки, сохранённые ☆ и
/// заведённые компанией. Водитель видит «Компании, где я в списке» и выходит
/// из любой; до его согласия компания видит только имя и «ждёт входа».
@Injectable()
export class CompanyDriversService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly shares: ShareService,
  ) {}

  private audit(actorUserId: string | null, action: string, entityId: string, metadata?: Record<string, unknown>) {
    return this.prisma.auditLog.create({
      data: { actorUserId, action, entityType: 'CompanyDriver', entityId, metadata: metadata as Prisma.InputJsonValue | undefined },
    });
  }

  async list(companyId: string) {
    const [rows, dealDrivers] = await Promise.all([
      this.prisma.companyDriver.findMany({ where: { companyId }, include: { driver: { include: { user: { select: { lastSeenAt: true } } } } } }),
      this.prisma.deal.findMany({ where: { companyId }, distinct: ['driverId'], select: { driverId: true } }),
    ]);
    const hidden = new Set(rows.filter((r) => r.driverId && (r.status === 'DECLINED' || r.status === 'LEFT')).map((r) => r.driverId!));
    const byDriver = new Map<string, (typeof rows)[number][]>();
    for (const r of rows) if (r.driverId && !hidden.has(r.driverId)) byDriver.set(r.driverId, [...(byDriver.get(r.driverId) ?? []), r]);

    const driverIds = new Set<string>([...byDriver.keys(), ...dealDrivers.map((d) => d.driverId).filter((id) => !hidden.has(id))]);
    const drivers = await this.prisma.driver.findMany({ where: { id: { in: [...driverIds] } }, include: { user: { select: { lastSeenAt: true } } } });
    const arrivals = await this.prisma.arrival.findMany({ where: { driverId: { in: [...driverIds] }, status: { in: ['PLANNED', 'ON_SITE'] } }, select: { driverId: true, status: true } });
    const dealSet = new Set(dealDrivers.map((d) => d.driverId));

    const entries: ListEntry[] = [];
    for (const d of drivers) {
      const own = byDriver.get(d.id) ?? [];
      const pending = own.length > 0 && own.every((r) => r.status === 'PENDING') && !dealSet.has(d.id);
      const arrival = arrivals.filter((a) => a.driverId === d.id);
      entries.push({
        rowId: own[0]?.id ?? null,
        driverId: d.id,
        // До «Принять» — только имя, которое указала компания.
        name: pending ? own[0].name ?? d.fullName : d.fullName,
        status: pending ? 'PENDING' : 'ACTIVE',
        saved: own.some((r) => r.source === 'SAVED' && r.status === 'ACTIVE'),
        createdByCompany: own.some((r) => r.source === 'CREATED'),
        fromDeals: dealSet.has(d.id),
        isVerified: pending ? false : d.isVerified,
        ratingAvg: pending ? 0 : Number(d.ratingAvg),
        ratingCount: pending ? 0 : d.ratingCount,
        avatarVersion: pending ? null : avatarVersion(d),
        lastSeenAt: pending ? null : d.user.lastSeenAt ?? null,
        searching: !pending && arrival.length > 0,
        onSite: !pending && arrival.some((a) => a.status === 'ON_SITE'),
      });
    }
    // Заведены компанией, ещё не входили: только имя.
    for (const r of rows) {
      if (r.driverId || r.status !== 'PENDING') continue;
      entries.push({ rowId: r.id, driverId: null, name: r.name ?? '', status: 'PENDING', saved: false, createdByCompany: true, fromDeals: false, isVerified: false, ratingAvg: 0, ratingCount: 0, avatarVersion: null, lastSeenAt: null, searching: false, onSite: false });
    }
    // «Ищет груз» и на месте — сверху, затем кто недавно был в сети.
    return entries.sort(
      (a, b) =>
        Number(b.onSite) - Number(a.onSite) ||
        Number(b.searching) - Number(a.searching) ||
        Number(a.status === 'PENDING') - Number(b.status === 'PENDING') ||
        (b.lastSeenAt?.getTime() ?? 0) - (a.lastSeenAt?.getTime() ?? 0) ||
        a.name.localeCompare(b.name),
    );
  }

  /// ☆ у водителя. Вышедшего или отказавшегося — не возвращаем без его согласия.
  async save(companyId: string, driverId: string, actorUserId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, select: { id: true } });
    if (!driver) throw new NotFoundException('Driver not found');
    const existing = await this.prisma.companyDriver.findUnique({ where: { companyId_driverId: { companyId, driverId } } });
    if (existing?.status === 'LEFT' || existing?.status === 'DECLINED') {
      throw new ConflictException({ code: 'DRIVER_LEFT_LIST', message: 'The driver left your list' });
    }
    if (existing) {
      if (existing.source !== 'SAVED' && existing.status === 'ACTIVE') return { saved: true };
      await this.prisma.companyDriver.update({ where: { id: existing.id }, data: { source: existing.status === 'PENDING' ? existing.source : 'SAVED' } });
      return { saved: true };
    }
    const row = await this.prisma.companyDriver.create({ data: { companyId, driverId, source: 'SAVED', status: 'ACTIVE', createdByUserId: actorUserId } });
    await this.audit(actorUserId, 'COMPANY_DRIVER_SAVED', row.id);
    return { saved: true };
  }

  async unsave(companyId: string, driverId: string, actorUserId: string) {
    const removed = await this.prisma.companyDriver.deleteMany({ where: { companyId, driverId, source: 'SAVED', status: 'ACTIVE' } });
    if (removed.count > 0) await this.audit(actorUserId, 'COMPANY_DRIVER_UNSAVED', driverId);
    return { saved: false };
  }

  /// «Создать водителя»: имя и телефон. Номер уже в Lubao — приглашение этому
  /// водителю (без дубля); нет — только имя и телефон до его входа. Ссылку
  /// логист отправляет сам — мы ничего не шлём от своего имени.
  async create(ctx: RequestContext, name: string, rawPhone: string) {
    const companyId = ctx.companyMember!.companyId;
    const phone = normalizeInvitePhone(rawPhone);
    if (!phone) throw new BadRequestException({ code: 'VALIDATION_FAILED', message: ['phone is invalid'], fields: [{ field: 'phone', rule: 'isPhone' }] });
    const cleanName = name.trim();
    if (cleanName.length < 2) throw new BadRequestException({ code: 'VALIDATION_FAILED', message: ['name is too short'], fields: [{ field: 'name', rule: 'minLength', limit: 2 }] });

    const since = new Date(Date.now() - 24 * 3600 * 1000);
    const today = await this.prisma.companyDriver.count({ where: { companyId, source: 'CREATED', createdAt: { gte: since } } });
    if (today >= CREATE_DRIVER_DAILY_LIMIT) {
      throw new HttpException({ code: 'CREATE_DRIVER_LIMIT', message: 'Daily limit reached', limit: CREATE_DRIVER_DAILY_LIMIT }, HttpStatus.TOO_MANY_REQUESTS);
    }

    const user = await this.prisma.user.findUnique({ where: { phone }, include: { driver: { select: { id: true } } } });
    let result: 'CREATED' | 'INVITED_EXISTING' | 'ALREADY_IN_LIST';
    let rowId: string;
    if (user?.driver) {
      const driverId = user.driver.id;
      const existing = await this.prisma.companyDriver.findUnique({ where: { companyId_driverId: { companyId, driverId } } });
      const hasDeals = (await this.prisma.deal.count({ where: { companyId, driverId } })) > 0;
      if (existing?.status === 'ACTIVE' || existing?.status === 'PENDING' || (!existing && hasDeals)) {
        result = 'ALREADY_IN_LIST';
        rowId = existing?.id ?? driverId;
      } else {
        const row = existing
          ? await this.prisma.companyDriver.update({ where: { id: existing.id }, data: { source: 'CREATED', status: 'PENDING', name: cleanName, respondedAt: null } })
          : await this.prisma.companyDriver.create({ data: { companyId, driverId, name: cleanName, source: 'CREATED', status: 'PENDING', createdByUserId: ctx.user.id } });
        result = 'INVITED_EXISTING';
        rowId = row.id;
      }
    } else {
      const row = await this.prisma.companyDriver.upsert({
        where: { companyId_phone: { companyId, phone } },
        create: { companyId, phone, name: cleanName, source: 'CREATED', status: 'PENDING', createdByUserId: ctx.user.id },
        update: { name: cleanName, status: 'PENDING' },
      });
      result = 'CREATED';
      rowId = row.id;
    }
    // В журнал — без телефона (ПДн): строка списка и исход.
    await this.audit(ctx.user.id, 'COMPANY_DRIVER_CREATED', rowId, { result });
    const link = await this.shares.create(ctx, 'COMPANY', companyId);
    return { result, url: link.url };
  }

  /// Вход водителя: приглашения на его номер привязываются к нему.
  async attachByPhone(driverId: string, phone: string | null) {
    if (!phone) return;
    const rows = await this.prisma.companyDriver.findMany({ where: { phone, driverId: null } });
    for (const r of rows) {
      const dup = await this.prisma.companyDriver.findUnique({ where: { companyId_driverId: { companyId: r.companyId, driverId } } });
      if (dup) {
        await this.prisma.companyDriver.delete({ where: { id: r.id } });
        if (dup.status === 'DECLINED' || dup.status === 'LEFT') continue;
      } else {
        // Телефон больше не нужен — водитель есть.
        await this.prisma.companyDriver.update({ where: { id: r.id }, data: { driverId, phone: null } });
      }
    }
  }

  /// «Компании, где я в списке» + приглашения «Компания X добавила вас».
  async listForDriver(driverId: string, phone: string | null) {
    await this.attachByPhone(driverId, phone);
    const [rows, deals] = await Promise.all([
      this.prisma.companyDriver.findMany({ where: { driverId }, include: { company: { select: { id: true, name: true } } } }),
      this.prisma.deal.findMany({ where: { driverId }, distinct: ['companyId'], select: { company: { select: { id: true, name: true } } } }),
    ]);
    const hidden = new Set(rows.filter((r) => r.status === 'DECLINED' || r.status === 'LEFT').map((r) => r.companyId));
    const out = new Map<string, { companyId: string; companyName: string; status: 'ACTIVE' | 'PENDING' }>();
    for (const d of deals) if (!hidden.has(d.company.id)) out.set(d.company.id, { companyId: d.company.id, companyName: d.company.name, status: 'ACTIVE' });
    for (const r of rows) {
      if (r.status !== 'ACTIVE' && r.status !== 'PENDING') continue;
      const prev = out.get(r.companyId);
      out.set(r.companyId, { companyId: r.companyId, companyName: r.company.name, status: r.status === 'PENDING' && !prev ? 'PENDING' : 'ACTIVE' });
    }
    return [...out.values()].sort((a, b) => Number(b.status === 'PENDING') - Number(a.status === 'PENDING') || a.companyName.localeCompare(b.companyName));
  }

  async respond(driverId: string, companyId: string, decision: 'ACCEPT' | 'DECLINE', actorUserId: string) {
    const row = await this.prisma.companyDriver.findUnique({ where: { companyId_driverId: { companyId, driverId } } });
    if (!row || row.status !== 'PENDING') throw new NotFoundException({ code: 'NO_INVITATION', message: 'No pending invitation' });
    await this.prisma.companyDriver.update({ where: { id: row.id }, data: { status: decision === 'ACCEPT' ? 'ACTIVE' : 'DECLINED', respondedAt: new Date() } });
    await this.audit(actorUserId, decision === 'ACCEPT' ? 'COMPANY_DRIVER_ACCEPTED' : 'COMPANY_DRIVER_DECLINED', row.id);
    return { status: decision === 'ACCEPT' ? 'ACTIVE' : 'DECLINED' };
  }

  /// Выйти из списка компании — и сохранённого, и «по сделкам».
  async leave(driverId: string, companyId: string, actorUserId: string) {
    const company = await this.prisma.company.findUnique({ where: { id: companyId }, select: { id: true } });
    if (!company) throw new NotFoundException('Company not found');
    const row = await this.prisma.companyDriver.upsert({
      where: { companyId_driverId: { companyId, driverId } },
      create: { companyId, driverId, source: 'SAVED', status: 'LEFT', respondedAt: new Date() },
      update: { status: 'LEFT', respondedAt: new Date() },
    });
    await this.audit(actorUserId, 'COMPANY_DRIVER_LEFT', row.id);
    return { status: 'LEFT' };
  }

  assertCompany(ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return ctx.companyMember.companyId;
  }
}
