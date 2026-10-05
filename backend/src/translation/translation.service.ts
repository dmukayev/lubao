import { Inject, Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';
import { Locale, TranslationStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { maskNumerics, unmaskNumerics, verifyLabelsIntact } from './masking';
import { TranslationProvider } from './translation-provider';
import { TranslationJob, TRANSLATION_QUEUE_TOKEN } from './translation.queue';

const RATE_LIMIT_PER_MINUTE = 60;

export interface TranslateMessageResult {
  translations: Partial<Record<Locale, string>>;
  status: TranslationStatus;
}

/// Перевод одного сообщения чата (задача 010, п.1-3а, 7, 9; задача 029,
/// п.5-6).
@Injectable()
export class TranslationService {
  private readonly logger = new Logger(TranslationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly provider: TranslationProvider,
    @Inject(TRANSLATION_QUEUE_TOKEN) private readonly queue: Queue<TranslationJob>,
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

  /// Один вызов провайдера + проверка, что метки `⟦N⟧` дошли целыми
  /// (задача 029, п.5) — возвращает переведённый (ещё с метками) текст
  /// или null, если вызов упал или перевод испорчен (метка пропала/
  /// задвоилась/подменилась на другой символ — `verifyLabelsIntact`).
  private async attemptTranslate(masked: string, from: Locale, to: Locale, expectedLabelCount: number): Promise<{ text: string; tokensUsed?: number } | null> {
    try {
      const { translations, tokensUsed } = await this.provider.translate(masked, from, [to]);
      const translated = translations[to];
      if (!translated || !verifyLabelsIntact(translated, expectedLabelCount)) {
        return null;
      }
      return { text: translated, tokensUsed };
    } catch (e) {
      this.logger.error(`Translation attempt failed: ${(e as Error).message}`);
      return null;
    }
  }

  /// Переводит `text` с `from` на `to`. SKIPPED — языки совпадают или
  /// лимит исчерпан (сообщение всё равно доставляется с оригиналом —
  /// п.7); FAILED — провайдер упал, вернул пусто, или испортил метки
  /// даже после одной повторной попытки (п.5).
  async translateMessage(senderUserId: string, text: string, from: Locale, to: Locale): Promise<TranslateMessageResult> {
    if (from === to) return { translations: {}, status: 'SKIPPED' };
    // Нет настроенного провайдера (обычный режим без ключа DeepSeek) —
    // SKIPPED, не FAILED (задача 029, п.20): иначе каждое межъязычное
    // сообщение в деве/демо показывало бы «Перевод недоступен · повторить».
    if (!this.provider.isAvailable) return { translations: {}, status: 'SKIPPED' };
    if (!(await this.underRateLimit(senderUserId))) {
      return { translations: {}, status: 'SKIPPED' };
    }

    const { masked, values } = maskNumerics(text);

    let result = await this.attemptTranslate(masked, from, to, values.length);
    await this.logUsage(result !== null, result?.tokensUsed);
    if (!result) {
      // Одна повторная попытка (п.5) — модель может потерять метку/
      // продублировать её на отдельном прогоне, но обычно не на двух сразу.
      result = await this.attemptTranslate(masked, from, to, values.length);
      await this.logUsage(result !== null, result?.tokensUsed);
    }
    if (!result) return { translations: {}, status: 'FAILED' };

    return { translations: { [to]: unmaskNumerics(result.text, values) }, status: 'DONE' };
  }

  /// `send()` не ждёт перевод (задача 029, п.6) — кладёт задание и сразу
  /// отвечает; фактический перевод и обновление сообщения — в
  /// TranslationProcessor.
  async enqueueTranslation(job: TranslationJob): Promise<void> {
    await this.queue.add('translate', job, { attempts: 3, backoff: { type: 'exponential', delay: 3000 } });
  }
}
