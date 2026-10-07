import { Controller, Get, INestApplication } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { Throttle, ThrottlerModule } from '@nestjs/throttler';
import helmet from 'helmet';
import { AppThrottlerGuard, userThrottler } from './app-throttler.guard';

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

/// 043 п.11: лимит на пользователя — по `sub` токена, не по IP; без токена и
/// у админа не действует.
describe('лимит запросов на пользователя — через настоящий HTTP', () => {
  let app: INestApplication;
  let base: string;
  const token = (sub: string, role = 'DRIVER') =>
    `Bearer x.${Buffer.from(JSON.stringify({ sub, role })).toString('base64url')}.y`;

  beforeAll(async () => {
    process.env.THROTTLE_USER_LIMIT = '3';
    const moduleRef = await Test.createTestingModule({
      imports: [ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 50 }, userThrottler()])],
      controllers: [ProbeController],
      providers: [{ provide: APP_GUARD, useClass: AppThrottlerGuard }],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.listen(0);
    base = await app.getUrl();
  });

  afterAll(async () => {
    delete process.env.THROTTLE_USER_LIMIT;
    await app.close();
  });

  it('4-й запрос одного водителя — 429, другой водитель и аноним не задеты, админ без лимита', async () => {
    const get = (auth?: string) => fetch(`${base}/probe/open`, { headers: auth ? { authorization: auth } : {} }).then((r) => r.status);
    const a: number[] = [];
    for (let i = 0; i < 4; i++) a.push(await get(token('driver-a')));
    expect(a).toEqual([200, 200, 200, 429]);
    expect(await get(token('driver-b'))).toBe(200);
    expect(await get()).toBe(200);
    for (let i = 0; i < 5; i++) expect(await get(token('admin', 'ADMIN'))).toBe(200);
  });
});
