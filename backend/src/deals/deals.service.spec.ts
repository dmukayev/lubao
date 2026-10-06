import { DealsService } from './deals.service';

const FAKE_CHAT_SYSTEM = { post: jest.fn(), postToChat: jest.fn() };
const FAKE_REALTIME = { emitDealUpdated: jest.fn(), emitDealUpdatedToUser: jest.fn() };

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
    tractorId: 'tractor1',
    trailerId: 'trailer1',
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
      deal: { findUnique: jest.fn(), update: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      arrival: { updateMany: jest.fn().mockResolvedValue({ count: 0 }), findFirst: jest.fn().mockResolvedValue(null), update: jest.fn() },
      cargo: { updateMany: jest.fn() },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      vehicle: {
        findUnique: jest.fn().mockResolvedValue({ isVerified: true, kind: 'TRACTOR' }),
        findMany: jest.fn().mockResolvedValue([
          { id: 'tractor1', isVerified: true },
          { id: 'trailer1', isVerified: true },
        ]),
      },
      // 038 п.7 — подтверждение идёт в $transaction под advisory-замком;
      // в тестах транзакция «прозрачная»: tx = тот же prisma-мок.
      $queryRaw: jest.fn().mockResolvedValue([]),
    };
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
    cargos = { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) };
    notifications = { notify: jest.fn() };
    service = new DealsService(prisma, cargos, notifications, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
  });

  it('041, п.13: смена статуса сделки уходит в личные комнаты водителя и логиста (трекинг рейса без опроса)', async () => {
    FAKE_REALTIME.emitDealUpdatedToUser.mockClear();
    prisma.deal.findUnique.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'LOADED' }));
    prisma.companyMember.findFirst.mockResolvedValue({ userId: 'logist-1' });

    await service.advanceStatus('deal1', 'd1', 'LOADED');

    const users = FAKE_REALTIME.emitDealUpdatedToUser.mock.calls.map((c) => c[0]).sort();
    expect(users).toEqual(['logist-1', 'user-d1']);
    expect(FAKE_REALTIME.emitDealUpdatedToUser).toHaveBeenCalledWith('user-d1', { dealId: 'deal1', status: expect.any(String) });
  });

  it('040, п.4: подтверждение сделки гасит анонс водителя («на месте» → COMPLETED)', async () => {
    prisma.deal.findUnique.mockResolvedValue(dealFixture());
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));
    prisma.arrival.updateMany.mockResolvedValue({ count: 1 });

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.arrival.updateMany).toHaveBeenCalledWith({ where: { driverId: 'd1', status: 'ON_SITE' }, data: { status: 'COMPLETED' } });
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

  it('041, п.2: отмена сделки возвращает груз IN_DEAL → PUBLISHED (снова в ленте)', async () => {
    prisma.deal.findUnique.mockResolvedValue(dealFixture());
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CANCELLED' }));

    await service.cancel('deal1', { driverId: 'd1' }, 'Не получилось забрать груз');

    expect(prisma.cargo.updateMany).toHaveBeenCalledWith(expect.objectContaining({ data: { status: 'PUBLISHED' } }));
  });
});

