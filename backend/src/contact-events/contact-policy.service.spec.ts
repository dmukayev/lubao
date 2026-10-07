import { ForbiddenException, HttpException } from '@nestjs/common';
import { ContactPolicyService } from './contact-policy.service';

// 043 п.11: правила выдачи номера и суточный лимит разных номеров.
function setup({ response = null as unknown, deal = null as unknown } = {}) {
  const sets = new Map<string, Set<string>>();
  const client = {
    sadd: jest.fn(async (k: string, v: string) => {
      const set = sets.get(k) ?? new Set<string>();
      sets.set(k, set);
      const had = set.has(v);
      set.add(v);
      return had ? 0 : 1;
    }),
    srem: jest.fn(async (k: string, v: string) => (sets.get(k)?.delete(v) ? 1 : 0)),
    scard: jest.fn(async (k: string) => sets.get(k)?.size ?? 0),
    expire: jest.fn(),
  };
  const prisma: any = {
    response: { findFirst: jest.fn().mockResolvedValue(response) },
    deal: { findFirst: jest.fn().mockResolvedValue(deal) },
    auditLog: { create: jest.fn() },
    contactEvent: { create: jest.fn() },
  };
  return { prisma, service: new ContactPolicyService(prisma, { client } as any) };
}

describe('ContactPolicyService', () => {
  it('непроверенный водитель без отклика — RESPOND_FIRST; с откликом или сделкой — можно; проверенный — сразу', async () => {
    await expect(setup().service.assertDriverMayContactCargo({ id: 'd1', isVerified: false }, 'c1')).rejects.toMatchObject({ response: { code: 'RESPOND_FIRST' } });
    await expect(setup({ response: { id: 'r1' } }).service.assertDriverMayContactCargo({ id: 'd1', isVerified: false }, 'c1')).resolves.toBeUndefined();
    await expect(setup({ deal: { id: 'deal1' } }).service.assertDriverMayContactCargo({ id: 'd1', isVerified: false }, 'c1')).resolves.toBeUndefined();
    const verified = setup();
    await expect(verified.service.assertDriverMayContactCargo({ id: 'd1', isVerified: true }, 'c1')).resolves.toBeUndefined();
    expect(verified.prisma.response.findFirst).not.toHaveBeenCalled();
  });

  it('отклик учитывается только живой (PENDING/SELECTED)', async () => {
    const { prisma, service } = setup({ response: { id: 'r1' } });
    await service.assertDriverMayContactCargo({ id: 'd1', isVerified: false }, 'c1');
    expect(prisma.response.findFirst.mock.calls[0][0].where.status).toEqual({ in: ['PENDING', 'SELECTED'] });
  });

  it('логист непроверенной компании — COMPANY_NOT_VERIFIED', () => {
    const { service } = setup();
    expect(() => service.assertCompanyMayContactDriver({ isVerified: false })).toThrow(ForbiddenException);
    expect(() => service.assertCompanyMayContactDriver({ isVerified: true })).not.toThrow();
  });

  it('31-й разный номер за сутки — 429 и запись в журнал; повтор того же номера лимит не тратит', async () => {
    const { prisma, service } = setup();
    for (let i = 0; i < 30; i++) await service.consume('u1', `cargo:${i}`);
    await service.consume('u1', 'cargo:0');
    await expect(service.consume('u1', 'cargo:31')).rejects.toBeInstanceOf(HttpException);
    await expect(service.consume('u1', 'cargo:32')).rejects.toMatchObject({ response: { code: 'CONTACT_LIMIT' } });
    expect(prisma.auditLog.create).toHaveBeenCalledTimes(2);
    expect(prisma.auditLog.create.mock.calls[0][0].data).toMatchObject({ action: 'CONTACT_LIMIT_EXCEEDED', entityId: 'u1' });
    // Уже открытые сегодня номера доступны и после превышения.
    await expect(service.consume('u1', 'cargo:5')).resolves.toBeUndefined();
  });
});
