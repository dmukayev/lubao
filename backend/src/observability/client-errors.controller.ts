import { Body, Controller, HttpCode, Logger, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import * as Sentry from '@sentry/node';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { THROTTLE_TTL_MS } from '../common/app-throttler.guard';
import { scrubText } from '../common/mask';
import { Public } from '../common/public.decorator';

export class ClientErrorDto {
  @IsString()
  @MaxLength(2000)
  message!: string;

  @IsOptional()
  @IsString()
  @MaxLength(8000)
  stack?: string;

  @IsIn(['ios', 'android', 'web'])
  platform!: string;

  @IsIn(['app', 'admin'])
  app!: string;

  @IsOptional()
  @IsString()
  @MaxLength(32)
  appVersion?: string;
}

/// Ошибки Flutter-клиентов (043 п.6) — через наш сервер, без SDK Sentry в
/// приложении: из Китая sentry.io может быть недоступен, а ПДн вычищаются в
/// одном месте (scrubText) до лога и до Sentry. Без входа — ошибка может
/// случиться до него; от спама — лимит по IP.
@Controller('client-errors')
export class ClientErrorsController {
  private readonly logger = new Logger('ClientError');

  @Public()
  @Throttle({ default: { limit: 20, ttl: THROTTLE_TTL_MS } })
  @Post()
  @HttpCode(204)
  report(@Body() dto: ClientErrorDto) {
    const message = scrubText(dto.message);
    const stack = dto.stack ? scrubText(dto.stack) : undefined;
    this.logger.warn(`${dto.app}/${dto.platform} ${dto.appVersion ?? '?'}: ${message.slice(0, 300)}`);
    Sentry.captureMessage(message, {
      level: 'error',
      tags: { source: 'flutter', app: dto.app, platform: dto.platform, appVersion: dto.appVersion ?? 'unknown' },
      extra: stack ? { stack } : undefined,
    });
  }
}
