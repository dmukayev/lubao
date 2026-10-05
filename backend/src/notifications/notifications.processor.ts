import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import { PushProvider } from './push/push-provider';
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
  ) {}

  onModuleInit() {
    // BullMQ требует отдельное соединение ioredis с maxRetriesPerRequest:
    // null — общий RedisService (используется для rate-limit SMS и т.п.)
    // этого не гарантирует, поэтому не делим соединение с ним.
    const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
    this.worker = new Worker<NotificationJob>(
      NOTIFICATIONS_QUEUE,
      async (job) => {
        const data = job.data;
        if (data.channel === 'PUSH') {
          await this.pushProvider.send(data.token, data.platform, { title: data.title, body: data.body, data: data.data });
        } else {
          await this.wecom.send(data.webhookUrl, data.text);
        }
      },
      { connection },
    );
    this.worker.on('failed', (job, err) => {
      this.logger.error(`Notification job ${job?.id} failed: ${err.message}`);
    });
  }

  async onModuleDestroy() {
    await this.worker?.close();
  }
}
