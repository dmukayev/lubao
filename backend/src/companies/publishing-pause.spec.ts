import { pauseAfterComplaints } from './publishing-pause';

/// 066 п.5: две жалобы разных водителей — непроверенная компания на паузе.
describe('pauseAfterComplaints', () => {
  const setup = (company: Record<string, unknown> | null, reporters: string[]) => {
    const db: any = {
      company: { findUnique: jest.fn().mockResolvedValue(company), update: jest.fn() },
      cargo: { findMany: jest.fn().mockResolvedValue([{ id: 'cargo1' }]) },
      deal: { findMany: jest.fn().mockResolvedValue([]) },
      complaint: { findMany: jest.fn().mockResolvedValue(reporters.map((reporterUserId) => ({ reporterUserId }))) },
      auditLog: { create: jest.fn() },
    };
    return db;
  };
  const unverified = { isVerified: false, publishingPausedAt: null, complaintsResetAt: null };

  it('один водитель с двумя жалобами — не пауза; два водителя — пауза и запись в журнал', async () => {
    const one = setup(unverified, ['u1', 'u1']);
    expect(await pauseAfterComplaints(one, 'c1')).toBe(false);
    expect(one.company.update).not.toHaveBeenCalled();

    const two = setup(unverified, ['u1', 'u2']);
    expect(await pauseAfterComplaints(two, 'c1')).toBe(true);
    expect(two.company.update.mock.calls[0][0].data.publishingPausedAt).toBeInstanceOf(Date);
    expect(two.auditLog.create.mock.calls[0][0].data.action).toBe('COMPANY_PUBLISHING_PAUSED');
    const where = two.complaint.findMany.mock.calls[0][0].where;
    expect(where.reporter).toEqual({ role: 'DRIVER' });
    expect(where.status).toEqual({ not: 'REJECTED' });
  });

  it('проверенную не трогаем; после снятия паузы считаются только новые жалобы', async () => {
    const verified = setup({ ...unverified, isVerified: true }, ['u1', 'u2']);
    expect(await pauseAfterComplaints(verified, 'c1')).toBe(false);
    expect(verified.complaint.findMany).not.toHaveBeenCalled();

    const reset = new Date('2026-10-13T10:00:00Z');
    const afterReset = setup({ ...unverified, complaintsResetAt: reset }, ['u3']);
    expect(await pauseAfterComplaints(afterReset, 'c1')).toBe(false);
    expect(afterReset.complaint.findMany.mock.calls[0][0].where.createdAt).toEqual({ gt: reset });
  });
});
