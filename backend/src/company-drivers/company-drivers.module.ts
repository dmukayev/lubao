import { Module } from '@nestjs/common';
import { ShareModule } from '../share/share.module';
import { CompanyDriversController, DriverCompaniesController } from './company-drivers.controller';
import { CompanyDriversService } from './company-drivers.service';

/// 058 п.6: «Мои водители» компании и «Создать водителя».
@Module({
  imports: [ShareModule],
  controllers: [CompanyDriversController, DriverCompaniesController],
  providers: [CompanyDriversService],
  exports: [CompanyDriversService],
})
export class CompanyDriversModule {}
