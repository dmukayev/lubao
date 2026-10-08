import { JobsService } from './jobs.service';

const NOW = new Date('2026-10-07T07:00:00.000Z'); // 12:00 по Алматы
const H = 3600 * 1000;

function makeRedis() {
  const keys = new Set<string>();
  return {
    keys,
    client: {
      set: jest.fn(async (key: string, _v: string, _ex: string, _ttl: number, nx: string) => {
        if (nx === 'NX' && keys.has(key)) return null;
        keys.add(key);
        return 'OK';
      }),
    },
  };
}

function setup() {
  const prisma: any = {
    exchangeRate: { findUnique: jest.fn().mockResolvedValue(null), upsert: jest.fn(), count: jest.fn().mockResolvedValue(0) },
    contactEvent: { findMany: jest.fn().mockResolvedValue([]) },
    response: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]), updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    chat: { findFirst: jest.fn().mockResolvedValue({ id: 'chat-1' }) },
    cargo: { findMany: jest.fn().mockResolvedValue([]), updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
    driver: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
    session: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
    companyMember: { findMany: jest.fn().mockResolvedValue([]) },
  };
  const redis = makeRedis();
  const notifications = { notify: jest.fn().mockResolvedValue(undefined) };
  const chatSystem = { post: jest.fn().mockResolvedValue(undefined) };
  const email = { sendTemplate: jest.fn().mockResolvedValue(undefined) };
  const service = new JobsService(prisma, redis as any, notifications as any, chatSystem as any, email as any);
  return { service, prisma, redis, notifications, chatSystem, email };
}

const NBK_XML = '<item><title>USD</title><description>480</description><quant>1</quant></item><item><title>CNY</title><description>67</description><quant>1</quant></item>';

describe('JobsService.refreshExchangeRates', () => {
  it('пишет USD и CNY на сегодняшнюю дату (по Алматы), источник nbrk', async () => {
    const { service, prisma } = setup();
    service.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => NBK_XML });

    const res = await service.refreshExchangeRates(NOW);

    expect(res).toEqual({ updated: 2, skippedManual: 0 });
    expect(service.fetchFn).toHaveBeenCalledWith(expect.stringContaining('fdate=07.10.2026'));
    expect(prisma.exchangeRate.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { currency_effectiveDate: { currency: 'USD', effectiveDate: new Date('2026-10-07T00:00:00.000Z') } },
        create: expect.objectContaining({ currency: 'USD', rateToKzt: 480, source: 'nbrk' }),
      }),
    );
  });

  it('идемпотентно: повторный запуск обновляет те же строки через upsert, а не плодит новые', async () => {
    const { service, prisma } = setup();
    service.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => NBK_XML });
    await service.refreshExchangeRates(NOW);
    await service.refreshExchangeRates(NOW);
    expect(prisma.exchangeRate.upsert).toHaveBeenCalledTimes(4);
    expect(prisma.exchangeRate.upsert.mock.calls[0][0].where).toEqual(prisma.exchangeRate.upsert.mock.calls[2][0].where);
  });

  it('ручная правка админа (source ≠ nbrk) автоматикой не перезаписывается', async () => {
    const { service, prisma } = setup();
    prisma.exchangeRate.findUnique.mockImplementation(async ({ where }: any) =>
      where.currency_effectiveDate.currency === 'USD' ? { source: 'manual' } : null,
    );
    service.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => NBK_XML });

    const res = await service.refreshExchangeRates(NOW);

    expect(res).toEqual({ updated: 1, skippedManual: 1 });
    expect(prisma.exchangeRate.upsert).toHaveBeenCalledTimes(1);
  });

  it('сеть недоступна/ответ мусорный — ошибка в результате, исключения нет, курсы не тронуты', async () => {
    const { service, prisma } = setup();
    service.fetchFn = jest.fn().mockRejectedValue(new Error('ETIMEDOUT'));
    expect((await service.refreshExchangeRates(NOW)).error).toBe('ETIMEDOUT');
    service.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '<html/>' });
    expect((await service.refreshExchangeRates(NOW)).error).toBe('EMPTY_RESPONSE');
    service.fetchFn = jest.fn().mockResolvedValue({ ok: false, status: 503, text: async () => '' });
    expect((await service.refreshExchangeRates(NOW)).error).toBe('HTTP 503');
    expect(prisma.exchangeRate.upsert).not.toHaveBeenCalled();
  });

  it('при старте: курс на сегодня уже есть — сеть не трогаем; нет — берём сразу', async () => {
    const { service, prisma } = setup();
    service.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => NBK_XML });
    prisma.exchangeRate.count.mockResolvedValue(2);
    expect(await service.ensureTodayRates(NOW)).toBe(false);
    expect(service.fetchFn).not.toHaveBeenCalled();
    prisma.exchangeRate.count.mockResolvedValue(0);
    expect(await service.ensureTodayRates(NOW)).toBe(true);
    expect(service.fetchFn).toHaveBeenCalledTimes(1);
  });
});

