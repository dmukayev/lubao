import { Injectable } from '@nestjs/common';
import { Locale } from '@prisma/client';
import { TranslationProvider, TranslationResult } from './translation-provider';

/// Для локальной разработки, без ключа DeepSeek, и как аварийное
/// отключение (решение 2026-10-05: «переключатель «Перевод выкл.» в
/// админке») — ничего не переводит, сообщение доставляется с оригиналом.
@Injectable()
export class NoopTranslationProvider extends TranslationProvider {
  readonly isAvailable = false;

  async translate(): Promise<TranslationResult> {
    return { translations: {} };
  }
}
