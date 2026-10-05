import * as fs from 'fs';
import * as path from 'path';
import { Injectable, Logger } from '@nestjs/common';
import OpenAI from 'openai';
import { Locale } from '@prisma/client';
import { TranslationProvider, TranslationResult } from './translation-provider';

const GLOSSARY: Array<Record<Locale, string>> = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'glossary.json'), 'utf-8'),
);

const LOCALE_NAMES: Record<Locale, string> = { kk: 'kk', ru: 'ru', zh: 'zh', en: 'en' };

/// DeepSeek — OpenAI-совместимый API (задача 010, п.1, decisions.md
/// «Перевод в чате: DeepSeek», 2026-10-05). `DEEPSEEK_MODEL` специально
/// без значения по умолчанию в коде («имя модели не хардкодить» — у
/// DeepSeek модели переименовываются) — это .env, не константа.
@Injectable()
export class DeepSeekTranslationProvider extends TranslationProvider {
  private readonly logger = new Logger(DeepSeekTranslationProvider.name);
  private readonly client: OpenAI;
  private readonly model: string;
  /// Неизменный префикс промпта (словарь + инструкция) — в начале каждого
  /// запроса, DeepSeek кэширует такой префикс и берёт за него меньше
  /// (п.1а).
  private readonly systemPrompt: string;

  constructor() {
    super();
    const apiKey = process.env.DEEPSEEK_API_KEY;
    const model = process.env.DEEPSEEK_MODEL;
    if (!apiKey) throw new Error('DEEPSEEK_API_KEY is not configured');
    if (!model) throw new Error('DEEPSEEK_MODEL is not configured');
    this.model = model;
    this.client = new OpenAI({ apiKey, baseURL: 'https://api.deepseek.com' });
    this.systemPrompt = this.buildSystemPrompt();
  }

  private buildSystemPrompt(): string {
    const glossaryLines = GLOSSARY.map((row) => `kk: ${row.kk} | ru: ${row.ru} | zh: ${row.zh} | en: ${row.en}`).join('\n');
    return [
      'Ты переводишь одно сообщение из чата между водителем грузовика и логистом на границе Казахстана и Китая.',
      'Сохраняй метки вида ⟦1⟧, ⟦2⟧ (и так далее) без изменений — это защищённые телефоны/номера/суммы/время/даты.',
      'Не добавляй ничего от себя, не поясняй, не меняй тон.',
      'Используй словарь терминов логистики ниже, если термин встретится в тексте:',
      glossaryLines,
      'Верни строго JSON-объект вида {"<lang>": "<перевод>", ...} с ключами — кодами запрошенных языков, без дополнительного текста.',
    ].join('\n\n');
  }

  async translate(text: string, from: Locale, to: Locale[]): Promise<TranslationResult> {
    const targets = to.filter((lang) => lang !== from);
    if (targets.length === 0) return { translations: {} };

    const userPrompt = [
      `Исходный язык: ${LOCALE_NAMES[from]}`,
      `Переведи на: ${targets.map((l) => LOCALE_NAMES[l]).join(', ')}`,
      'Сообщение:',
      text,
    ].join('\n');

    const completion = await this.client.chat.completions.create(
      {
        model: this.model,
        temperature: 0.2,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: this.systemPrompt },
          { role: 'user', content: userPrompt },
        ],
      },
      { timeout: 5000 },
    );

    const raw = completion.choices[0]?.message?.content ?? '{}';
    let parsed: Record<string, string> = {};
    try {
      parsed = JSON.parse(raw);
    } catch {
      this.logger.error('DeepSeek returned non-JSON response');
      return { translations: {}, tokensUsed: completion.usage?.total_tokens };
    }

    const translations: Partial<Record<Locale, string>> = {};
    for (const lang of targets) {
      const value = parsed[lang];
      if (typeof value === 'string') translations[lang] = value;
    }
    return { translations, tokensUsed: completion.usage?.total_tokens };
  }
}
