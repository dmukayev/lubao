import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { Throttle, ThrottlerModule } from '@nestjs/throttler';
import helmet from 'helmet';
import { AppThrottlerGuard } from './app-throttler.guard';

@Controller('probe')
class ProbeController {
  @Get('open')
  open() {
    return { ok: true };
  }

  @Throttle({ default: { limit: 2, ttl: 60_000 } })
  @Get('strict')
  strict() {
    return { ok: true };
  }
}

/// Реальный HTTP-стек: глобальный guard + @Throttle + helmet (задача 043, п.4).
describe('лимиты запросов и заголовки безопасности — через настоящий HTTP', () => {
  let app: INestApplication;
  let base: string;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 50 }])],
      controllers: [ProbeController],
      providers: [{ provide: APP_GUARD, useClass: AppThrottlerGuard }],
    }).compile();
    app = moduleRef.createNestApplication();
    app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
    await app.listen(0);
    base = await app.getUrl();
  });

  afterAll(async () => {
    await app.close();
  });

  it('строгий маршрут: после лимита — 429, обычный при этом работает', async () => {
    const statuses: number[] = [];
    for (let i = 0; i < 4; i++) statuses.push((await fetch(`${base}/probe/strict`)).status);
    expect(statuses).toEqual([200, 200, 429, 429]);
    expect((await fetch(`${base}/probe/open`)).status).toBe(200);
  });

  it('ответ несёт заголовки helmet и не раскрывает Express', async () => {
    const res = await fetch(`${base}/probe/open`);
    expect(res.headers.get('x-content-type-options')).toBe('nosniff');
    expect(res.headers.get('strict-transport-security')).toContain('max-age');
    expect(res.headers.get('x-powered-by')).toBeNull();
    expect(res.headers.get('cross-origin-resource-policy')).toBe('cross-origin');
  });
});