describe('JobsService.sendAgreedChecks — «Договорились?» через 2 ч', () => {
  const event = (over: Record<string, unknown> = {}) => ({
    driverId: 'd1',
    companyId: 'co1',
    cargoId: 'cargo1',
    createdAt: new Date(NOW.getTime() - 3 * H),
    driver: { id: 'd1', userId: 'u-d1' },
    company: { name: 'Acme' },
    cargo: { status: 'PUBLISHED', publishedBy: { id: 'l1', name: 'Ли Вэй' } },
    ...over,
  });

  it('звонок 3 ч назад → один push водителю с именем логиста и ссылкой на чат', async () => {
    const { service, prisma, notifications } = setup();
    prisma.contactEvent.findMany.mockResolvedValue([event()]);

    const res = await service.sendAgreedChecks(NOW);

    expect(res).toEqual({ sent: 1 });
    expect(notifications.notify).toHaveBeenCalledWith({ userIds: ['u-d1'] }, 'AGREED_CHECK', { counterpartName: 'Ли Вэй', cargoId: 'cargo1', chatId: 'chat-1' });
  });

  it('окно запроса: не раньше 2 ч и не старше 26 ч', async () => {
    const { service, prisma } = setup();
    await service.sendAgreedChecks(NOW);
    const where = prisma.contactEvent.findMany.mock.calls[0][0].where;
    expect(where.createdAt.lte).toEqual(new Date(NOW.getTime() - 2 * H));
    expect(where.createdAt.gte).toEqual(new Date(NOW.getTime() - 26 * H));
  });

  it('идемпотентность: повторный запуск (и второй звонок по тому же грузу) второго push не шлёт', async () => {
    const { service, prisma, notifications } = setup();
    prisma.contactEvent.findMany.mockResolvedValue([event(), event({ createdAt: new Date(NOW.getTime() - 4 * H) })]);

    await service.sendAgreedChecks(NOW);
    await service.sendAgreedChecks(NOW);

    expect(notifications.notify).toHaveBeenCalledTimes(1);
  });

  it('груз уже закрыт или водитель уже выбран — спрашивать не о чем', async () => {
    const { service, prisma, notifications } = setup();
    prisma.contactEvent.findMany.mockResolvedValue([event({ cargo: { status: 'IN_DEAL', publishedBy: null } })]);
    await service.sendAgreedChecks(NOW);
    expect(notifications.notify).not.toHaveBeenCalled();

    prisma.contactEvent.findMany.mockResolvedValue([event({ cargoId: 'cargo2' })]);
    prisma.response.count.mockResolvedValue(1);
    await service.sendAgreedChecks(NOW);
    expect(notifications.notify).not.toHaveBeenCalled();
  });

  it('чата нет — ссылка ведёт на груз (chatId = null), имя — компания, если логист не указан', async () => {
    const { service, prisma, notifications } = setup();
    prisma.chat.findFirst.mockResolvedValue(null);
    prisma.contactEvent.findMany.mockResolvedValue([event({ cargo: { status: 'PUBLISHED', publishedBy: null } })]);
    await service.sendAgreedChecks(NOW);
    expect(notifications.notify).toHaveBeenCalledWith(expect.anything(), 'AGREED_CHECK', { counterpartName: 'Acme', cargoId: 'cargo1', chatId: null });
  });
});

