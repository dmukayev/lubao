import * as bcrypt from 'bcryptjs';
import { BadRequestException, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

/// Минимальная in-memory замена ioredis — только методы, которые реально
/// использует AuthService.loginAdmin (get/incr/expire/set/del).
class FakeRedisClient {
  private store = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key) ?? null;
  }
  async set(key: string, value: string): Promise<void> {
    this.store.set(key, String(value));
  }
  async del(key: string): Promise<void> {
    this.store.delete(key);
  }
  async incr(key: string): Promise<number> {
    const next = Number(this.store.get(key) ?? 0) + 1;
    this.store.set(key, String(next));
    return next;
  }
  async expire(_key: string, _seconds: number): Promise<void> {
    // TTL countdown не важен для логики блокировки в этих тестах
  }
}

describe('AuthService — admin lockout + audit log', () => {
  const ADMIN_EMAIL = 'admin@lubao.kz';
  let adminPasswordHash: string;
  let prisma: any;
  let redis: { client: FakeRedisClient };
  let sessions: { createSession: jest.Mock };
  let service: AuthService;

  beforeAll(async () => {
    adminPasswordHash = await bcrypt.hash('correct-password', 4);
  });

  beforeEach(() => {
    const adminUser = { id: 'admin-1', role: 'ADMIN', email: ADMIN_EMAIL, passwordHash: adminPasswordHash };
    prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(adminUser) },
      auditLog: { create: jest.fn().mockResolvedValue(undefined) },
      companyMember: { findUnique: jest.fn() },
    };
    redis = { client: new FakeRedisClient() };
    sessions = { createSession: jest.fn().mockResolvedValue({ accessToken: 'at', refreshToken: 'rt' }) };
    service = new AuthService(prisma, redis as any, {} as any, {} as any, {} as any, {} as any, sessions as any);
  });

  it('locks out after 5 consecutive wrong passwords — a 6th attempt with the CORRECT password is still rejected', async () => {
    for (let i = 0; i < 5; i++) {
      await expect(service.loginAdmin(ADMIN_EMAIL, 'wrong-password', '1.1.1.1')).rejects.toThrow(UnauthorizedException);
    }
    await expect(service.loginAdmin(ADMIN_EMAIL, 'correct-password', '1.1.1.1')).rejects.toThrow(
      'Слишком много неверных попыток, попробуйте через 15 минут',
    );
  });

  it('writes exactly one AuditLog row per attempt, with the right action', async () => {
    await expect(service.loginAdmin(ADMIN_EMAIL, 'wrong-password', '1.1.1.1')).rejects.toThrow();
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'ADMIN_LOGIN_FAILURE' }) }),
    );

    await service.loginAdmin(ADMIN_EMAIL, 'correct-password', '1.1.1.1');
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(2);
    expect(prisma.auditLog.create).toHaveBeenLastCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'ADMIN_LOGIN_SUCCESS' }) }),
    );
  });

  it('logs ADMIN_LOGIN_LOCKED (without touching bcrypt) once locked out', async () => {
    for (let i = 0; i < 5; i++) {
      await expect(service.loginAdmin(ADMIN_EMAIL, 'wrong-password', '1.1.1.1')).rejects.toThrow();
    }
    prisma.auditLog.create.mockClear();
    await expect(service.loginAdmin(ADMIN_EMAIL, 'correct-password', '1.1.1.1')).rejects.toThrow();
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'ADMIN_LOGIN_LOCKED' }) }),
    );
  });

  it('a successful login clears the failure/lockout counters and creates a session', async () => {
    await expect(service.loginAdmin(ADMIN_EMAIL, 'wrong-password', '1.1.1.1')).rejects.toThrow();
    const result = await service.loginAdmin(ADMIN_EMAIL, 'correct-password', '1.1.1.1');
    expect(sessions.createSession).toHaveBeenCalledWith('admin-1', 'ADMIN', undefined, undefined);
    expect(result).toEqual(expect.objectContaining({ accessToken: 'at', refreshToken: 'rt' }));

    // счётчик неудач сброшен успехом — 4 новые неудачи ещё не доходят до лимита (5),
    // поэтому верный пароль сразу после них должен снова сработать, а не быть заблокирован
    for (let i = 0; i < 4; i++) {
      await expect(service.loginAdmin(ADMIN_EMAIL, 'wrong-password', '1.1.1.1')).rejects.toThrow();
    }
    await expect(service.loginAdmin(ADMIN_EMAIL, 'correct-password', '1.1.1.1')).resolves.toEqual(
      expect.objectContaining({ accessToken: 'at', refreshToken: 'rt' }),
    );
  });
});

