import { Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';
import { DevicePlatform, Locale } from '@prisma/client';
import { withTimeout } from '../common/with-timeout';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { NOTIFICATION_EVENTS, NotificationEvent, NotificationPayload, pickLocaleText } from './notification-events';
import { NOTIFICATIONS_QUEUE, NotificationJob } from './notifications.queue';

const QUEUE_ADD_TIMEOUT_MS = 3000;

export { pickLocaleText };

export interface NotifyTarget {
  userIds?: string[];
  companyId?: string;
}

/// Единая точка входа (задача 011, п.1): `notify(target, event, payload)` →
/// проверяет настройки получателя (группа событий + канал), throttle для
/// частых событий, и кладёт готовые к отправке задания в очередь на Redis
/// (retry — на уровне BullMQ, см. notifications.module.ts). Бизнес-логика
/// вызывающей стороны не знает о провайдерах push/WeCom вообще.
@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly queue: Queue<NotificationJob>,
  ) {}

  /// Сбой очереди (недоступный Redis) не должен ронять или подвешивать
  /// вызывающий запрос (задача 029, п.8) — отправка сообщения, отклик на
  /// груз и т.п. не должны ждать/падать из-за уведомлений. notify()
  /// поэтому сам никогда не бросает — ошибки и зависания ловятся и
  /// логируются внутри pushToUser/wecomToCompany.
  async notify(target: NotifyTarget, event: NotificationEvent, payload: NotificationPayload): Promise<void> {
    const def = NOTIFICATION_EVENTS[event];

    if (target.userIds?.length && def.channels.includes('PUSH')) {
      await Promise.all(target.userIds.map((userId) => this.pushToUser(userId, event, payload)));
    }

    if (target.companyId && def.channels.includes('WECOM')) {
      await this.wecomToCompany(target.companyId, event, payload);
    }
  }

  private async pushToUser(userId: string, event: NotificationEvent, payload: NotificationPayload): Promise<void> {
    const def = NOTIFICATION_EVENTS[event];

    const [eventSetting, channelSetting] = await Promise.all([
      this.prisma.notificationEventSetting.findUnique({ where: { userId_eventGroup: { userId, eventGroup: def.eventGroup } } }),
      this.prisma.notificationSetting.findUnique({ where: { userId_channel: { userId, channel: 'PUSH' } } }),
    ]);
    if (eventSetting?.enabled === false) return;
    if (channelSetting?.enabled === false) return;

    if (def.throttleSeconds && def.throttleKey) {
      const key = `notif:throttle:${def.throttleKey({ ...payload, recipientUserId: userId })}`;
      try {
        const set = await withTimeout(this.redis.client.set(key, '1', 'EX', def.throttleSeconds, 'NX'), QUEUE_ADD_TIMEOUT_MS, 'throttle check timed out');
        if (set === null) return;
      } catch (e) {
        // Redis недоступен — лучше продублировать push, чем молчать (задача 029, п.8).
        this.logger.error(`Throttle check failed, sending anyway: ${(e as Error).message}`);
      }
    }

    const tokens = await this.prisma.deviceToken.findMany({ where: { userId } });
    if (tokens.length === 0) return;

    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { locale: true } });
    const locale: Locale = user?.locale ?? 'ru';
    const rendered = def.render(locale, payload);
    const deepLink = def.deepLink(payload);

    await Promise.all(
      tokens.map(async (t) => {
        try {
          await withTimeout(
            this.queue.add(
              'deliver',
              {
                channel: 'PUSH' as const,
                token: t.token,
                platform: t.platform as DevicePlatform,
                title: rendered.title,
                body: rendered.body,
                data: { deepLink, event },
              },
              { attempts: 3, backoff: { type: 'exponential', delay: 5000 } },
            ),
            QUEUE_ADD_TIMEOUT_MS,
            'notifications queue.add timed out',
          );
        } catch (e) {
          this.logger.error(`Failed to enqueue push for user ${userId}: ${(e as Error).message}`);
        }
      }),
    );
  }

  private async wecomToCompany(companyId: string, event: NotificationEvent, payload: NotificationPayload): Promise<void> {
    const def = NOTIFICATION_EVENTS[event];
    const company = await this.prisma.company.findUnique({ where: { id: companyId } });
    if (!company?.wecomWebhookUrl) return;

    const owner = await this.prisma.companyMember.findFirst({
      where: { companyId, role: 'OWNER' },
      include: { user: { select: { locale: true } } },
    });
    const locale: Locale = owner?.user.locale ?? 'ru';
    const rendered = def.render(locale, payload);

    try {
      await withTimeout(
        this.queue.add(
          'deliver',
          { channel: 'WECOM' as const, webhookUrl: company.wecomWebhookUrl, text: `${rendered.title}\n${rendered.body}` },
          { attempts: 3, backoff: { type: 'exponential', delay: 5000 } },
        ),
        QUEUE_ADD_TIMEOUT_MS,
        'notifications queue.add timed out',
      );
    } catch (e) {
      this.logger.error(`Failed to enqueue WeCom message for company ${companyId}: ${(e as Error).message}`);
    }
  }

  async registerDeviceToken(userId: string, token: string, platform: DevicePlatform): Promise<void> {
    await this.prisma.deviceToken.upsert({
      where: { token },
      update: { userId, platform, lastSeenAt: new Date() },
      create: { userId, token, platform },
    });
  }

  async unregisterDeviceToken(token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({ where: { token } });
  }

  async getEventSettings(userId: string) {
    const rows = await this.prisma.notificationEventSetting.findMany({ where: { userId } });
    const byGroup = new Map(rows.map((r) => [r.eventGroup, r.enabled]));
    const groups: NotificationEvent[] = Object.keys(NOTIFICATION_EVENTS) as NotificationEvent[];
    const uniqueGroups = [...new Set(groups.map((e) => NOTIFICATION_EVENTS[e].eventGroup))];
    return uniqueGroups.map((eventGroup) => ({ eventGroup, enabled: byGroup.get(eventGroup) ?? true }));
  }

  async setEventSetting(userId: string, eventGroup: string, enabled: boolean) {
    await this.prisma.notificationEventSetting.upsert({
      where: { userId_eventGroup: { userId, eventGroup: eventGroup as never } },
      update: { enabled },
      create: { userId, eventGroup: eventGroup as never, enabled },
    });
    return { eventGroup, enabled };
  }
}
