import { Body, Controller, Get, Headers, HttpCode, Param, Post, UnauthorizedException } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { Public } from '../common/public.decorator';
import { ClientIp } from '../common/client-ip.decorator';
import { authLimit, THROTTLE_TTL_MS } from '../common/app-throttler.guard';
import { AuthService } from './auth.service';
import { TelegramLoginService } from './telegram-login.service';

class TelegramStartDto {
  @IsOptional() @IsString() @MaxLength(100) deviceName?: string;
  @IsOptional() @IsString() @MaxLength(20) platform?: string;
}

/// Вход через бот Telegram (050): старт и опрос — приложению, webhook — Telegram.
@Controller()
export class TelegramLoginController {
  constructor(
    private readonly telegram: TelegramLoginService,
    private readonly auth: AuthService,
  ) {}

  @Public()
  @Throttle({ default: { limit: authLimit(), ttl: THROTTLE_TTL_MS } })
  @Post('auth/telegram/start')
  start(@Body() dto: TelegramStartDto, @ClientIp() ip: string) {
    return this.telegram.start(ip, dto.deviceName, dto.platform);
  }

  /// Опрос раз в 2 с: PENDING — ждём; READY — токены, как после SMS-кода.
  @Public()
  @Get('auth/telegram/:nonce')
  async poll(@Param('nonce') nonce: string) {
    const state = await this.telegram.consume(nonce);
    if (state.status === 'PENDING') return { status: 'PENDING' };
    const session = await this.auth.loginDriverByPhone(state.phone, state.deviceName, state.platform, { telegramUserId: state.telegramUserId });
    return { status: 'READY', ...session };
  }

  /// Webhook бота: подлинность — по секрету в заголовке (setWebhook secret_token).
  @Public()
  @Post('telegram/webhook')
  @HttpCode(200)
  async webhook(@Headers('x-telegram-bot-api-secret-token') secret: string | undefined, @Body() update: Record<string, unknown>) {
    if (!this.telegram.webhookSecretOk(secret)) throw new UnauthorizedException('Bad webhook secret');
    await this.telegram.handleUpdate(update as never);
    return { ok: true };
  }
}
