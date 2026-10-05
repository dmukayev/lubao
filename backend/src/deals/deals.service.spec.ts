import { DealsService } from './deals.service';

function dealFixture(overrides: Record<string, unknown> = {}) {
  return {
    id: 'deal1',
    driverId: 'd1',
    companyId: 'c1',
    status: 'SELECTED',
    cancelReason: null,
    cancelledByRole: null,
    confirmedAt: null,
    loadedAt: null,
    inTransitAt: null,
    deliveredAt: null,
    createdAt: new Date(),
    driver: { userId: 'user-d1', fullName: 'Ерлан', currentLat: null, currentLng: null, locationUpdatedAt: null },
    company: { name: 'Acme' },
    cargo: { companyId: 'c1', publishedByUserId: 'logist-1' },
    ...overrides,
  };
}

describe('DealsService — DEAL_STATUS notification (задача 011)', () => {
  let prisma: any;
  let cargos: any;
  let notifications: any;
  let service: DealsService;

  beforeEach(() => {
    prisma = {
      deal: { findUnique: jest.fn(), update: jest.fn() },
      companyMember: { findFirst: jest.fn() },
    };
    cargos = { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) };
    notifications = { notify: jest.fn() };
    service = new DealsService(prisma, cargos, notifications);
  });

  it('advanceStatus notifies the driver and the cargo publisher, plus WeCom to the company', async () => {
    const deal = dealFixture();
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['user-d1', 'logist-1'], companyId: 'c1' },
      'DEAL_STATUS',
      expect.objectContaining({ dealId: 'deal1', status: 'CONFIRMED_BY_DRIVER' }),
    );
  });

  it('falls back to the oldest OWNER as the push target when the cargo has no publisher', async () => {
    const deal = dealFixture({ cargo: { companyId: 'c1', publishedByUserId: null } });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(deal);
    prisma.companyMember.findFirst.mockResolvedValue({ userId: 'owner-1' });

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['user-d1', 'owner-1'], companyId: 'c1' },
      'DEAL_STATUS',
      expect.anything(),
    );
  });

  it('cancel() notifies with the CANCELLED label', async () => {
    const deal = dealFixture();
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CANCELLED' }));

    await service.cancel('deal1', { driverId: 'd1' }, 'Не получилось забрать груз');

    expect(notifications.notify).toHaveBeenCalledWith(
      expect.anything(),
      'DEAL_STATUS',
      expect.objectContaining({ status: 'CANCELLED' }),
    );
  });
});

describe('DealsService.advanceStatus — проверка связки машин перед CONFIRMED_BY_DRIVER (задача 031, этап A, п.4)', () => {
  let prisma: any;
  let service: DealsService;

  beforeEach(() => {
    prisma = {
      deal: { findUnique: jest.fn(), update: jest.fn() },
      companyMember: { findFirst: jest.fn() },
      vehicle: { findMany: jest.fn() },
    };
    const cargos = { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) };
    const notifications = { notify: jest.fn() };
    service = new DealsService(prisma, cargos as any, notifications as any);
  });

  it('rejects when the tractor of the deal combo is not verified', async () => {
    const deal = dealFixture({ tractorId: 'tractor1', trailerId: 'trailer1' });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.vehicle.findMany.mockResolvedValue([
      { id: 'tractor1', isVerified: false },
      { id: 'trailer1', isVerified: true },
    ]);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toThrow('VEHICLE_NOT_VERIFIED');
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('allows confirmation once both tractor and trailer of the combo are verified', async () => {
    const deal = dealFixture({ tractorId: 'tractor1', trailerId: 'trailer1' });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));
    prisma.vehicle.findMany.mockResolvedValue([
      { id: 'tractor1', isVerified: true },
      { id: 'trailer1', isVerified: true },
    ]);

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('skips the vehicle check for legacy deals with no combo snapshot', async () => {
    const deal = dealFixture({ tractorId: null, trailerId: null });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.vehicle.findMany).not.toHaveBeenCalled();
    expect(prisma.deal.update).toHaveBeenCalled();
  });
});
