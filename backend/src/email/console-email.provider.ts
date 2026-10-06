import { Injectable, Logger } from '@nestjs/common';
import { EmailProvider } from './email-provider';

/// Для локальной разработки и демо: код всегда "111111", письмо не
/// отправляется — только пишется в лог, чтобы было видно, что сервис вызван.
@Injectable()
export class ConsoleEmailProvider extends EmailProvider {
  private readonly logger = new Logger(ConsoleEmailProvider.name);

  generateCode(): string {
    this.assertNotProduction();
    return '111111';
  }

  /// Dev-код 111111 — только вне production (задача 043, п.3).
  private assertNotProduction() {
    if (process.env.NODE_ENV === 'production') throw new Error('ConsoleEmailProvider is disabled in production');
  }

  async sendCode(email: string, code: string, _locale?: 'kk' | 'ru' | 'zh' | 'en'): Promise<void> {
    this.assertNotProduction();
    this.logger.log(`[DEV EMAIL] ${email}: ваш код — ${code}`);
  }

  async sendMessage(email: string, subject: string, bodyText: string): Promise<void> {
    this.assertNotProduction();
    this.logger.log(`[DEV EMAIL] ${email}: ${subject}\n${bodyText}`);
  }
}