describe('JobsService.sendAgreedDigests — «Договорились?» логисту письмом', () => {
  const calls = (companyId: string, n: number) => Array.from({ length: n }, (_, i) => ({ companyId, driverId: `d${i}`, cargoId: 'cargo1' }));

  it('одно письмо на сотрудника с числом водителей, звонивших по грузам компании', async () => {
    const { service, prisma, email } = setup();
    prisma.contactEvent.findMany.mockResolvedValue([...calls('co1', 3), { companyId: 'co1', driverId: 'd0', cargoId: 'cargo1' }]);
    prisma.companyMember.findMany.mockResolvedValue([{ user: { email: 'a@example.com', locale: 'zh' } }, { user: { email: 'b@example.com', locale: 'ru' } }]);

    const res = await service.sendAgreedDigests(NOW);

    expect(res).toEqual({ companies: 1, emails: 2 });
    expect(email.sendTemplate).toHaveBeenCalledWith('a@example.com', 'AGREED_DIGEST', 'zh', { count: 3, link: 'https://app.lubao.kz/chats' });
    expect(email.sendTemplate).toHaveBeenCalledWith('b@example.com', 'AGREED_DIGEST', 'ru', expect.objectContaining({ count: 3 }));
  });

  it('идемпотентность: второй запуск в те же сутки писем не шлёт', async () => {
    const { service, prisma, email } = setup();
    prisma.contactEvent.findMany.mockResolvedValue(calls('co1', 1));
    prisma.companyMember.findMany.mockResolvedValue([{ user: { email: 'a@example.com', locale: 'ru' } }]);
    await service.sendAgreedDigests(NOW);
    await service.sendAgreedDigests(NOW);
    expect(email.sendTemplate).toHaveBeenCalledTimes(1);
  });

  it('звонки есть только по закрытым грузам — запрос их уже отсёк (cargo.status = PUBLISHED), писем нет', async () => {
    const { service, prisma, email } = setup();
    await service.sendAgreedDigests(NOW);
    expect(prisma.contactEvent.findMany.mock.calls[0][0].where.cargo).toEqual({ status: 'PUBLISHED' });
    expect(email.sendTemplate).not.toHaveBeenCalled();
  });

  it('сбой почты одному получателю не мешает остальным', async () => {
    const { service, prisma, email } = setup();
    prisma.contactEvent.findMany.mockResolvedValue(calls('co1', 1));
    prisma.companyMember.findMany.mockResolvedValue([{ user: { email: 'a@example.com', locale: 'ru' } }, { user: { email: 'b@example.com', locale: 'ru' } }]);
    email.sendTemplate.mockRejectedValueOnce(new Error('smtp down'));
    expect(await service.sendAgreedDigests(NOW)).toEqual({ companies: 1, emails: 1 });
  });
});

