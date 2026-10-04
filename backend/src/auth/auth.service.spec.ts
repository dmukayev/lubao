import * as bcrypt from 'bcryptjs';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
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

describe('AuthService — email code login/registration (задачи 006, 022)', () => {
  let prisma: any;
  let email: { requestCode: jest.Mock; verifyCode: jest.Mock };
  let sessions: { createSession: jest.Mock };
  let companies: { toCompanyDto: jest.Mock; toMemberDto: jest.Mock };
  let service: AuthService;

  beforeEach(() => {
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn() },
      companyMember: { findUnique: jest.fn() },
    };
    email = {
      requestCode: jest.fn().mockResolvedValue(undefined),
      verifyCode: jest.fn().mockResolvedValue(true),
    };
    companies = {
      toCompanyDto: jest.fn((c) => ({ id: c.id, name: c.name })),
      toMemberDto: jest.fn((m) => ({ id: m.id, role: m.role })),
    };
    sessions = { createSession: jest.fn().mockResolvedValue({ accessToken: 'at', refreshToken: 'rt' }) };
    service = new AuthService(prisma, {} as any, {} as any, companies as any, {} as any, email as any, sessions as any);
  });

  it('requestEmailCode rejects an email already used by a non-COMPANY role', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'DRIVER' });
    await expect(service.requestEmailCode('driver@example.com', '1.1.1.1')).rejects.toThrow();
    expect(email.requestCode).not.toHaveBeenCalled();
  });

  it('requestEmailCode delegates to EmailService for a new or COMPANY email', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    await service.requestEmailCode('new@example.com', '1.1.1.1');
    expect(email.requestCode).toHaveBeenCalledWith('new@example.com', '1.1.1.1');
  });

  it('verifyEmailCode rejects a wrong/expired code without touching the database', async () => {
    email.verifyCode.mockResolvedValue(false);
    await expect(service.verifyEmailCode('new@example.com', '000000')).rejects.toThrow(BadRequestException);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('verifyEmailCode creates a bare COMPANY user and returns company: null for a new email', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'new@example.com' });
    prisma.companyMember.findUnique.mockResolvedValue(null);

    const result = await service.verifyEmailCode('new@example.com', '123456');
    expect(prisma.user.create).toHaveBeenCalledWith({ data: { role: 'COMPANY', email: 'new@example.com' } });
    expect(result.company).toBeNull();
    expect(result.companyMember).toBeNull();
    expect(result).toEqual(expect.objectContaining({ accessToken: 'at', refreshToken: 'rt' }));
  });

  it('verifyEmailCode logs an existing company owner straight in with their company', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'COMPANY', email: 'owner@yidao-logistics.cn' });
    prisma.companyMember.findUnique.mockResolvedValue({
      id: 'm1',
      role: 'OWNER',
      company: { id: 'c1', name: 'Yidao' },
    });

    const result = await service.verifyEmailCode('owner@yidao-logistics.cn', '123456');
    expect(prisma.user.create).not.toHaveBeenCalled();
    expect(result.company).toEqual({ id: 'c1', name: 'Yidao' });
    expect(result.companyMember).toEqual({ id: 'm1', role: 'OWNER' });
  });

  it('verifyEmailCode rejects an email already used by a non-COMPANY role', async () => {
    prisma.user.findUnique.mockResolvedValue({ id: 'u1', role: 'DRIVER', email: 'driver@example.com' });
    await expect(service.verifyEmailCode('driver@example.com', '123456')).rejects.toThrow();
  });
});
