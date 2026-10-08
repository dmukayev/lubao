import { DealsService } from './deals.service';

const FAKE_CHAT_SYSTEM = { post: jest.fn(), postToChat: jest.fn() };
const FAKE_REALTIME = { emitDealUpdated: jest.fn(), emitDealUpdatedToUser: jest.fn() };

/// Пересчёт рейтинга при отмене (046 п.4): отзывы, отменённые сделки, вес из app_settings.
const RATING_MOCKS = () => ({
  review: { aggregate: jest.fn().mockResolvedValue({ _sum: { rating: 0 }, _count: { rating: 0 } }) },
  appSetting: { findUnique: jest.fn().mockResolvedValue(null) },
  driver: { findUnique: jest.fn().mockResolvedValue({ userId: 'user-d1', fullName: 'Ерлан' }), update: jest.fn() },
  company: { findUnique: jest.fn().mockResolvedValue({ name: 'Acme' }), update: jest.fn() },
});

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
      cargo: {
        updateMany: jest.fn(),
        findUnique: jest.fn().mockResolvedValue({ companyId: 'c1', publishedByUserId: 'logist-1', point: { name: { ru: 'Хоргос' } }, destinationCity: { name: { ru: 'Алматы' } }, destinationCountry: null }),
      },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      ...RATING_MOCKS(),
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

    // 042 п.8: водитель нажал сам — ему push нет; логисту — текст от его лица с городами.
    expect(notifications.notify).toHaveBeenCalledTimes(1);
    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['logist-1'], companyId: 'c1' },
      'DEAL_FOR_LOGIST',
      expect.objectContaining({ dealId: 'deal1', status: 'CONFIRMED_BY_DRIVER', driverName: 'Ерлан', destination: { ru: 'Алматы' } }),
    );
  });

  it('falls back to the oldest OWNER as the push target when the cargo has no publisher', async () => {
    const deal = dealFixture({ cargo: { companyId: 'c1', publishedByUserId: null } });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(deal);
    prisma.cargo.findUnique.mockResolvedValue({ companyId: 'c1', publishedByUserId: null, point: null, destinationCity: null, destinationCountry: null });
    prisma.companyMember.findFirst.mockResolvedValue({ userId: 'owner-1' });

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');

    expect(notifications.notify).toHaveBeenCalledWith(
      { userIds: ['owner-1'], companyId: 'c1' },
      'DEAL_FOR_LOGIST',
      expect.anything(),
    );
  });

  it('cancel() notifies with the CANCELLED label', async () => {
    const deal = dealFixture();
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CANCELLED' }));

    await service.cancel('deal1', { driverId: 'd1' }, 'Не получилось забрать груз');

    // Отменил водитель — логист получает причину.
    expect(notifications.notify).toHaveBeenCalledWith(
      expect.objectContaining({ userIds: ['logist-1'] }),
      'DEAL_FOR_LOGIST',
      expect.objectContaining({ status: 'CANCELLED' }),
    );
    expect(notifications.notify).not.toHaveBeenCalledWith(expect.anything(), 'DEAL_FOR_DRIVER', expect.anything());
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

  it('044 п.5: машина «на проверке» больше не мешает подтвердить перевозку', async () => {
    const deal = dealFixture({ tractorId: 'tractor1', trailerId: 'trailer1' });
    prisma.deal.findUnique.mockResolvedValue(deal);
    prisma.deal.update.mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' }));
    prisma.vehicle.findUnique.mockResolvedValue({ isVerified: false, kind: 'TRACTOR' });
    prisma.vehicle.findMany.mockResolvedValue([
      { id: 'tractor1', isVerified: false },
      { id: 'trailer1', isVerified: false },
    ]);

    await service.advanceStatus('deal1', 'd1', 'CONFIRMED_BY_DRIVER');
    expect(prisma.deal.update).toHaveBeenCalled();
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

    expect(prisma.vehicle.findMany).not.toHaveBeenCalled(); // 044 п.5: проверка машины — не гейт
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
        where: expect.objectContaining({ status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'CANCEL_REQUESTED', 'DISPUTED'] } }),
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

describe('DealsService.cancel — причина из списка, этап и вина (046 п.1–2; 038 п.28)', () => {
  function setup(status = 'SELECTED') {
    const prisma: any = {
      deal: { findUnique: jest.fn(), update: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      cargo: { updateMany: jest.fn(), findUnique: jest.fn().mockResolvedValue(null) },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      ...RATING_MOCKS(),
    };
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
    prisma.deal.findUnique.mockResolvedValue(dealFixture({ status }));
    prisma.deal.update.mockImplementation(async ({ data }: any) => dealFixture(data));
    const service = new DealsService(prisma, { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) } as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    return { prisma, service };
  }
  const data = (prisma: any) => prisma.deal.update.mock.calls[0][0].data;

  it('водитель: TOOK_OTHER_CARGO сохраняется, своя вина', async () => {
    const { prisma, service } = setup('CONFIRMED_BY_DRIVER');
    await service.cancel('deal1', { driverId: 'd1' }, undefined, 'TOOK_OTHER_CARGO');
    expect(data(prisma)).toMatchObject({ status: 'CANCELLED', cancelReasonCode: 'TOOK_OTHER_CARGO', cancelStage: 'AFTER_CONFIRM', faultSide: 'SELF', cancelledByRole: 'DRIVER' });
  });

  it('компания: «взял другой груз» недоступен — 400 (не искажает статистику водителя)', async () => {
    const { prisma, service } = setup();
    await expect(service.cancel('deal1', { companyId: 'c1' }, undefined, 'TOOK_OTHER_CARGO')).rejects.toThrow('REASON_NOT_ALLOWED');
    expect(prisma.deal.update).not.toHaveBeenCalled();
  });

  it('«Другое» без текста — 400; старый клиент только с текстом → OTHER', async () => {
    const a = setup();
    await expect(a.service.cancel('deal1', { driverId: 'd1' }, '  ', 'OTHER')).rejects.toThrow('REASON_TEXT_REQUIRED');
    const b = setup();
    await b.service.cancel('deal1', { driverId: 'd1' }, 'Не получилось');
    expect(data(b.prisma)).toMatchObject({ cancelReasonCode: 'OTHER', cancelReason: 'Не получилось', faultSide: 'NEUTRAL', cancelStage: 'BEFORE_CONFIRM' });
  });

  it.each([
    ['SELECTED', 'BEFORE_CONFIRM'],
    ['CONFIRMED_BY_DRIVER', 'AFTER_CONFIRM'],
    ['LOADED', 'AFTER_LOAD'],
  ])('этап по статусу: %s → %s', async (status, stage) => {
    const { prisma, service } = setup(status);
    await service.cancel('deal1', { companyId: 'c1' }, undefined, 'CARGO_NOT_READY');
    expect(data(prisma)).toMatchObject({ cancelStage: stage, faultSide: 'SELF', cancelledByRole: 'COMPANY' });
  });

  it('вина относительно отменившего: «машина сломалась» у компании — вина водителя', async () => {
    const { prisma, service } = setup('LOADED');
    await service.cancel('deal1', { companyId: 'c1' }, undefined, 'VEHICLE_BREAKDOWN');
    expect(data(prisma).faultSide).toBe('OTHER_PARTY');
  });

  it('отмена пересчитывает рейтинг обеих сторон', async () => {
    const { prisma, service } = setup('LOADED');
    await service.cancel('deal1', { driverId: 'd1' }, undefined, 'VEHICLE_BREAKDOWN');
    expect(prisma.driver.update).toHaveBeenCalled();
    expect(prisma.company.update).toHaveBeenCalled();
  });

  it('после «В пути» — не отмена, а запрос: CANCEL_REQUESTED, push второй стороне', async () => {
    const { prisma, service } = setup('IN_TRANSIT');
    await service.cancel('deal1', { driverId: 'd1' }, undefined, 'VEHICLE_BREAKDOWN');
    expect(data(prisma)).toMatchObject({ status: 'CANCEL_REQUESTED', cancelRequestedByRole: 'DRIVER', cancelRequestReasonCode: 'VEHICLE_BREAKDOWN' });
    expect(prisma.cargo.updateMany).not.toHaveBeenCalled();
  });

  it('повторный запрос, пока ждём ответа — 409', async () => {
    const { service } = setup('CANCEL_REQUESTED');
    await expect(service.cancel('deal1', { companyId: 'c1' }, undefined, 'TERMS_CHANGED')).rejects.toThrow('CANCEL_ALREADY_REQUESTED');
  });
});

describe('DealsService — запрос отмены после «В пути»: подтверждение, спор, админ, таймаут (046 п.5)', () => {
  const requested = (overrides: Record<string, unknown> = {}) =>
    dealFixture({
      status: 'CANCEL_REQUESTED',
      cancelRequestedAt: new Date('2030-01-01T10:00:00Z'),
      cancelRequestedByRole: 'DRIVER',
      cancelRequestReasonCode: 'VEHICLE_BREAKDOWN',
      cancelRequestReason: null,
      ...overrides,
    });
  function setup(deal: any) {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(deal), update: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      cargo: { updateMany: jest.fn(), findUnique: jest.fn().mockResolvedValue(null) },
      companyMember: { findFirst: jest.fn() },
      chat: { findFirst: jest.fn().mockResolvedValue(null) },
      auditLog: { create: jest.fn() },
      ...RATING_MOCKS(),
    };
    prisma.$transaction = jest.fn(async (cb: any) => cb(prisma));
    prisma.deal.update.mockImplementation(async ({ data }: any) => ({ ...deal, ...data }));
    const service = new DealsService(prisma, { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) } as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    return { prisma, service };
  }
  const data = (prisma: any) => prisma.deal.update.mock.calls[0][0].data;

  it('вторая сторона подтверждает → CANCELLED, этап «в пути», вина по причине запроса', async () => {
    const { prisma, service } = setup(requested());
    await service.confirmCancel('deal1', { companyId: 'c1' });
    expect(data(prisma)).toMatchObject({ status: 'CANCELLED', cancelStage: 'IN_TRANSIT', faultSide: 'SELF', cancelledByRole: 'DRIVER', cancelReasonCode: 'VEHICLE_BREAKDOWN' });
    expect(prisma.cargo.updateMany).toHaveBeenCalled();
  });

  it('инициатор сам себе не подтверждает и не оспаривает — 403', async () => {
    const { service } = setup(requested());
    await expect(service.confirmCancel('deal1', { driverId: 'd1' })).rejects.toThrow('OWN_CANCEL_REQUEST');
    await expect(service.disputeCancel('deal1', { driverId: 'd1' }, 'нет')).rejects.toThrow('OWN_CANCEL_REQUEST');
  });

  it('«Оспорить» → DISPUTED с позицией второй стороны', async () => {
    const { prisma, service } = setup(requested());
    await service.disputeCancel('deal1', { companyId: 'c1' }, 'Машина на ходу, груз в пути');
    expect(data(prisma)).toMatchObject({ status: 'DISPUTED', disputeReason: 'Машина на ходу, груз в пути' });
    expect(prisma.deal.update.mock.calls[0][0].where).toEqual({ id: 'deal1', status: 'CANCEL_REQUESTED' });
  });

  it('админ: отменить, виновата компания (инициатор — водитель) → OTHER_PARTY, в журнал', async () => {
    const { prisma, service } = setup(requested({ status: 'DISPUTED' }));
    await service.resolveDispute('deal1', 'admin-1', 'CANCEL', 'COMPANY', 'проверили');
    expect(data(prisma)).toMatchObject({ status: 'CANCELLED', faultSide: 'OTHER_PARTY', cancelledByRole: 'DRIVER' });
    expect(prisma.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ action: 'DEAL_DISPUTE_RESOLVED' }) }));
  });

  it('админ: вернуть в «В пути» — запрос и спор стираются', async () => {
    const { prisma, service } = setup(requested({ status: 'DISPUTED', disputeReason: 'x' }));
    await service.resolveDispute('deal1', 'admin-1', 'RESUME', null, 'груз едет');
    expect(data(prisma)).toMatchObject({ status: 'IN_TRANSIT', cancelRequestedAt: null, disputeReason: null });
  });

  it('без ответа 24 ч → отмена проходит, вина на молчавшем', async () => {
    const { prisma, service } = setup(requested());
    prisma.deal.findMany.mockImplementation(async (args: any) => (args.where.status === 'CANCEL_REQUESTED' ? [requested()] : []));
    const res = await service.expireCancelRequests(new Date('2030-01-02T11:00:00Z'));
    expect(res).toEqual({ cancelled: 1 });
    expect(prisma.deal.findMany.mock.calls[0][0].where.cancelRequestedAt).toEqual({ lt: new Date('2030-01-01T11:00:00Z') });
    expect(data(prisma)).toMatchObject({ status: 'CANCELLED', faultSide: 'OTHER_PARTY', cancelStage: 'IN_TRANSIT' });
  });
});

