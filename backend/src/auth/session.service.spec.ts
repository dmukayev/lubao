import { NotFoundException, UnauthorizedException } from '@nestjs/common';
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

describe('SessionService', () => {
  let prisma: ReturnType<typeof makePrismaMock>;
  let tokens: ReturnType<typeof makeTokensMock>;
  let service: SessionService;

  beforeEach(() => {
    prisma = makePrismaMock();
    tokens = makeTokensMock();
    service = new SessionService(prisma as any, tokens as any);
  });

  it('createSession stores a hashed refresh token and signs an access token with the session id', async () => {
    prisma.session.create.mockResolvedValue({ id: 'session-1' });

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
    it('rotates a valid, unexpired session and extends expiresAt using the role TTL', async () => {
      const now = Date.now();
      prisma.session.findUnique.mockResolvedValueOnce({
        id: 'session-1',
        userId: 'user-1',
        revokedAt: null,
        expiresAt: new Date(now + 1000),
        user: { role: 'COMPANY' },
      });

      const result = await service.rotateSession('old-refresh');

      expect(prisma.session.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'session-1' },
          data: expect.objectContaining({
            refreshTokenHash: 'hash(refresh-1)',
            previousTokenHash: 'hash(old-refresh)',
          }),
        }),
      );
      expect(tokens.refreshTtlMs).toHaveBeenCalledWith('COMPANY');
      expect(result).toEqual({ accessToken: 'signed-access-token', refreshToken: 'refresh-1' });
    });

    it('throws on an unknown refresh token', async () => {
      prisma.session.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce(null);

      await expect(service.rotateSession('unknown')).rejects.toThrow(UnauthorizedException);
    });

    it('throws and revokes the session when a previously-rotated token is reused', async () => {
      prisma.session.findUnique
        .mockResolvedValueOnce(null) // not the current refreshTokenHash
        .mockResolvedValueOnce({ id: 'session-1' }); // matches previousTokenHash

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
});
