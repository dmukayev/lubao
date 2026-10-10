import { ValidationPipe } from '@nestjs/common';
import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { assertProductionConfig } from './config/production-guard';
import { validationExceptionFactory } from './common/validation-errors';
import { SentryExceptionFilter, initSentry } from './observability/sentry';

async function bootstrap() {
  // Предохранитель прода (задача 043, п.3): с dev-настройками в production
  // сервер не стартует — до подключения к БД и очередям.
  assertProductionConfig(process.env);

  const sentryEnabled = initSentry();

  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  if (sentryEnabled) app.useGlobalFilters(new SentryExceptionFilter(app.get(HttpAdapterHost).httpAdapter));
  app.set('trust proxy', 1); // за nginx — иначе req.ip всегда внутренний IP контейнера
  // Заголовки безопасности (задача 043, п.4). CORP cross-origin: веб-клиенты
  // (кабинет логиста, админка) ходят сюда с другого origin.
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  // Задача 030, п.11 — при проверке админки с телефона через Tailscale её
  // веб-адрес отличается от localhost. CORS_ALLOWED_ORIGINS (список через
  // запятую) сузит origin до нужных адресов; не задан — как раньше,
  // открыто (локальная разработка не должна требовать .env только из-за
  // этого). В production пустой список не пропустит предохранитель.
  const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS?.split(',').map((o) => o.trim()).filter(Boolean);
  app.enableCors(allowedOrigins?.length ? { origin: allowedOrigins } : {});
  // Ошибки полей — с полем и пределом: приложение пишет конкретную причину.
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, exceptionFactory: validationExceptionFactory }));
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
