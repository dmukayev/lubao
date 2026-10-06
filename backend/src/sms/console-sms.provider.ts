import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider } from './sms-provider';

/// Для локальной разработки и демо: код всегда "1111", реальная SMS не
/// отправляется — только пишется в лог, чтобы было видно, что сервис вызван.
@Injectable()
export class ConsoleSmsProvider extends SmsProvider {
  private readonly logger = new Logger(ConsoleSmsProvider.name);

  generateCode(): string {
    this.assertNotProduction();
    return '1111';
  }

  /// Dev-код 1111 — только вне production (задача 043, п.3): последний рубеж
  /// на случай, если предохранитель в main.ts обошли.
  private assertNotProduction() {
    if (process.env.NODE_ENV === 'production') throw new Error('ConsoleSmsProvider is disabled in production');
  }

  async sendCode(phone: string, code: string): Promise<void> {
    this.assertNotProduction();
    this.logger.log(`[DEV SMS] ${phone}: ваш код — ${code}`);
  }
}
