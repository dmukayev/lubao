import { Module } from '@nestjs/common';
import { ConsoleEmailProvider } from './console-email.provider';
import { EmailProvider } from './email-provider';
import { EmailService } from './email.service';

/// Прод-провайдер (Alibaba DirectMail или аналог для qq.com/163.com — задача
/// 022, п. 14-15) подключается здесь же по образцу SmsModule, когда появятся
/// учётные данные; пока EMAIL_PROVIDER не 'console' — используем dev-заглушку.
@Module({
  providers: [
    ConsoleEmailProvider,
    {
      provide: EmailProvider,
      useExisting: ConsoleEmailProvider,
    },
    EmailService,
  ],
  exports: [EmailService],
})
export class EmailModule {}
