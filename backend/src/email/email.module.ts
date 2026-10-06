import { Module } from '@nestjs/common';
import { ConsoleEmailProvider } from './console-email.provider';
import { EmailProvider } from './email-provider';
import { EmailService } from './email.service';
import { SmtpEmailProvider } from './smtp-email.provider';

/// EMAIL_PROVIDER=smtp — боевая отправка (задача 042, п.2); иначе dev-заглушка
/// с кодом 111111. Без SMTP прод не стартует (предохранитель, задача 043).
@Module({
  providers: [
    ConsoleEmailProvider,
    SmtpEmailProvider,
    {
      provide: EmailProvider,
      useFactory: (console: ConsoleEmailProvider, smtp: SmtpEmailProvider) => (process.env.EMAIL_PROVIDER === 'smtp' ? smtp : console),
      inject: [ConsoleEmailProvider, SmtpEmailProvider],
    },
    EmailService,
  ],
  exports: [EmailService],
})
export class EmailModule {}