describe('JobsService.archiveCargos — через 3 дня после даты готовности', () => {
  it('архивирует PUBLISHED с readyDate ≤ сегодня−3, закрывает висящие отклики', async () => {
    const { service, prisma } = setup();
    prisma.cargo.findMany.mockResolvedValue([{ id: 'c1' }, { id: 'c2' }]);
    prisma.cargo.updateMany.mockResolvedValue({ count: 2 });

    const res = await service.archiveCargos(NOW);

    expect(res).toEqual({ archived: 2 });
    expect(prisma.cargo.findMany).toHaveBeenCalledWith({
      where: { status: 'PUBLISHED', readyDate: { lte: new Date('2026-10-04T00:00:00.000Z') } },
      select: { id: true },
    });
    expect(prisma.cargo.updateMany).toHaveBeenCalledWith({ where: { id: { in: ['c1', 'c2'] }, status: 'PUBLISHED' }, data: { status: 'ARCHIVED', archivedAt: NOW } });
    expect(prisma.response.updateMany).toHaveBeenCalledWith({ where: { cargoId: { in: ['c1', 'c2'] }, status: { in: ['PENDING', 'INVITED'] } }, data: { status: 'CANCELLED', closeReason: 'CARGO_ARCHIVED' } });
  });

  it('нечего архивировать — ничего не пишет', async () => {
    const { service, prisma } = setup();
    expect(await service.archiveCargos(NOW)).toEqual({ archived: 0 });
    expect(prisma.cargo.updateMany).not.toHaveBeenCalled();
  });

  it('груз в сделке (IN_DEAL) не архивируется — фильтр только по PUBLISHED', async () => {
    const { service, prisma } = setup();
    await service.archiveCargos(NOW);
    expect(prisma.cargo.findMany.mock.calls[0][0].where.status).toBe('PUBLISHED');
  });
});

describe('JobsService.expireInvitations — 24 часа на ответ', () => {
  it('приглашение без ответа > 24 ч → CANCELLED + системная строка в чат', async () => {
    const { service, prisma, chatSystem } = setup();
    prisma.response.findMany.mockResolvedValue([
      { id: 'r1', driverId: 'd1', cargoId: 'cargo1', driver: { userId: 'u1', fullName: 'Ерлан' }, cargo: { companyId: 'co1' } },
    ]);

    const res = await service.expireInvitations(NOW);

    expect(res).toEqual({ expired: 1 });
    expect(prisma.response.findMany.mock.calls[0][0].where).toEqual({ status: 'INVITED', updatedAt: { lt: new Date(NOW.getTime() - 24 * H) } });
    expect(prisma.response.updateMany).toHaveBeenCalledWith({ where: { id: 'r1', status: 'INVITED' }, data: { status: 'CANCELLED', closeReason: 'INVITE_EXPIRED' } });
    expect(chatSystem.post).toHaveBeenCalledWith(expect.objectContaining({ code: 'INVITATION_EXPIRED', driverId: 'd1', cargoId: 'cargo1' }));
  });

  it('водитель успел ответить (условный апдейт проиграл) — ничего не пишем в чат', async () => {
    const { service, prisma, chatSystem } = setup();
    prisma.response.findMany.mockResolvedValue([{ id: 'r1', driverId: 'd1', cargoId: 'c', driver: { userId: 'u', fullName: 'x' }, cargo: { companyId: 'co' } }]);
    prisma.response.updateMany.mockResolvedValue({ count: 0 });
    expect(await service.expireInvitations(NOW)).toEqual({ expired: 0 });
    expect(chatSystem.post).not.toHaveBeenCalled();
  });
});

describe('JobsService — чистка', () => {
  it('геопозиции старше 30 дней обнуляются', async () => {
    const { service, prisma } = setup();
    prisma.driver.updateMany.mockResolvedValue({ count: 3 });
    expect(await service.cleanupLocations(NOW)).toEqual({ cleared: 3 });
    expect(prisma.driver.updateMany).toHaveBeenCalledWith({
      where: { locationUpdatedAt: { lt: new Date(NOW.getTime() - 30 * 24 * H) } },
      data: { currentLat: null, currentLng: null, locationUpdatedAt: null },
    });
  });

  it('просроченные (+7 дн.) и давно отозванные (+30 дн.) сессии удаляются', async () => {
    const { service, prisma } = setup();
    prisma.session.deleteMany.mockResolvedValue({ count: 5 });
    expect(await service.cleanupSessions(NOW)).toEqual({ deleted: 5 });
    expect(prisma.session.deleteMany.mock.calls[0][0].where.OR).toHaveLength(2);
  });
});
