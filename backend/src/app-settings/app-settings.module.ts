import { Module } from '@nestjs/common';
import { AppSettingsService } from './app-settings.service';
import { AppVersionController } from './app-version.controller';

@Module({
  controllers: [AppVersionController],
  providers: [AppSettingsService],
  exports: [AppSettingsService],
})
export class AppSettingsModule {}
