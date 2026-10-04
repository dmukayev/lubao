import * as crypto from 'crypto';
import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider } from './sms-provider';

/// Прод: реальная отправка через Mobizon.kz (https://mobizon.kz).
/// Нужны MOBIZON_API_KEY (и, опционально, MOBIZON_API_URL — по умолчанию
/// казахстанский регион).
@Injectable()
export class MobizonSmsProvider extends SmsProvider {
  private readonly logger = new Logger(MobizonSmsProvider.name);
  private readonly apiUrl = process.env.MOBIZON_API_URL || 'https://api.mobizon.kz/service/message/sendsmsmessage';
  private readonly apiKey = process.env.MOBIZON_API_KEY;

  generateCode(): string {
    return String(crypto.randomInt(1000, 10000));
  }

  async sendCode(phone: string, code: string): Promise<void> {
    if (!this.apiKey) {
      throw new Error('MOBIZON_API_KEY is not configured');
    }

    const params = new URLSearchParams({
      apiKey: this.apiKey,
      recipient: phone,
      text: `Lubao: ваш код подтверждения — ${code}`,
    });

    const res = await fetch(`${this.apiUrl}?${params.toString()}`, { method: 'GET' });
    if (!res.ok) {
      throw new Error(`Mobizon request failed: ${res.status} ${res.statusText}`);
    }

    const body = (await res.json()) as { code?: number; message?: string };
    if (body.code !== 0) {
      this.logger.error(`Mobizon error for ${phone}: ${JSON.stringify(body)}`);
      throw new Error(`Mobizon error: ${body.message ?? 'unknown'}`);
    }
  }
}
