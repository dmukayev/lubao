import { ForbiddenException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { SessionService } from './session.service';

function makePrismaMock() {
  return {
    session: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
    },
  };
}

function makeTokensMock() {
  let counter = 0;
  return {
    generateRefreshToken: jest.fn(() => `refresh-${++counter}`),
    hashToken: jest.fn((token: string) => `hash(${token})`),
    refreshTtlMs: jest.fn((role: string) => ({ DRIVER: 90, COMPANY: 30, ADMIN: 12 })[role] ?? 0),
    signAccessToken: jest.fn(async () => 'signed-access-token'),
  };
}

/// In-memory замена ioredis только под то, что использует SessionService —
/// get/set с TTL (TTL здесь не моделируем, тесты сами не ждут 30с).
function makeRedisMock() {
  const store = new Map<string, string>();
  return {
    client: {
      get: jest.fn(async (key: string) => store.get(key) ?? null),
      set: jest.fn(async (key: string, value: string) => {
        store.set(key, value);
      }),
    },
  };
}

describe('SessionService', () => {
  let prisma: ReturnType<typeof makePrismaMock>;
  let tokens: ReturnType<typeof makeTokensMock>;
  let redis: ReturnType<typeof makeRedisMock>;
  let service: SessionService;

  beforeEach(() => {
    prisma = makePrismaMock();
    tokens = makeTokensMock();
    redis = makeRedisMock();
    service = new SessionService(prisma as any, tokens as any, redis as any);
  });

  it('createSession stores a hashed refresh token and signs an access token with the session id', async () => {
    prisma.session.create.mockResolvedValue({ id: 'session-1' });
    prisma.session.findMany.mockResolvedValue([]);

    const result = await service.createSession('user-1', 'DRIVER', 'iPhone', 'ios');

    expect(prisma.session.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          refreshTokenHash: 'hash(refresh-1)',
          deviceName: 'iPhone',
          platform: 'ios',
        }),
      }),
    );
    expect(tokens.signAccessToken).toHaveBeenCalledWith({ sub: 'user-1', role: 'DRIVER', sid: 'session-1' });
    expect(result).toEqual({ accessToken: 'signed-access-token', refreshToken: 'refresh-1' });
  });

  describe('rotateSession', () => {
    it('rotates a valid, unexpired session (conditional updateMany, count 1) and extends expiresAt using the role TTL', async () => {
      const now = Date.now();
      prisma.session.findUnique.mockResolvedValueOnce({
        id: 'session-1',
        userId: 'user-1',
        revokedAt: null,
        expiresAt: new Date(now + 1000),
        user: { role: 'COMPANY' },
      });
      prisma.session.updateMany.mockResolvedValueOnce({ count: 1 });

      const result = await service.rotateSession('old-refresh');

      expect(prisma.session.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'session-1', refreshTokenHash: 'hash(old-refresh)' },
          data: expect.objectContaining({
            refreshTokenHash: 'hash(refresh-1)',
            previousTokenHash: 'hash(old-refresh)',
          }),
        }),
      );
      expect(tokens.refreshTtlMs).toHaveBeenCalledWith('COMPANY');
      expect(result).toEqual({ accessToken: 'signed-access-token', refreshToken: 'refresh-1' });
      // победитель кладёт пару в Redis под старым hash — на случай, если
      // параллельный запрос с тем же токеном придёт следом.
      expect(redis.client.set).toHaveBeenCalledWith(
        'session:rotated:hash(old-refresh)',
        JSON.stringify(result),
        'EX',
        30,
      );
    });

    it('rejects a blocked user with ACCOUNT_BLOCKED instead of issuing new tokens (задача 026, п.5)', async () => {
      prisma.session.findUnique.mockResolvedValueOnce({
        id: 'session-1',
        userId: 'user-1',
        revokedAt: null,
        expiresAt: new Date(Date.now() + 1000),
        user: { role: 'COMPANY', isBlocked: true },
      });

      await expect(service.rotateSession('old-refresh')).rejects.toThrow(ForbiddenException);
      expect(prisma.session.updateMany).not.toHaveBeenCalled();
    });

    it('throws on an unknown refresh token — no grace-cache retry delay for garbage tokens', async () => {
      prisma.session.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce(null);

      await expect(service.rotateSession('unknown')).rejects.toThrow(UnauthorizedException);
      expect(redis.client.get).not.toHaveBeenCalled();
    });

    it('throws and revokes the session when a previously-rotated token is reused well after the grace period', async () => {
      prisma.session.findUnique
        .mockResolvedValueOnce(null) // not the current refreshTokenHash
        .mockResolvedValueOnce({ id: 'session-1', lastUsedAt: new Date(Date.now() - 60_000) }); // rotated 60s ago — outside grace

      await expect(service.rotateSession('stolen-old-token')).rejects.toThrow('Refresh token reuse detected');
      expect(prisma.session.update).toHaveBeenCalledWith({
        where: { id: 'session-1' },
        data: { revokedAt: expect.any(Date) },
      });
    });

    it('throws on a revoked session even if the hash still matches', async () => {
      prisma.session.findUnique.mockResolvedValueOnce({
        id: 'session-1',
        revokedAt: new Date(),
        expiresAt: new Date(Date.now() + 1000),
        user: { role: 'DRIVER' },
      });
      prisma.session.findUnique.mockResolvedValueOnce(null);

      await expect(service.rotateSession('revoked-token')).rejects.toThrow(UnauthorizedException);
    });

    it('throws on an expired session', async () => {
      prisma.session.findUnique.mockResolvedValueOnce({
        id: 'session-1',
        revokedAt: null,
        expiresAt: new Date(Date.now() - 1000),
        user: { role: 'DRIVER' },
      });
      prisma.session.findUnique.mockResolvedValueOnce(null);

      await expect(service.rotateSession('expired-token')).rejects.toThrow(UnauthorizedException);
    });

    describe('grace period for a second parallel/near-parallel request with the same token (024 п.4)', () => {
      const session = {
        id: 'session-1',
        userId: 'user-1',
        revokedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
        user: { role: 'COMPANY' },
      };

      it('two truly parallel refreshes of the same token both resolve to the identical pair, session stays alive', async () => {
        // Оба запроса читают одну и ту же ещё не обновлённую сессию — как
        // было бы при реальной гонке двух вкладок веб-кабинета.
        prisma.session.findUnique.mockResolvedValue(session);
        // Первый updateMany побеждает (count 1), второй — проигрывает (count 0),
        // ровно как в реальной БД с условием в WHERE.
        prisma.session.updateMany.mockResolvedValueOnce({ count: 1 }).mockResolvedValueOnce({ count: 0 });

        const [first, second] = await Promise.all([
          service.rotateSession('old-refresh'),
          service.rotateSession('old-refresh'),
        ]);

        expect(first).toEqual(second);
        expect(prisma.session.update).not.toHaveBeenCalled(); // сессия не отозвана как «кража»
      });

      it('a second request arriving just after rotation (previousTokenHash match, within grace) gets the same pair, not a revoke', async () => {
        // Первый запрос ротирует как обычно.
        prisma.session.findUnique.mockResolvedValueOnce(session);
        prisma.session.updateMany.mockResolvedValueOnce({ count: 1 });
        const first = await service.rotateSession('old-refresh');

        // Второй запрос с тем же старым токеном приходит чуть позже — он уже
        // не совпадает с текущим refreshTokenHash, только с previousTokenHash.
        prisma.session.findUnique
          .mockResolvedValueOnce(null)
          .mockResolvedValueOnce({ id: 'session-1', lastUsedAt: new Date() }); // ротация только что была

        const second = await service.rotateSession('old-refresh');

        expect(second).toEqual(first);
        expect(prisma.session.update).not.toHaveBeenCalled();
      });
    });
  });

  it('revokeByRefreshToken is idempotent and matches either current or previous hash', async () => {
    prisma.session.updateMany.mockResolvedValue({ count: 0 });
    await expect(service.revokeByRefreshToken('whatever')).resolves.toBeUndefined();
    expect(prisma.session.updateMany).toHaveBeenCalledWith({
      where: { OR: [{ refreshTokenHash: 'hash(whatever)' }, { previousTokenHash: 'hash(whatever)' }], revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
  });

  it('revokeSession throws NotFoundException when the session is not the caller\'s or already gone', async () => {
    prisma.session.updateMany.mockResolvedValue({ count: 0 });
    await expect(service.revokeSession('session-1', 'user-1')).rejects.toThrow(NotFoundException);
  });

  it('revokeAllExceptCurrent excludes only the current session id', async () => {
    prisma.session.updateMany.mockResolvedValue({ count: 2 });
    await service.revokeAllExceptCurrent('user-1', 'current-session');
    expect(prisma.session.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', id: { not: 'current-session' }, revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
  });

  it('isSessionActive is false for missing, revoked, or expired sessions and true otherwise', async () => {
    prisma.session.findUnique.mockResolvedValueOnce(null);
    expect(await service.isSessionActive('s1')).toBe(false);

    prisma.session.findUnique.mockResolvedValueOnce({ revokedAt: new Date(), expiresAt: new Date(Date.now() + 1000) });
    expect(await service.isSessionActive('s2')).toBe(false);

    prisma.session.findUnique.mockResolvedValueOnce({ revokedAt: null, expiresAt: new Date(Date.now() - 1000) });
    expect(await service.isSessionActive('s3')).toBe(false);

    prisma.session.findUnique.mockResolvedValueOnce({ revokedAt: null, expiresAt: new Date(Date.now() + 1000) });
    expect(await service.isSessionActive('s4')).toBe(true);
  });

  it('043 п.11: 4-я сессия водителя отзывает самую давно использованную, у админа лимита нет', async () => {
    prisma.session.create.mockResolvedValue({ id: 'new' });
    // Отсортировано по lastUsedAt desc: s1 — свежая, s3 — самая старая.
    prisma.session.findMany.mockResolvedValue([{ id: 's1' }, { id: 's2' }, { id: 's3' }]);
    await service.createSession('user-1', 'DRIVER');
    expect(prisma.session.findMany.mock.calls[0][0]).toMatchObject({ where: { userId: 'user-1', revokedAt: null, id: { not: 'new' } }, orderBy: { lastUsedAt: 'desc' } });
    expect(prisma.session.updateMany).toHaveBeenCalledWith({ where: { id: { in: ['s3'] } }, data: { revokedAt: expect.any(Date) } });

    prisma.session.findMany.mockClear();
    prisma.session.updateMany.mockClear();
    await service.createSession('admin-1', 'ADMIN');
    expect(prisma.session.findMany).not.toHaveBeenCalled();
    expect(prisma.session.updateMany).not.toHaveBeenCalled();
  });
});