describe('AuthService.loginCompany (email + password, задача 025)', () => {
  let prisma: any;
  let redis: { client: FakeRedisClient };
  let companies: { toCompanyDto: jest.Mock; toMemberDto: jest.Mock };
  let sessions: { createSession: jest.Mock };
  let service: AuthService;
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await bcrypt.hash('correct-password', 4);
  });

  beforeEach(() => {
    prisma = {
      user: { findUnique: jest.fn() },
      companyMember: { findUnique: jest.fn() },
    };
    redis = { client: new FakeRedisClient() };
    companies = {
      toCompanyDto: jest.fn((c) => ({ id: c.id, name: c.name })),
      toMemberDto: jest.fn((m) => ({ id: m.id, role: m.role })),
    };
    sessions = { createSession: jest.fn().mockResolvedValue({ accessToken: 'at', refreshToken: 'rt' }) };
    service = new AuthService(prisma, redis as any, {} as any, companies as any, {} as any, {} as any, sessions as any);
  });

  it('rejects when the account has no password (role mismatch or never set)', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'new@example.com', passwordHash: null });
    await expect(service.loginCompany('new@example.com', 'anything', '1.1.1.1')).rejects.toThrow(UnauthorizedException);
  });

  it('rejects a wrong password with the same generic message as an unknown email', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com', passwordHash });
    await expect(service.loginCompany('owner@example.com', 'wrong-password', '1.1.1.1')).rejects.toThrow(
      'Invalid email or password',
    );
    prisma.user.findUnique.mockResolvedValue(null);
    await expect(service.loginCompany('nobody@example.com', 'whatever', '1.1.1.1')).rejects.toThrow(
      'Invalid email or password',
    );
  });

  it('logs in with the correct password and returns the company', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com', passwordHash });
    prisma.companyMember.findUnique.mockResolvedValue({ id: 'm1', role: 'OWNER', company: { id: 'c1', name: 'Yidao' } });

    const result = await service.loginCompany('owner@example.com', 'correct-password', '1.1.1.1');
    expect(result.company).toEqual({ id: 'c1', name: 'Yidao' });
    expect(result).toEqual(expect.objectContaining({ accessToken: 'at', refreshToken: 'rt' }));
  });

  it('locks out after 5 wrong passwords — the 6th attempt with the CORRECT password is still rejected', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com', passwordHash });
    for (let i = 0; i < 5; i++) {
      await expect(service.loginCompany('owner@example.com', 'wrong-password', '1.1.1.1')).rejects.toThrow();
    }
    await expect(service.loginCompany('owner@example.com', 'correct-password', '1.1.1.1')).rejects.toThrow(
      'Слишком много неверных попыток, попробуйте через 15 минут',
    );
  });

  it('admin and company lockouts use separate namespaces — failing company login does not lock the admin', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'same@example.com', passwordHash });
    for (let i = 0; i < 5; i++) {
      await expect(service.loginCompany('same@example.com', 'wrong-password', '1.1.1.1')).rejects.toThrow();
    }
    const adminUser = { id: 'admin-1', role: 'ADMIN', email: 'same@example.com', passwordHash };
    prisma.user.findUnique.mockResolvedValue(adminUser);
    prisma.auditLog = { create: jest.fn().mockResolvedValue(undefined) };
    await expect(service.loginAdmin('same@example.com', 'wrong-password', '1.1.1.1')).rejects.toThrow(
      'Invalid email or password',
    );
  });
});

describe('AuthService.registerCompany (задача 025 — email+пароль в один шаг)', () => {
  let prisma: any;
  let email: { requestCode: jest.Mock };
  let companies: { registerOwnedCompany: jest.Mock };
  let sessions: { createSession: jest.Mock };
  let service: AuthService;

  beforeEach(() => {
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn() },
    };
    email = { requestCode: jest.fn().mockResolvedValue(undefined) };
    companies = {
      registerOwnedCompany: jest.fn().mockResolvedValue({
        company: { id: 'c1', name: 'Yidao' },
        companyMember: { id: 'm1', role: 'OWNER' },
      }),
    };
    sessions = { createSession: jest.fn().mockResolvedValue({ accessToken: 'at', refreshToken: 'rt' }) };
    service = new AuthService(prisma, {} as any, {} as any, companies as any, {} as any, email as any, sessions as any);
  });

  it('rejects an already-registered email (any role) without leaking which role', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY' });
    await expect(
      service.registerCompany(
        { email: 'owner@example.com', password: 'password1', ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' },
        '1.1.1.1',
      ),
    ).rejects.toThrow('Email already registered');
    expect(prisma.user.create).not.toHaveBeenCalled();
  });

  it('creates the user, delegates Company creation, and returns tokens', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com' });

    const result = await service.registerCompany(
      { email: 'Owner@Example.com', password: 'password1', ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' },
      '1.1.1.1',
    );

    expect(prisma.user.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ role: 'COMPANY', email: 'owner@example.com' }) }),
    );
    expect(companies.registerOwnedCompany).toHaveBeenCalledWith('u1', expect.objectContaining({ companyName: 'Yidao' }));
    expect(result.company).toEqual({ id: 'c1', name: 'Yidao' });
    expect(result).toEqual(expect.objectContaining({ accessToken: 'at', refreshToken: 'rt' }));
  });

  it('sends a verification code but does not fail registration if sending throws (п. 7 — не блокирует)', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com' });
    email.requestCode.mockRejectedValue(new Error('smtp down'));

    await expect(
      service.registerCompany(
        { email: 'owner@example.com', password: 'password1', ownerName: 'Ли Вэй', companyName: 'Yidao', countryId: 'cn-1' },
        '1.1.1.1',
      ),
    ).resolves.toEqual(expect.objectContaining({ accessToken: 'at' }));
  });
});

