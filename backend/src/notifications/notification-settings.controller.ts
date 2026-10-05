import { Body, Controller, Get, Param, Patch } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { SetEventSettingDto } from './dto/set-event-setting.dto';
import { NotificationsService } from './notifications.service';

/// Настройки «вкл/выкл по группе событий» в профиле (задача 011, п.4).
@Controller('notifications/settings')
export class NotificationSettingsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  get(@CurrentUser() ctx: RequestContext) {
    return this.notifications.getEventSettings(ctx.user.id);
  }

  @Patch(':eventGroup')
  set(@CurrentUser() ctx: RequestContext, @Param('eventGroup') eventGroup: string, @Body() dto: SetEventSettingDto) {
    return this.notifications.setEventSetting(ctx.user.id, eventGroup, dto.enabled);
  }
}
