import { Module } from '@nestjs/common';
import { ConsoleSmsProvider } from './console-sms.provider';
import { MobizonSmsProvider } from './mobizon-sms.provider';
import { SmsProvider } from './sms-provider';
import { SmsService } from './sms.service';

@Module({
  providers: [
    ConsoleSmsProvider,
    MobizonSmsProvider,
    {
      provide: SmsProvider,
      useFactory: (console: ConsoleSmsProvider, mobizon: MobizonSmsProvider) =>
        process.env.SMS_PROVIDER === 'mobizon' ? mobizon : console,
      inject: [ConsoleSmsProvider, MobizonSmsProvider],
    },
    SmsService,
  ],
  exports: [SmsService],
})
export class SmsModule {}
