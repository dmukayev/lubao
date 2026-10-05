import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.set('trust proxy', 1); // за nginx — иначе req.ip всегда внутренний IP контейнера
  // Задача 030, п.11 — при проверке админки с телефона через Tailscale её
  // веб-адрес отличается от localhost. CORS_ALLOWED_ORIGINS (список через
  // запятую) сузит origin до нужных адресов; не задан — как раньше,
  // открыто (локальная разработка не должна требовать .env только из-за
  // этого). Прод — за отдельной сетевой защитой (decisions.md «Админка на
  // телефоне»: Tailscale/ограничение по IP), CORS здесь — не она.
  const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS?.split(',').map((o) => o.trim()).filter(Boolean);
  app.enableCors(allowedOrigins?.length ? { origin: allowedOrigins } : {});
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
