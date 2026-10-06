import { randomInt } from 'crypto';
import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { EmailProvider } from './email-provider';
import { renderEmail } from './email-messages';

/// Боевая отправка почты (задача 042, п.2): SMTP через nodemailer.
/// env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM (+ SMTP_SECURE=true для 465).
/// Для получателей на qq.com/163.com нужен SMTP-провайдер с доставкой в КНР
/// (Alibaba DirectMail и т.п.) — это только значения env, код тот же.
@Injectable()
export class SmtpEmailProvider extends EmailProvider {
  private readonly logger = new Logger(SmtpEmailProvider.name);
  private transport: nodemailer.Transporter | null = null;

  /// Подменяется в тестах.
  createTransport: () => nodemailer.Transporter = () =>
    nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT || 587),
      secure: process.env.SMTP_SECURE === 'true' || Number(process.env.SMTP_PORT) === 465,
      auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
    });

  generateCode(): string {
    return String(randomInt(0, 1_000_000)).padStart(6, '0');
  }

  async sendCode(email: string, code: string, locale?: Parameters<typeof renderEmail>[1]): Promise<void> {
    const { subject, text } = renderEmail('CODE', locale, { code, minutes: 10 });
    await this.sendMessage(email, subject, text);
  }

  async sendMessage(email: string, subject: string, bodyText: string): Promise<void> {
    this.transport ??= this.createTransport();
    const from = process.env.SMTP_FROM || process.env.SMTP_USER;
    try {
      await this.transport.sendMail({ from, to: email, subject, text: bodyText });
    } catch (e) {
      // Адрес и тело письма (в нём коды/ссылки) в лог не пишем.
      this.logger.error(`SMTP: письмо не отправлено: ${(e as Error).message}`);
      throw e;
    }
  }
}
