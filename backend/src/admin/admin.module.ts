import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';

@Module({
  imports: [AppSettingsModule],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
