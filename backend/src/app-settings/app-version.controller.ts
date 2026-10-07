import { Controller, Get } from '@nestjs/common';
import { Public } from '../common/public.decorator';
import { AppSettingsService } from './app-settings.service';

/// Минимальная версия приложения (043 п.8): приложение спрашивает при старте,
/// до входа; ниже — экран «Обновите приложение». Пусто/нет — не требуем.
@Controller('app')
export class AppVersionController {
  constructor(private readonly appSettings: AppSettingsService) {}

  @Public()
  @Get('min-version')
  async minVersion() {
    const value = (await this.appSettings.get('minAppVersion'))?.trim();
    return { minAppVersion: value ? value : null };
  }
}
