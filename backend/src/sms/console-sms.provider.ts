import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider } from './sms-provider';

/// Для локальной разработки и демо: код всегда "1111", реальная SMS не
/// отправляется — только пишется в лог, чтобы было видно, что сервис вызван.
@Injectable()
export class ConsoleSmsProvider extends SmsProvider {
  private readonly logger = new Logger(ConsoleSmsProvider.name);

  generateCode(): string {
    return '1111';
  }

  async sendCode(phone: string, code: string): Promise<void> {
    this.logger.log(`[DEV SMS] ${phone}: ваш код — ${code}`);
  }
}