describe('DealsService.advanceStatus — проверка связки машин перед CONFIRMED_BY_DRIVER (задача 031/032, п.4/5)', () => {
  let prisma: any;
  let service: DealsService;

  beforeEach(() => {
    prisma = {
      deal: { findUnique: jest.fn(), update: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      arrival: { updateMany: jest.fn().mockResolvedValue({ count: 0 }), findFirst: jest.fn().mockResolvedValue(null), update: jest.fn() },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      vehicle: { findUnique: jest.fn(), findMany: jest.fn() },
      $queryRaw: jest.fn().mockResolvedValue([]),
    };
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
    const cargos = { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) };
    const notifications = { notify: jest.fn() };
    service = new DealsService(prisma, cargos as any, notifications as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
  });

  it('rejects when the tractor of the deal combo is not verified', async () => {
    const deal = dealFixture({ tractorId: 'tractor1', trailerId: 'trailer1' });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.vehicle.findUnique.mockResolvedValue({ isVerified: false, kind: 'TRACTOR' });
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
    prisma.vehicle.findUnique.mockResolvedValue({ isVerified: true, kind: 'TRACTOR' });
    prisma.vehicle.findMany.mockResolvedValue([
      { id: 'tractor1', isVerified: true },
      { id: 'trailer1', isVerified: true },
    ]);

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('задача 032, п.5 — a deal without a combo snapshot (legacy, or announce never set one) is now a 409 VEHICLE_REQUIRED, not a silent skip', async () => {
    const deal = dealFixture({ tractorId: null, trailerId: null });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toThrow('VEHICLE_REQUIRED');
    expect(prisma.vehicle.findMany).not.toHaveBeenCalled();
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('задача 032, п.5 — a RIGID tractor (single truck) does not require a trailer', async () => {
    const deal = dealFixture({ tractorId: 'rigid1', trailerId: null });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));
    prisma.vehicle.findUnique.mockResolvedValue({ isVerified: true, kind: 'RIGID' });
    prisma.vehicle.findMany.mockResolvedValue([{ id: 'rigid1', isVerified: true }]);

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.vehicle.findMany).toHaveBeenCalledWith({ where: { id: { in: ['rigid1'] } }, select: { id: true, isVerified: true } });
    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('задача 032, п.5 — a non-RIGID tractor without a trailer in the combo is 409 VEHICLE_REQUIRED', async () => {
    const deal = dealFixture({ tractorId: 'tractor1', trailerId: null });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.vehicle.findUnique.mockResolvedValue({ isVerified: true, kind: 'TRACTOR' });

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toThrow('VEHICLE_REQUIRED');
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });
});

describe('DealsService — догруз разрешён, «бронь всего подряд» — нет (задача 037)', () => {
  const READY = new Date('2026-10-10T00:00:00Z');

  function cargoFixture(overrides: Record<string, unknown> = {}) {
    return {
      companyId: 'c1',
      publishedByUserId: 'logist-1',
      weightKg: 10000,
      volumeM3: null,
      palletCount: null,
      readyDate: READY,
      destinationCountryId: 'kz',
      destinationCityId: null,
      ...overrides,
    };
  }

  function setup({
    activeDeals = [] as unknown[],
    trailer = { capacityTons: 20, volumeM3: null, palletsEuro: null } as { capacityTons: number | null; volumeM3: number | null; palletsEuro: number | null },
  }) {
    const prisma: any = {
      deal: {
        findUnique: jest.fn(),
        update: jest.fn(),
        findMany: jest.fn().mockResolvedValue(activeDeals),
      },
      arrival: { updateMany: jest.fn().mockResolvedValue({ count: 0 }), findFirst: jest.fn().mockResolvedValue(null), update: jest.fn() },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      vehicle: {
        // Первый findUnique — проверка тягача (kind), второй — кузов связки.
        findUnique: jest.fn().mockImplementation(({ where }: any) =>
          Promise.resolve(where.id === 'tractor1' ? { isVerified: true, kind: 'TRACTOR' } : { id: 'trailer1', isVerified: true, kind: 'TRAILER', ...trailer }),
        ),
        findMany: jest.fn().mockResolvedValue([
          { id: 'tractor1', isVerified: true },
          { id: 'trailer1', isVerified: true },
        ]),
      },
      $queryRaw: jest.fn().mockResolvedValue([]),
    };
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
    const service = new DealsService(prisma, { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) } as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    return { prisma, service };
  }

  it('два частичных 8 т + 10 т на машину 20 т — вторая подтверждается', async () => {
    const { prisma, service } = setup({
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 8000 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 10000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('20 т + 10 т на машину 20 т — вторая падает с 409 VEHICLE_FULL', async () => {
    const { prisma, service } = setup({
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 20000 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 10000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'VEHICLE_FULL', reason: 'FULL', usedWeightKg: 20000, capacityKg: 20000 }),
    });
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('груз без веса занимает машину целиком — догруз рядом не подтвердить', async () => {
    const { prisma, service } = setup({
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: null }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 1000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toThrow();
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('объём НЕ учитывается, когда неизвестен у машины или груза (отсекает только вес)', async () => {
    const { prisma, service } = setup({
      // У машины объёма нет (volumeM3: null) — суммарные 150 м³ не мешают.
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 5000, volumeM3: 80 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 5000, volumeM3: 70 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('объём учитывается, когда известен и у машины, и у всех грузов', async () => {
    const { prisma, service } = setup({
      trailer: { capacityTons: 20, volumeM3: 90, palletsEuro: null },
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 5000, volumeM3: 80 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 5000, volumeM3: 70 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'VEHICLE_FULL' }),
    });
  });

  it('погрузка через 3 дня — это следующий рейс, не догруз: 409 с reason NEXT_TRIP', async () => {
    const { prisma, service } = setup({
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 1000, readyDate: new Date('2026-10-07T00:00:00Z') }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 1000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'VEHICLE_FULL', reason: 'NEXT_TRIP' }),
    });
  });

  it('последовательные рейсы: активных сделок нет (DELIVERED не считаются — фильтр по статусам в запросе) — без ограничений', async () => {
    const { prisma, service } = setup({ activeDeals: [] });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 20000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.deal.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT'] } }),
      }),
    );
    expect(prisma.deal.update).toHaveBeenCalled();
  });

  it('задача 038, п.6 — активные сделки считаются по тягачу: смена прицепа не обходит проверку', async () => {
    const { prisma, service } = setup({
      // Активная сделка на тот же тягач, но ДРУГОЙ прицеп — всё равно
      // учитывается: один тягач не везёт две полные машины.
      activeDeals: [{ id: 'deal-old', trailerId: 'other-trailer', cargo: cargoFixture({ weightKg: 20000 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 10000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'VEHICLE_FULL' }),
    });
    // В where нет trailerId — фильтр только по тягачу.
    const where = prisma.deal.findMany.mock.calls[0][0].where;
    // п.26 (038): тягач ИЛИ сделки без снимка тягача (legacy) — консервативно.
    expect(where.OR).toEqual([{ tractorId: 'tractor1' }, { tractorId: null }]);
    expect('trailerId' in where).toBe(false);
  });

  it('задача 038, п.6 — прицеп без тоннажа: вместимость неизвестна, вторая активная сделка запрещена', async () => {
    const { prisma, service } = setup({
      trailer: { capacityTons: null, volumeM3: null, palletsEuro: null },
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 1000 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 1000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'VEHICLE_FULL', reason: 'FULL' }),
    });
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('задача 038, п.7 — проверка и запись статуса идут в одной транзакции под advisory-замком по водителю', async () => {
    const { prisma, service } = setup({
      activeDeals: [{ id: 'deal-old', cargo: cargoFixture({ weightKg: 8000 }) }],
    });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 10000 }) });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(prisma.$transaction).toHaveBeenCalled();
    // Замок взят ДО перечитывания/проверки вместимости.
    expect(prisma.$queryRaw).toHaveBeenCalled();
    const lockOrder = prisma.$queryRaw.mock.invocationCallOrder[0];
    const findManyOrder = prisma.deal.findMany.mock.invocationCallOrder[0];
    const updateOrder = prisma.deal.update.mock.invocationCallOrder[0];
    expect(lockOrder).toBeLessThan(findManyOrder);
    expect(findManyOrder).toBeLessThan(updateOrder);
  });

  it('задача 038, п.7 — статус перечитывается под замком: сделка уже CONFIRMED → 400, не вторая запись', async () => {
    const { prisma, service } = setup({ activeDeals: [] });
    const deal = dealFixture({ cargo: cargoFixture({ weightKg: 10000 }) });
    // Снаружи транзакции сделка ещё SELECTED, под замком — уже CONFIRMED
    // (параллельное подтверждение успело первым).
    prisma.deal.findUnique
      .mockResolvedValueOnce(deal)
      .mockResolvedValueOnce({ status: 'CONFIRMED_BY_DRIVER' });

    await expect(service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER')).rejects.toThrow('Cannot move deal');
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });
});

describe('DealsService.cancel — код причины только от водителя (задача 038, п.28)', () => {
  function setup() {
    const prisma: any = { deal: { findUnique: jest.fn(), update: jest.fn() }, cargo: { updateMany: jest.fn() }, companyMember: { findFirst: jest.fn() }, chat: { findFirst: jest.fn().mockResolvedValue(null) } };
    prisma.deal.findUnique.mockResolvedValue(dealFixture());
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CANCELLED' }));
    const service = new DealsService(prisma, { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) } as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    return { prisma, service };
  }

  it('водитель: TOOK_OTHER_CARGO сохраняется', async () => {
    const { prisma, service } = setup();
    await service.cancel('deal1', { driverId: 'd1' }, 'Взял другой груз', 'TOOK_OTHER_CARGO');
    expect(prisma.deal.update.mock.calls[0][0].data.cancelReasonCode).toBe('TOOK_OTHER_CARGO');
  });

  it('компания: тот же код игнорируется (не искажает статистику водителя)', async () => {
    const { prisma, service } = setup();
    await service.cancel('deal1', { companyId: 'c1' }, 'Взял другой груз', 'TOOK_OTHER_CARGO');
    expect(prisma.deal.update.mock.calls[0][0].data.cancelReasonCode).toBeNull();
  });
});
