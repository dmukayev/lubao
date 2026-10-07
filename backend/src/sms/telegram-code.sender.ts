import { Injectable, Logger } from '@nestjs/common';

type FetchLike = (url: string, init: { method: string; headers: Record<string, string>; body: string; signal: AbortSignal }) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

export const TELEGRAM_TIMEOUT_MS = 10_000;

/// Код входа через Telegram Gateway (gateway.telegram.org, задача 042 п.3):
/// сообщение от официального аккаунта «Verification Codes». Нет Telegram на
/// номере / отказ / таймаут — ошибка, SmsService берёт следующий канал.
@Injectable()
export class TelegramCodeSender {
  private readonly logger = new Logger(TelegramCodeSender.name);

  fetchFn: FetchLike = (url, init) => fetch(url, init);

  enabled(): boolean {
    return !!process.env.TELEGRAM_GATEWAY_TOKEN;
  }

  async sendCode(phone: string, code: string): Promise<void> {
    const res = await this.fetchFn('https://gateway.telegram.org/sendVerificationMessage', {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.TELEGRAM_GATEWAY_TOKEN}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone_number: phone.startsWith('+') ? phone : `+${phone}`, code, ttl: 300 }),
      signal: AbortSignal.timeout(TELEGRAM_TIMEOUT_MS),
    });
    let body: { ok?: boolean; error?: string } = {};
    try {
      body = JSON.parse(await res.text());
    } catch {
      // тело не JSON — решаем по HTTP-статусу
    }
    if (!res.ok || body.ok !== true) {
      // Номер и код в лог не пишем — только причину.
      this.logger.warn(`Telegram: код не доставлен (HTTP ${res.status}${body.error ? `, ${body.error}` : ''})`);
      throw new Error(`Telegram Gateway failed: ${body.error ?? res.status}`);
    }
  }
}
