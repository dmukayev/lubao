import { Global, Module } from '@nestjs/common';
import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { DeviceTokensController } from './device-tokens.controller';
import { NotificationSettingsController } from './notification-settings.controller';
import { NotificationsService } from './notifications.service';
import { NotificationsProcessor } from './notifications.processor';
import { NOTIFICATIONS_QUEUE, NotificationJob } from './notifications.queue';
import { ApnsPushProvider } from './push/apns-push.provider';
import { ConsolePushProvider } from './push/console-push.provider';
import { FcmPushProvider } from './push/fcm-push.provider';
import { JpushPushProvider } from './push/jpush-push.provider';
import { PushProvider } from './push/push-provider';
import { RealPushProvider } from './push/real-push.provider';
import { WeComService } from './wecom.service';

/// Глобальный модуль (как RedisModule/TokenModule) — NotificationsService
/// нужен из admin/cargos/responses/deals/chats, заводить его в импортах
/// каждого из них по отдельности избыточно.
@Global()
@Module({
  controllers: [DeviceTokensController, NotificationSettingsController],
  providers: [
    {
      provide: Queue,
      useFactory: () => {
        const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
        return new Queue<NotificationJob>(NOTIFICATIONS_QUEUE, { connection });
      },
    },
    ConsolePushProvider,
    FcmPushProvider,
    ApnsPushProvider,
    JpushPushProvider,
    RealPushProvider,
    {
      provide: PushProvider,
      useFactory: (console: ConsolePushProvider, real: RealPushProvider) =>
        process.env.PUSH_PROVIDER === 'real' ? real : console,
      inject: [ConsolePushProvider, RealPushProvider],
    },
    WeComService,
    NotificationsService,
    NotificationsProcessor,
  ],
  exports: [NotificationsService, WeComService],
})
export class NotificationsModule {}
