import { Module } from '@nestjs/common';
import { DriversModule } from '../drivers/drivers.module';
import { CompaniesModule } from '../companies/companies.module';
import { SmsModule } from '../sms/sms.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  imports: [DriversModule, CompaniesModule, SmsModule],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
