import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatSystemMessagesService } from '../chats/chat-system-messages.service';
import { EmailService } from '../email/email.service';
import { appLink } from '../email/email-messages';
import { addDaysDateOnly, localDateOnly, parseDateOnly } from '../common/date-only';
import { CARGO_ARCHIVE_AFTER_DAYS } from '../cargos/cargo-lifecycle';
import { nbkRatesUrl, parseNbkRates } from './nbk-rates';

export const AGREED_CHECK_AFTER_HOURS = 2;
const AGREED_CHECK_WINDOW_HOURS = 26;
export { INVITATION_TTL_HOURS } from '../responses/invitation-ttl';
import { INVITATION_TTL_HOURS } from '../responses/invitation-ttl';
export const LOCATION_RETENTION_DAYS = 30;
const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

type FetchLike = (url: string) => Promise<{ ok: boolean; status: number; text(): Promise<string> }>;

/// Фоновые задачи (задача 042, п.4). Каждая идемпотентна: повторный запуск
/// (второй экземпляр, перезапуск посреди задачи) не делает ничего лишнего.
/// Расписание и замки — в JobsScheduler.
@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly notifications: NotificationsService,
    private readonly chatSystem: ChatSystemMessagesService,
    private readonly email: EmailService,
  ) {}

  /// Подменяется в тестах.
  fetchFn: FetchLike = (url) => fetch(url, { signal: AbortSignal.timeout(15000) });

  /// Курс НБ РК на сегодня. Ручная правка админом (source != 'nbrk') не
  /// перезаписывается автоматикой — иначе она жила бы до ближайшего запуска.
  async refreshExchangeRates(now = new Date()): Promise<{ updated: number; skippedManual: number; error?: string }> {
    const day = parseDateOnly(localDateOnly(now));
    let xml: string;
    try {
      const res = await this.fetchFn(nbkRatesUrl(day));
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      xml = await res.text();
    } catch (e) {
      this.logger.warn(`Курс НБ РК не получен: ${(e as Error).message}`);
      return { updated: 0, skippedManual: 0, error: (e as Error).message };
    }
    const rates = parseNbkRates(xml);
    if (rates.length === 0) {
      this.logger.warn('Курс НБ РК: в ответе нет USD/CNY');
      return { updated: 0, skippedManual: 0, error: 'EMPTY_RESPONSE' };
    }
    let updated = 0;
    let skippedManual = 0;
    for (const rate of rates) {
      const existing = await this.prisma.exchangeRate.findUnique({
        where: { currency_effectiveDate: { currency: rate.currency, effectiveDate: day } },
      });
      if (existing && existing.source !== 'nbrk') {
        skippedManual += 1;
        continue;
      }
      await this.prisma.exchangeRate.upsert({
        where: { currency_effectiveDate: { currency: rate.currency, effectiveDate: day } },
        update: { rateToKzt: rate.rateToKzt },
        create: { currency: rate.currency, rateToKzt: rate.rateToKzt, effectiveDate: day, source: 'nbrk' },
      });
      updated += 1;
    }
    return { updated, skippedManual };
  }

  /// При старте: курса на сегодня ещё нет — берём сразу, не ждём 10:00.
  async ensureTodayRates(now = new Date()): Promise<boolean> {
    const day = parseDateOnly(localDateOnly(now));
    const have = await this.prisma.exchangeRate.count({ where: { effectiveDate: day, currency: { in: ['USD', 'CNY'] } } });
    if (have >= 2) return false;
    await this.refreshExchangeRates(now);
    return true;
  }

  /// «Договорились?» через 2 ч после звонка/WhatsApp (задача 017/042): один
  /// push водителю на пару «водитель + груз», пока сделки по ним нет.
  /// Повтор исключён ключом в Redis (7 суток), поэтому окно просмотра —
  /// 26 ч назад: пропущенный запуск догонится следующим.
  async sendAgreedChecks(now = new Date()): Promise<{ sent: number }> {
    const events = await this.prisma.contactEvent.findMany({
      where: {
        cargoId: { not: null },
        createdAt: { lte: new Date(now.getTime() - AGREED_CHECK_AFTER_HOURS * HOUR_MS), gte: new Date(now.getTime() - AGREED_CHECK_WINDOW_HOURS * HOUR_MS) },
      },
      include: { driver: { select: { id: true, userId: true } }, company: { select: { name: true } }, cargo: { select: { status: true, publishedBy: { select: { id: true, name: true } } } } },
      orderBy: { createdAt: 'asc' },
    });

    let sent = 0;
    const seen = new Set<string>();
    for (const event of events) {
      const pair = `${event.driverId}:${event.cargoId}`;
      if (seen.has(pair)) continue;
      seen.add(pair);
      // Груз уже не ищет водителя — спрашивать не о чем.
      if (event.cargo?.status !== 'PUBLISHED') continue;
      // Сделка/выбор уже есть — договорились, не переспрашиваем.
      const decided = await this.prisma.response.count({
        where: { cargoId: event.cargoId!, driverId: event.driverId, status: 'SELECTED' },
      });
      if (decided > 0) continue;

      const first = await this.redis.client.set(`agreed:sent:${pair}`, '1', 'EX', 7 * 24 * 3600, 'NX');
      if (first !== 'OK') continue;

      const chat = await this.prisma.chat.findFirst({
        where: { driverId: event.driverId, companyId: event.companyId, cargoId: event.cargoId },
        select: { id: true },
      });
      await this.notifications.notify({ userIds: [event.driver.userId] }, 'AGREED_CHECK', {
        counterpartName: event.cargo?.publishedBy?.name ?? event.company.name,
        cargoId: event.cargoId,
        chatId: chat?.id ?? null,
      });
      sent += 1;
    }
    return { sent };
  }

  /// «Договорились?»-дайджест логисту (задача 042, п.2): раз в сутки одно
  /// письмо на сотрудника компании — сколько водителей звонили по её
  /// опубликованным грузам (звонок > 2 ч назад, водитель ещё не выбран).
  /// Повторное письмо за те же сутки исключено ключом в Redis.
  async sendAgreedDigests(now = new Date()): Promise<{ companies: number; emails: number }> {
    const events = await this.prisma.contactEvent.findMany({
      where: {
        cargoId: { not: null },
        createdAt: { lte: new Date(now.getTime() - AGREED_CHECK_AFTER_HOURS * HOUR_MS), gte: new Date(now.getTime() - DAY_MS) },
        cargo: { status: 'PUBLISHED' },
      },
      select: { companyId: true, driverId: true, cargoId: true },
    });
    const byCompany = new Map<string, Set<string>>();
    for (const e of events) {
      const pairs = byCompany.get(e.companyId) ?? new Set<string>();
      pairs.add(`${e.driverId}:${e.cargoId}`);
      byCompany.set(e.companyId, pairs);
    }

    const day = localDateOnly(now);
    let companies = 0;
    let emails = 0;
    for (const [companyId, pairs] of byCompany) {
      const first = await this.redis.client.set(`agreed:digest:${companyId}:${day}`, '1', 'EX', 36 * 3600, 'NX');
      if (first !== 'OK') continue;
      const members = await this.prisma.companyMember.findMany({
        where: { companyId, user: { email: { not: null } } },
        select: { user: { select: { email: true, locale: true } } },
      });
      companies += 1;
      for (const member of members) {
        try {
          await this.email.sendTemplate(member.user.email!, 'AGREED_DIGEST', member.user.locale, { count: pairs.size, link: appLink('chats') });
          emails += 1;
        } catch (e) {
          this.logger.warn(`Дайджест «Договорились?» не отправлен: ${(e as Error).message}`);
        }
      }
    }
    return { companies, emails };
  }

  /// Архив груза через 3 дня после даты готовности (не 48 ч, CLAUDE.md):
  /// сам груз уходит в ARCHIVED, висящие отклики/приглашения закрываются.
  async archiveCargos(now = new Date()): Promise<{ archived: number }> {
    const threshold = parseDateOnly(addDaysDateOnly(localDateOnly(now), -CARGO_ARCHIVE_AFTER_DAYS));
    const stale = await this.prisma.cargo.findMany({
      where: { status: 'PUBLISHED', readyDate: { lte: threshold } },
      select: { id: true },
    });
    if (stale.length === 0) return { archived: 0 };
    const ids = stale.map((c) => c.id);
    const res = await this.prisma.cargo.updateMany({
      where: { id: { in: ids }, status: 'PUBLISHED' },
      data: { status: 'ARCHIVED', archivedAt: now },
    });
    await this.prisma.response.updateMany({
      where: { cargoId: { in: ids }, status: { in: ['PENDING', 'INVITED'] } },
      data: { status: 'CANCELLED', closeReason: 'CARGO_ARCHIVED' },
    });
    return { archived: res.count };
  }

  /// Приглашение без ответа 24 ч истекает (decisions: приглашение с согласием).
  async expireInvitations(now = new Date()): Promise<{ expired: number }> {
    const stale = await this.prisma.response.findMany({
      where: { status: 'INVITED', updatedAt: { lt: new Date(now.getTime() - INVITATION_TTL_HOURS * HOUR_MS) } },
      include: { driver: { select: { userId: true, fullName: true } }, cargo: { select: { companyId: true } } },
    });
    let expired = 0;
    for (const response of stale) {
      // Условный апдейт: водитель мог согласиться/отказаться за эти секунды.
      const res = await this.prisma.response.updateMany({ where: { id: response.id, status: 'INVITED' }, data: { status: 'CANCELLED', closeReason: 'INVITE_EXPIRED' } });
      if (res.count === 0) continue;
      expired += 1;
      await this.chatSystem.post({
        driverId: response.driverId,
        companyId: response.cargo.companyId,
        cargoId: response.cargoId,
        actorUserId: response.driver.userId,
        code: 'INVITATION_EXPIRED',
        systemParams: { driverName: response.driver.fullName },
      });
    }
    return { expired };
  }

  /// Геопозиции старше 30 дней не храним (политика, 043).
  async cleanupLocations(now = new Date()): Promise<{ cleared: number }> {
    const res = await this.prisma.driver.updateMany({
      where: { locationUpdatedAt: { lt: new Date(now.getTime() - LOCATION_RETENTION_DAYS * DAY_MS) } },
      data: { currentLat: null, currentLng: null, locationUpdatedAt: null },
    });
    return { cleared: res.count };
  }

  /// Просроченные и давно отозванные сессии. Коды входа живут в Redis с TTL
  /// и истекают сами.
  async cleanupSessions(now = new Date()): Promise<{ deleted: number }> {
    const res = await this.prisma.session.deleteMany({
      where: {
        OR: [{ expiresAt: { lt: new Date(now.getTime() - 7 * DAY_MS) } }, { revokedAt: { lt: new Date(now.getTime() - 30 * DAY_MS) } }],
      },
    });
    return { deleted: res.count };
  }
}
