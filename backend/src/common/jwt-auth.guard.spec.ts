import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtAuthGuard, lastSeenDue } from './jwt-auth.guard';

function makeContext(headers: Record<string, string | undefined>, isPublic = false) {
  const request: any = {
    header: (name: string) => headers[name],
    authContext: undefined,
  };
  const context = {
    getHandler: () => ({}),
    getClass: () => ({}),
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
  return { context, request, isPublic };
}

describe('JwtAuthGuard', () => {
  let reflector: { getAllAndOverride: jest.Mock };
  let prisma: { user: { findUnique: jest.Mock; update: jest.Mock }; driver: { findUnique: jest.Mock }; companyMember: { findUnique: jest.Mock } };
  let tokens: { verifyAccessToken: jest.Mock };
  let sessions: { isSessionActive: jest.Mock };
  let guard: JwtAuthGuard;

  const activeUser = { id: 'user-1', isActive: true, isBlocked: false, role: 'DRIVER' };

  beforeEach(() => {
    reflector = { getAllAndOverride: jest.fn().mockReturnValue(false) };
    prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(activeUser), update: jest.fn().mockResolvedValue({}) },
      driver: { findUnique: jest.fn().mockResolvedValue(null) },
      companyMember: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    tokens = { verifyAccessToken: jest.fn().mockResolvedValue({ sub: 'user-1', role: 'DRIVER', sid: 'session-1' }) };
    sessions = { isSessionActive: jest.fn().mockResolvedValue(true) };
    guard = new JwtAuthGuard(reflector as unknown as Reflector, prisma as any, tokens as any, sessions as any);
  });

  it('allows @Public() routes without any token', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    const { context } = makeContext({});
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(tokens.verifyAccessToken).not.toHaveBeenCalled();
  });

  it('rejects a request with no Authorization header', async () => {
    const { context } = makeContext({});
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects a malformed Authorization header', async () => {
    const { context } = makeContext({ Authorization: 'Token abc' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects an invalid/expired access token', async () => {
    tokens.verifyAccessToken.mockRejectedValue(new UnauthorizedException('Invalid or expired access token'));
    const { context } = makeContext({ Authorization: 'Bearer bad-token' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects when the user no longer exists', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    const { context } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects a blocked user', async () => {
    prisma.user.findUnique.mockResolvedValue({ ...activeUser, isBlocked: true });
    const { context } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects an inactive user', async () => {
    prisma.user.findUnique.mockResolvedValue({ ...activeUser, isActive: false });
    const { context } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('rejects when the session has been revoked or expired', async () => {
    sessions.isSessionActive.mockResolvedValue(false);
    const { context } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('populates authContext (including sessionId) on the happy path', async () => {
    const { context, request } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.authContext).toEqual({
      user: activeUser,
      driver: null,
      companyMember: null,
      sessionId: 'session-1',
    });
  });

  it('X-User-Id header has zero effect — a request without a valid Bearer token is rejected regardless', async () => {
    const { context } = makeContext({ 'X-User-Id': 'some-other-user-id' });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  // 024 п.6: /reference-data публичный, но «мои» PENDING-города видны
  // только автору — для этого guard должен опционально распознать токен
  // и на публичном роуте тоже, не отклоняя запрос при его отсутствии/невалидности.
  it('on a @Public() route, a valid token still populates authContext', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    const { context, request } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.authContext).toEqual({
      user: activeUser,
      driver: null,
      companyMember: null,
      sessionId: 'session-1',
    });
  });

  it('on a @Public() route, an invalid/expired token is silently ignored (no throw, no authContext)', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    tokens.verifyAccessToken.mockRejectedValue(new UnauthorizedException('Invalid or expired access token'));
    const { context, request } = makeContext({ Authorization: 'Bearer bad-token' });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.authContext).toBeUndefined();
  });

  it('on a @Public() route, a token for a now-blocked user is silently ignored', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    prisma.user.findUnique.mockResolvedValue({ ...activeUser, isBlocked: true });
    const { context, request } = makeContext({ Authorization: 'Bearer good-token' });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.authContext).toBeUndefined();
  });
});

describe('058 п.7: «был в сети» — lastSeenAt не чаще раза в 5 минут', () => {
  const now = Date.parse('2026-10-10T20:15:00Z');
  it('ещё не было или прошло 5 минут — писать; меньше — нет', () => {
    expect(lastSeenDue(null, now)).toBe(true);
    expect(lastSeenDue(new Date(now - 5 * 60 * 1000), now)).toBe(true);
    expect(lastSeenDue(new Date(now - 4 * 60 * 1000), now)).toBe(false);
  });
});

