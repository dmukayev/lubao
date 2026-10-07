import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { ConsoleSmsProvider } from './console-sms.provider';
import { MobizonSmsProvider } from './mobizon-sms.provider';
import { SmsProvider } from './sms-provider';
import { SmsService } from './sms.service';
import { TelegramCodeSender } from './telegram-code.sender';
import { WhatsappCodeSender } from './whatsapp-code.sender';

@Module({
  imports: [AppSettingsModule],
  providers: [
    ConsoleSmsProvider,
    MobizonSmsProvider,
    {
      provide: SmsProvider,
      useFactory: (console: ConsoleSmsProvider, mobizon: MobizonSmsProvider) =>
        process.env.SMS_PROVIDER === 'mobizon' ? mobizon : console,
      inject: [ConsoleSmsProvider, MobizonSmsProvider],
    },
    WhatsappCodeSender,
    TelegramCodeSender,
    SmsService,
  ],
  exports: [SmsService],
})
export class SmsModule {}
