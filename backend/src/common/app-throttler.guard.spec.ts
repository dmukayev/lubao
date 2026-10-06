import { ExecutionContext } from '@nestjs/common';
import { AppThrottlerGuard, authLimit, defaultLimit } from './app-throttler.guard';

describe('AppThrottlerGuard (задача 043, п.4)', () => {
  it('не-HTTP контексты (WebSocket) пропускает без проверки лимита', async () => {
    const guard = Object.create(AppThrottlerGuard.prototype) as AppThrottlerGuard;
    const ctx = { getType: () => 'ws' } as unknown as ExecutionContext;
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
  });

  describe('лимиты из env', () => {
    const OLD = { ...process.env };
    afterEach(() => {
      process.env = { ...OLD };
    });

    it('по умолчанию: общий 300/мин, строгий для входа/регистрации 20/мин', () => {
      delete process.env.THROTTLE_LIMIT;
      delete process.env.THROTTLE_AUTH_LIMIT;
      expect(defaultLimit()).toBe(300);
      expect(authLimit()).toBe(20);
    });

    it('переопределяются THROTTLE_LIMIT / THROTTLE_AUTH_LIMIT', () => {
      process.env.THROTTLE_LIMIT = '50';
      process.env.THROTTLE_AUTH_LIMIT = '3';
      expect(defaultLimit()).toBe(50);
      expect(authLimit()).toBe(3);
    });
  });
});
