import { Global, Module } from '@nestjs/common';
import { DeepSeekTranslationProvider } from './deepseek-translation.provider';
import { NoopTranslationProvider } from './noop-translation.provider';
import { TranslationProvider } from './translation-provider';
import { TranslationService } from './translation.service';

/// Глобальный модуль (как Notifications/Realtime) — ChatsService зовёт
/// TranslationService напрямую. Выбор провайдера — через .env
/// TRANSLATION_PROVIDER=deepseek|noop (дефолт — noop, как у остальных
/// каналов без настроенной прод-учётки).
@Global()
@Module({
  providers: [
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
  ],
  exports: [TranslationService],
})
export class TranslationModule {}