describe('AuthService password reset (задача 025, п. 9)', () => {
  let prisma: any;
  let email: { requestCode: jest.Mock; verifyCode: jest.Mock };
  let sessions: { revokeAllForUser: jest.Mock };
  let service: AuthService;

  beforeEach(() => {
    prisma = { user: { findUnique: jest.fn(), update: jest.fn() } };
    email = { requestCode: jest.fn().mockResolvedValue(undefined), verifyCode: jest.fn() };
    sessions = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    service = new AuthService(prisma, {} as any, {} as any, {} as any, {} as any, email as any, sessions as any);
  });

  it('requestPasswordReset does not leak whether the email exists — no code sent for unknown email', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    await service.requestPasswordReset('nobody@example.com', '1.1.1.1');
    expect(email.requestCode).not.toHaveBeenCalled();
  });

  it('requestPasswordReset sends a code for a known COMPANY email', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com', locale: 'zh' });
    await service.requestPasswordReset('owner@example.com', '1.1.1.1');
    // Письмо — на языке пользователя (042, п.2).
    expect(email.requestCode).toHaveBeenCalledWith('owner@example.com', '1.1.1.1', 'zh');
  });

  it('resetPassword rejects a wrong/expired code', async () => {
    email.verifyCode.mockResolvedValue(false);
    await expect(service.resetPassword('owner@example.com', '000000', 'newpassword1')).rejects.toThrow(
      BadRequestException,
    );
  });

  it('resetPassword sets the new password and revokes every session', async () => {
    email.verifyCode.mockResolvedValue(true);
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@example.com' });

    await service.resetPassword('owner@example.com', '123456', 'newpassword1');

    expect(prisma.user.update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'u1' } }));
    expect(sessions.revokeAllForUser).toHaveBeenCalledWith('u1');
  });
});

describe('AuthService email verification (задача 025, п. 7 — не блокирует вход)', () => {
  let prisma: any;
  let email: { verifyCode: jest.Mock };
  let service: AuthService;

  beforeEach(() => {
    prisma = { user: { findUnique: jest.fn(), update: jest.fn() } };
    email = { verifyCode: jest.fn() };
    service = new AuthService(prisma, {} as any, {} as any, {} as any, {} as any, email as any, {} as any);
  });

  it('verifyEmail sets emailVerifiedAt on a correct code', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', email: 'owner@example.com' });
    email.verifyCode.mockResolvedValue(true);

    await service.verifyEmail('u1', '123456');
    expect(prisma.user.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'u1' }, data: expect.objectContaining({ emailVerifiedAt: expect.any(Date) }) }),
    );
  });

  it('verifyEmail rejects a wrong code without updating the user', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', email: 'owner@example.com' });
    email.verifyCode.mockResolvedValue(false);

    await expect(service.verifyEmail('u1', '000000')).rejects.toThrow(BadRequestException);
    expect(prisma.user.update).not.toHaveBeenCalled();
  });
});

describe('AuthService — blocked accounts cannot log in (задача 026, п.5)', () => {
  it('loginCompany: a blocked user with the right password still gets rejected with ACCOUNT_BLOCKED', async () => {
    const passwordHash = await bcrypt.hash('correct-password', 4);
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'a@b.com', passwordHash, isBlocked: true }) },
      companyMember: { findUnique: jest.fn() },
    };
    const redis = { client: new FakeRedisClient() };
    const sessions = { createSession: jest.fn() };
    const service = new AuthService(prisma, redis as any, {} as any, {} as any, {} as any, {} as any, sessions as any);

    await expect(service.loginCompany('a@b.com', 'correct-password', '1.1.1.1')).rejects.toThrow(ForbiddenException);
    expect(sessions.createSession).not.toHaveBeenCalled();
  });

  it('verifyDriverCode: a blocked existing driver still gets rejected with ACCOUNT_BLOCKED even with the right SMS code', async () => {
    const prisma: any = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', role: 'DRIVER', phone: '+77011234567', isBlocked: true }) },
    };
    const sms = { verifyCode: jest.fn().mockResolvedValue(true) };
    const drivers = { findByUserId: jest.fn() };
    const sessions = { createSession: jest.fn() };
    const service = new AuthService(prisma, {} as any, drivers as any, {} as any, sms as any, {} as any, sessions as any);

    await expect(service.verifyDriverCode('+77011234567', '1111', '1.1.1.1')).rejects.toThrow(ForbiddenException);
    expect(sessions.createSession).not.toHaveBeenCalled();
  });
});

describe('AuthService.setLocale (задача 013 — язык хранится на сервере)', () => {
  it('writes the new locale to the user row', async () => {
    const prisma: any = { user: { update: jest.fn().mockResolvedValue({}) } };
    const service = new AuthService(prisma, {} as any, {} as any, {} as any, {} as any, {} as any, {} as any);

    await service.setLocale('u1', 'en');
    expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'u1' }, data: { locale: 'en' } });
  });
});