// 044 п.2, 4–5: карточка сделки — машины проверены? когда логист открыл документы?
describe('DealsService.byId — плашки пакета документов', () => {
  it('машина на проверке → vehiclesVerified=false; последнее открытие документов', async () => {
    const opened = new Date('2030-01-01T10:00:00Z');
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(dealFixture({ status: 'CONFIRMED_BY_DRIVER' })), findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findMany: jest.fn().mockResolvedValue([{ isVerified: true }, { isVerified: false }]) },
      auditLog: { findFirst: jest.fn().mockResolvedValue({ createdAt: opened }) },
    };
    const service = new DealsService(prisma, { toDto: jest.fn().mockResolvedValue({ id: 'cargo1' }) } as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    const dto: any = await service.byId('deal1', { driverId: 'd1' });
    expect(dto.vehiclesVerified).toBe(false);
    expect(dto.driverDocsOpenedAt).toEqual(opened);
    expect(prisma.auditLog.findFirst.mock.calls[0][0].where).toMatchObject({ entityType: 'Deal', entityId: 'deal1' });
  });
});

describe('DealsService.complain — жалоба по сделке (046 п.6)', () => {
  function setup(open: unknown = null) {
    const prisma: any = {
      deal: { findUnique: jest.fn().mockResolvedValue(dealFixture({ status: 'CANCELLED' })) },
      complaint: { findFirst: jest.fn().mockResolvedValue(open), create: jest.fn().mockResolvedValue({ id: 'cmp1', status: 'OPEN' }) },
    };
    const service = new DealsService(prisma, {} as any, { notify: jest.fn() } as any, FAKE_CHAT_SYSTEM as any, FAKE_REALTIME as any);
    return { prisma, service };
  }

  it('сторона сделки подаёт жалобу — в очередь DEAL', async () => {
    const { prisma, service } = setup();
    await expect(service.complain('deal1', { companyId: 'c1' }, 'logist-1', 'Отменил с грузом в машине')).resolves.toEqual({ id: 'cmp1', status: 'OPEN' });
    expect(prisma.complaint.create).toHaveBeenCalledWith({ data: expect.objectContaining({ targetType: 'DEAL', targetId: 'deal1', reporterUserId: 'logist-1' }) });
  });

  it('чужая сделка — 403, повторная открытая — 409', async () => {
    await expect(setup().service.complain('deal1', { companyId: 'other' }, 'u', 'x')).rejects.toThrow('Not a party');
    await expect(setup({ id: 'old' }).service.complain('deal1', { driverId: 'd1' }, 'u', 'x')).rejects.toThrow('COMPLAINT_ALREADY_OPEN');
  });
});
