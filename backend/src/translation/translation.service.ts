import { Injectable, Logger } from '@nestjs/common';
import { Locale, TranslationStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { maskNumerics, unmaskNumerics } from './masking';
import { TranslationProvider } from './translation-provider';

const RATE_LIMIT_PER_MINUTE = 60;

export interface TranslateMessageResult {
  translations: Partial<Record<Locale, string>>;
  status: TranslationStatus;
}

/// Перевод одного сообщения чата (задача 010, п.1-3а, 7, 9).
@Injectable()
export class TranslationService {
  private readonly logger = new Logger(TranslationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly provider: TranslationProvider,
  ) {}

  /// До 60 переводов в минуту на пользователя (п.9) — защита от расходов,
  /// не от спама (сам чат никак не лимитирован этим).
  private async underRateLimit(userId: string): Promise<boolean> {
    const key = `translation:rate:${userId}`;
    const count = await this.redis.client.incr(key);
    if (count === 1) await this.redis.client.expire(key, 60);
    return count <= RATE_LIMIT_PER_MINUTE;
  }

  private async logUsage(success: boolean, tokensUsed?: number): Promise<void> {
    await this.prisma.translationLog.create({
      data: {
        provider: process.env.TRANSLATION_PROVIDER ?? 'noop',
        model: process.env.DEEPSEEK_MODEL ?? null,
        success,
        tokensUsed,
      },
    });
  }

  /// Переводит `text` с `from` на `to`. SKIPPED — языки совпадают или
  /// лимит исчерпан (сообщение всё равно доставляется с оригиналом —
  /// п.7); FAILED — провайдер упал/вернул пусто (таймаут 5с — в самом
  /// провайдере, см. DeepSeekTranslationProvider).
  async translateMessage(senderUserId: string, text: string, from: Locale, to: Locale): Promise<TranslateMessageResult> {
    if (from === to) return { translations: {}, status: 'SKIPPED' };
    if (!(await this.underRateLimit(senderUserId))) {
      return { translations: {}, status: 'SKIPPED' };
    }

    const { masked, values } = maskNumerics(text);
    try {
      const { translations, tokensUsed } = await this.provider.translate(masked, from, [to]);
      await this.logUsage(true, tokensUsed);

      const translated = translations[to];
      if (!translated) return { translations: {}, status: 'FAILED' };

      return { translations: { [to]: unmaskNumerics(translated, values) }, status: 'DONE' };
    } catch (e) {
      this.logger.error(`Translation failed: ${(e as Error).message}`);
      await this.logUsage(false);
      return { translations: {}, status: 'FAILED' };
    }
  }
}
