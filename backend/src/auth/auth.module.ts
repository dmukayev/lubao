import { Module } from '@nestjs/common';
import { DriversModule } from '../drivers/drivers.module';
import { CompaniesModule } from '../companies/companies.module';
import { SmsModule } from '../sms/sms.module';
import { EmailModule } from '../email/email.module';
import { UploadsModule } from '../uploads/uploads.module';
import { AccountDeletionService } from './account-deletion.service';
import { AuthController } from './auth.controller';
import { TelegramLoginController } from './telegram-login.controller';
import { TelegramLoginService } from './telegram-login.service';
import { AuthService } from './auth.service';
import { SessionService } from './session.service';

@Module({
  imports: [DriversModule, CompaniesModule, SmsModule, EmailModule, UploadsModule],
  controllers: [AuthController, TelegramLoginController],
  providers: [AuthService, SessionService, AccountDeletionService, TelegramLoginService],
  exports: [SessionService],
})
export class AuthModule {}
