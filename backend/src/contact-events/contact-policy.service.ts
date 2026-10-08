import { ForbiddenException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ContactEventType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

/// Сколько РАЗНЫХ номеров аккаунт может открыть за сутки (043 п.11).
export const contactDailyLimit = () => Number(process.env.CONTACT_DAILY_LIMIT || 30);
const DAY_SECONDS = 24 * 60 * 60;

/// Телефоны — только по нажатию «Позвонить»/WhatsApp (decisions.md
/// 2026-10-07 «Телефоны — только по нажатию, с лимитом; новичку — после
/// отклика»): здесь правила доступа, суточный лимит и запись contact_events.
/// Сами номера достают сервисы грузов/водителей/чатов.
@Injectable()
export class ContactPolicyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  /// Водитель без проверки документов видит номер груза только после своего
  /// отклика «Готов взять» (или если по грузу уже сделка); проверенный — сразу.
  async assertDriverMayContactCargo(driver: { id: string; isVerified: boolean }, cargoId: string): Promise<void> {
    if (driver.isVerified) return;
    const [response, deal] = await Promise.all([
      this.prisma.response.findFirst({ where: { cargoId, driverId: driver.id, status: { in: ['PENDING', 'SELECTED'] } }, select: { id: true } }),
      this.prisma.deal.findFirst({ where: { cargoId, driverId: driver.id }, select: { id: true } }),
    ]);
    if (!response && !deal) {
      throw new ForbiddenException({ code: 'RESPOND_FIRST', message: 'Respond to the cargo first to see the phone' });
    }
  }

  /// Логист видит номер водителя только из проверенной компании.
  /// 049 п.6: водитель «виден» компании — у него активный анонс («Кто свободен»),
  /// отклик на её груз или сделка с ней. Иначе фото машин и номера ей не отдаём.
  async driverVisibleToCompany(driverId: string, companyId: string): Promise<boolean> {
    const [arrival, response, deal] = await Promise.all([
      this.prisma.arrival.findFirst({ where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } }, select: { id: true } }),
      this.prisma.response.findFirst({ where: { driverId, cargo: { companyId } }, select: { id: true } }),
      this.prisma.deal.findFirst({ where: { driverId, companyId }, select: { id: true } }),
    ]);
    return !!(arrival || response || deal);
  }

  assertCompanyMayContactDriver(company: { isVerified: boolean }): void {
    if (!company.isVerified) {
      throw new ForbiddenException({ code: 'COMPANY_NOT_VERIFIED', message: 'Company must be verified to see driver phones' });
    }
  }

  /// Суточный лимит разных номеров: повторное открытие того же номера в тот же
  /// день не считается. Превышение → 429 и запись в журнал (3 за сутки —
  /// «Требует внимания» в админке).
  /// `scope` — отдельный суточный счётчик (049 п.6: фото машин — свой лимит,
  /// не съедает лимит номеров).
  async consume(userId: string, target: string, scope = 'contacts'): Promise<void> {
    const key = `${scope}:${userId}:${new Date().toISOString().slice(0, 10)}`;
    const client = this.redis.client;
    const added = await client.sadd(key, target);
    await client.expire(key, 2 * DAY_SECONDS);
    if (added === 0) return;
    const limit = contactDailyLimit();
    if ((await client.scard(key)) <= limit) return;
    await client.srem(key, target);
    await this.prisma.auditLog.create({
      data: { actorUserId: userId, action: 'CONTACT_LIMIT_EXCEEDED', entityType: 'User', entityId: userId, metadata: { limit } },
    });
    throw new HttpException({ code: 'CONTACT_LIMIT', limit, message: 'Daily limit of opened phone numbers reached' }, HttpStatus.TOO_MANY_REQUESTS);
  }

  async record(data: { actorUserId: string; driverId: string; companyId: string; cargoId?: string | null; dealId?: string | null; type: ContactEventType }) {
    await this.prisma.contactEvent.create({
      data: { actorUserId: data.actorUserId, driverId: data.driverId, companyId: data.companyId, cargoId: data.cargoId ?? null, dealId: data.dealId ?? null, type: data.type },
    });
  }
}
