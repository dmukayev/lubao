import { Body, Controller, Delete, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications/device-tokens')
export class DeviceTokensController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post()
  register(@CurrentUser() ctx: RequestContext, @Body() dto: RegisterDeviceTokenDto) {
    return this.notifications.registerDeviceToken(ctx.user.id, dto.token, dto.platform).then(() => ({ success: true }));
  }

  @Delete(':token')
  unregister(@Param('token') token: string) {
    return this.notifications.unregisterDeviceToken(token).then(() => ({ success: true }));
  }
}
