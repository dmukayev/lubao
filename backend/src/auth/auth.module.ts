import { Module } from '@nestjs/common';
import { DriversModule } from '../drivers/drivers.module';
import { CompaniesModule } from '../companies/companies.module';
import { SmsModule } from '../sms/sms.module';
import { EmailModule } from '../email/email.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SessionService } from './session.service';

@Module({
  imports: [DriversModule, CompaniesModule, SmsModule, EmailModule],
  controllers: [AuthController],
  providers: [AuthService, SessionService],
  exports: [SessionService],
})
export class AuthModule {}
