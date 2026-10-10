import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { UnrecoverableError, Worker } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import IORedis from 'ioredis';
import { PushProvider, PushTokenGoneError } from './push/push-provider';
import { WeComService } from './wecom.service';
import { NOTIFICATIONS_QUEUE, NotificationJob } from './notifications.queue';

/// Обработчик очереди (задача 011, п.1: «повтор при ошибке» — обеспечивает
/// BullMQ по attempts/backoff, заданным при постановке задания в
/// NotificationsService; здесь — только фактическая отправка).
@Injectable()
export class NotificationsProcessor implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationsProcessor.name);
  private worker: Worker<NotificationJob> | null = null;

  constructor(
    private readonly pushProvider: PushProvider,
    private readonly wecom: WeComService,
    private readonly prisma: PrismaService,
  ) {}

  /// Отправка одного задания. Умерший токен удаляем и не повторяем — иначе он
  /// навсегда остаётся «получателем» и каждое уведомление падает трижды.
  async process(data: NotificationJob): Promise<void> {
    if (data.channel === 'PUSH') {
      try {
        await this.pushProvider.send(data.token, data.platform, { title: data.title, body: data.body, data: data.data, category: data.category });
      } catch (e) {
        if (e instanceof PushTokenGoneError) {
          const removed = await this.prisma.deviceToken.deleteMany({ where: { token: data.token } });
          this.logger.warn(`Push token ${data.token.slice(0, 8)}… (${data.platform}) больше не действует — удалён (${removed.count})`);
          throw new UnrecoverableError(e.message);
        }
        throw e;
      }
    } else {
      await this.wecom.send(data.webhookUrl, data.text);
    }
  }

  onModuleInit() {
    // BullMQ требует отдельное соединение ioredis с maxRetriesPerRequest:
    // null — общий RedisService (используется для rate-limit SMS и т.п.)
    // этого не гарантирует, поэтому не делим соединение с ним.
    const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
    this.worker = new Worker<NotificationJob>(
      NOTIFICATIONS_QUEUE,
      async (job) => this.process(job.data),
      { connection },
    );
    this.worker.on('failed', (job, err) => {
      // Канал и начало токена — чтобы по логу было видно, куда не дошло.
      const d = job?.data;
      const where = d?.channel === 'PUSH' ? `PUSH ${d.platform} ${d.token.slice(0, 8)}…` : 'WECOM';
      this.logger.error(`Notification job ${job?.id} (${where}) failed, попытка ${job?.attemptsMade ?? '?'}: ${err.message}`);
    });
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }
}
