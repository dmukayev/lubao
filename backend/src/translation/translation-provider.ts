import { Locale } from '@prisma/client';

export interface TranslationResult {
  translations: Partial<Record<Locale, string>>;
  tokensUsed?: number;
}

/// Абстракция провайдера перевода (задача 010, п.1). Выбор реализации —
/// через .env (TRANSLATION_PROVIDER), по аналогии с SmsProvider/
/// EmailProvider/PushProvider. `text` уже промаскирован (см. masking.ts) —
/// провайдер не знает о цифрах/метках, только переводит текст с метками
/// как есть, сохраняя их неизменными (это требование — в системном
/// промпте DeepSeek-провайдера, не здесь).
export abstract class TranslationProvider {
  abstract translate(text: string, from: Locale, to: Locale[]): Promise<TranslationResult>;
}
