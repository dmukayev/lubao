import { Global, Module } from '@nestjs/common';
import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import { DeepSeekTranslationProvider } from './deepseek-translation.provider';
import { NoopTranslationProvider } from './noop-translation.provider';
import { TranslationProvider } from './translation-provider';
import { TranslationProcessor } from './translation.processor';
import { TRANSLATION_QUEUE, TRANSLATION_QUEUE_TOKEN, TranslationJob } from './translation.queue';
import { TranslationService } from './translation.service';

/// Глобальный модуль (как Notifications/Realtime) — ChatsService зовёт
/// TranslationService напрямую. Выбор провайдера — через .env
/// TRANSLATION_PROVIDER=deepseek|noop (дефолт — noop, как у остальных
/// каналов без настроенной прод-учётки). Очередь — на том же Redis, что
/// и у 011, но отдельный DI-токен (TRANSLATION_QUEUE_TOKEN), не класс
/// `Queue` — тот уже занят под уведомления.
@Global()
@Module({
  providers: [
    {
      provide: TRANSLATION_QUEUE_TOKEN,
      useFactory: () => {
        const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379', { maxRetriesPerRequest: null });
        return new Queue<TranslationJob>(TRANSLATION_QUEUE, { connection });
      },
    },
    NoopTranslationProvider,
    {
      provide: TranslationProvider,
      useFactory: (noop: NoopTranslationProvider) => {
        if (process.env.TRANSLATION_PROVIDER === 'deepseek') {
          return new DeepSeekTranslationProvider();
        }
        return noop;
      },
      inject: [NoopTranslationProvider],
    },
    TranslationService,
    TranslationProcessor,
  ],
  exports: [TranslationService],
})
export class TranslationModule {}
