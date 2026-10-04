import { JwtService } from '@nestjs/jwt';
import { TokenService } from './token.service';

describe('TokenService', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    process.env = { ...OLD_ENV, JWT_ACCESS_SECRET: 'test-secret' };
  });

  afterEach(() => {
    process.env = OLD_ENV;
  });

  it('throws at construction if JWT_ACCESS_SECRET is not configured', () => {
    delete process.env.JWT_ACCESS_SECRET;
    expect(() => new TokenService(new JwtService())).toThrow('JWT_ACCESS_SECRET is not configured');
  });

  it('signs and verifies an access token round-trip', async () => {
    const service = new TokenService(new JwtService());
    const token = await service.signAccessToken({ sub: 'user-1', role: 'DRIVER', sid: 'session-1' });
    const payload = await service.verifyAccessToken(token);
    expect(payload.sub).toBe('user-1');
    expect(payload.role).toBe('DRIVER');
    expect(payload.sid).toBe('session-1');
  });

  it('rejects a tampered/invalid token', async () => {
    const service = new TokenService(new JwtService());
    await expect(service.verifyAccessToken('not-a-real-token')).rejects.toThrow('Invalid or expired access token');
  });

  it('hashToken is deterministic for the same input', () => {
    const service = new TokenService(new JwtService());
    const token = service.generateRefreshToken();
    expect(service.hashToken(token)).toBe(service.hashToken(token));
  });

  it('generateRefreshToken produces sufficiently long, unique output', () => {
    const service = new TokenService(new JwtService());
    const a = service.generateRefreshToken();
    const b = service.generateRefreshToken();
    expect(a).not.toBe(b);
    expect(a.length).toBeGreaterThanOrEqual(48);
  });

  it('returns the exact role-based refresh TTLs', () => {
    const service = new TokenService(new JwtService());
    expect(service.refreshTtlMs('DRIVER')).toBe(90 * 24 * 60 * 60 * 1000);
    expect(service.refreshTtlMs('COMPANY')).toBe(30 * 24 * 60 * 60 * 1000);
    expect(service.refreshTtlMs('ADMIN')).toBe(12 * 60 * 60 * 1000);
  });
});
