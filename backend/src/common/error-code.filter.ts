import { ArgumentsHost, Catch, ExceptionFilter, HttpException, Logger } from '@nestjs/common';
import { randomBytes } from 'crypto';
import type { Response } from 'express';
import { resolveErrorCode } from './error-codes';

/// 074: у каждого ответа-ошибки — `code` (см. error-codes.ts) и короткий
/// `requestId`: если приложение показывает «Что-то пошло не так», пользователь
/// называет номер, а он есть в журнале сервера. Неизвестные ошибки (5xx) —
/// в журнал с этим номером, наружу — без подробностей.
@Catch()
export class ErrorCodeFilter implements ExceptionFilter {
  private readonly logger = new Logger('Errors');

  constructor(private readonly onServerError?: (exception: unknown) => void) {}

  catch(exception: unknown, host: ArgumentsHost) {
    // Сокеты и прочее — свой обработчик Nest; здесь только HTTP.
    if (host.getType() !== 'http') throw exception;
    const res = host.switchToHttp().getResponse<Response>();
    const requestId = randomBytes(4).toString('hex');
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const raw = exception.getResponse();
      const body: Record<string, unknown> = typeof raw === 'string' ? { message: raw } : { ...(raw as Record<string, unknown>) };
      body.statusCode ??= status;
      body.code = resolveErrorCode(status, body);
      body.requestId = requestId;
      if (status >= 500) {
        this.logger.error(`[${requestId}] ${exception.message}`, exception.stack);
        this.onServerError?.(exception);
      }
      res.status(status).json(body);
      return;
    }
    this.logger.error(`[${requestId}] ${(exception as Error)?.message ?? exception}`, (exception as Error)?.stack);
    this.onServerError?.(exception);
    res.status(500).json({ statusCode: 500, code: 'SERVER_ERROR', message: 'Internal server error', requestId });
  }
}
