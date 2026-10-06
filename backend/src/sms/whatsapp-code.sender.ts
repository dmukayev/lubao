import { Injectable, Logger } from '@nestjs/common';

type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string; signal: AbortSignal }) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

export const WHATSAPP_TIMEOUT_MS = 10_000;

/// Код входа в WhatsApp (задача 042, п.3): Meta Cloud API, шаблон категории
/// authentication с кнопкой «Скопировать код». Без ключей канал выключен —
/// вход идёт по SMS (Mobizon). env: WHATSAPP_TOKEN, WHATSAPP_PHONE_ID,
/// WHATSAPP_TEMPLATE (+ WHATSAPP_TEMPLATE_LANG, по умолчанию ru).
@Injectable()
export class WhatsappCodeSender {
  private readonly logger = new Logger(WhatsappCodeSender.name);

  /// Подменяется в тестах.
  fetchFn: FetchLike = (url, init) => fetch(url, init);

  enabled(): boolean {
    return !!(process.env.WHATSAPP_TOKEN && process.env.WHATSAPP_PHONE_ID && process.env.WHATSAPP_TEMPLATE);
  }

  /// Бросает при любой неудаче (нет WhatsApp у номера, отказ API, таймаут
  /// 10 с) — вызывающий переключается на SMS.
  async sendCode(phone: string, code: string): Promise<void> {
    const version = process.env.WHATSAPP_API_VERSION || 'v20.0';
    const url = `https://graph.facebook.com/${version}/${process.env.WHATSAPP_PHONE_ID}/messages`;
    const body = {
      messaging_product: 'whatsapp',
      to: phone.replace(/^\+/, ''),
      type: 'template',
      template: {
        name: process.env.WHATSAPP_TEMPLATE,
        language: { code: process.env.WHATSAPP_TEMPLATE_LANG || 'ru' },
        components: [
          { type: 'body', parameters: [{ type: 'text', text: code }] },
          // Кнопка «Скопировать код» шаблона authentication принимает тот же код.
          { type: 'button', sub_type: 'url', index: '0', parameters: [{ type: 'text', text: code }] },
        ],
      },
    };
    const res = await this.fetchFn(url, {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(WHATSAPP_TIMEOUT_MS),
    });
    if (!res.ok) {
      // Тело ответа Meta может содержать номер — в лог только статус.
      this.logger.warn(`WhatsApp: код не доставлен (HTTP ${res.status})`);
      throw new Error(`WhatsApp request failed: ${res.status}`);
    }
  }
}
