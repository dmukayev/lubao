import { Module } from '@nestjs/common';
import { DriversModule } from '../drivers/drivers.module';
import { CompaniesModule } from '../companies/companies.module';
import { SmsModule } from '../sms/sms.module';
import { EmailModule } from '../email/email.module';
import { UploadsModule } from '../uploads/uploads.module';
import { AccountDeletionService } from './account-deletion.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SessionService } from './session.service';

@Module({
  imports: [DriversModule, CompaniesModule, SmsModule, EmailModule, UploadsModule],
  controllers: [AuthController],
  providers: [AuthService, SessionService, AccountDeletionService],
  exports: [SessionService],
})
export class AuthModule {}
