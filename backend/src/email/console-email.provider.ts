import { Injectable, Logger } from '@nestjs/common';
import { EmailProvider } from './email-provider';

/// Для локальной разработки и демо: код всегда "111111", письмо не
/// отправляется — только пишется в лог, чтобы было видно, что сервис вызван.
@Injectable()
export class ConsoleEmailProvider extends EmailProvider {
  private readonly logger = new Logger(ConsoleEmailProvider.name);

  generateCode(): string {
    return '111111';
  }

  async sendCode(email: string, code: string): Promise<void> {
    this.logger.log(`[DEV EMAIL] ${email}: ваш код — ${code}`);
  }
}
