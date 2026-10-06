import { ArgumentsHost, Catch, HttpException } from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import * as Sentry from '@sentry/node';
import { scrubText } from '../common/mask';

/// Отчёты об ошибках (задача 043, п.6): SENTRY_DSN не задан — Sentry выключен.
/// Персональные данные в отчёт не уходят: тело/куки/авторизация запроса
/// вырезаются, телефоны/ИИН/email в сообщениях маскируются.

export function scrubSentryEvent<T>(input: T): T {
  // Структура события Sentry версионно плавает — работаем с ним как с обычным объектом.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const event = input as any;
  const request = event.request;
  if (request) {
    delete request.data;
    delete request.cookies;
    delete request.query_string;
    if (request.headers) {
      for (const name of Object.keys(request.headers)) {
        if (/^(authorization|cookie|x-forwarded-for|x-real-ip)$/i.test(name)) delete request.headers[name];
      }
    }
  }
  if (event.user) event.user = { id: event.user.id };
  if (typeof event.message === 'string') event.message = scrubText(event.message);
  for (const exception of event.exception?.values ?? []) {
    if (typeof exception.value === 'string') exception.value = scrubText(exception.value);
  }
  for (const crumb of event.breadcrumbs ?? []) {
    if (typeof crumb.message === 'string') crumb.message = scrubText(crumb.message);
    delete crumb.data;
  }
  return input;
}

export function initSentry(env: NodeJS.ProcessEnv = process.env): boolean {
  if (!env.SENTRY_DSN) return false;
  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.NODE_ENV,
    beforeSend: (event) => scrubSentryEvent(event),
  });
  return true;
}

/// Нестандартные 5xx уходят в Sentry, ответ клиенту формирует обычный фильтр Nest.
@Catch()
export class SentryExceptionFilter extends BaseExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const status = exception instanceof HttpException ? exception.getStatus() : 500;
    if (status >= 500) Sentry.captureException(exception);
    super.catch(exception, host);
  }
}
