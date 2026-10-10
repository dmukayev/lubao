import { CompanyDriversService, CREATE_DRIVER_DAILY_LIMIT, normalizeInvitePhone } from './company-drivers.service';

const ctx: any = { user: { id: 'logist-1' }, companyMember: { companyId: 'c1' } };

function setup(over: Record<string, any> = {}) {
  const prisma: any = {
    companyDriver: {
      count: jest.fn().mockResolvedValue(0),
      findUnique: jest.fn().mockResolvedValue(null),
      findMany: jest.fn().mockResolvedValue([]),
      create: jest.fn().mockImplementation(async ({ data }: any) => ({ id: 'row1', ...data })),
      update: jest.fn().mockImplementation(async ({ data }: any) => ({ id: 'row1', ...data })),
      upsert: jest.fn().mockImplementation(async ({ create }: any) => ({ id: 'row1', ...create })),
      delete: jest.fn(),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    user: { findUnique: jest.fn().mockResolvedValue(null) },
    deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
    driver: { findUnique: jest.fn().mockResolvedValue({ id: 'd1' }), findMany: jest.fn().mockResolvedValue([]) },
    arrival: { findMany: jest.fn().mockResolvedValue([]) },
    company: { findUnique: jest.fn().mockResolvedValue({ id: 'c1' }) },
    auditLog: { create: jest.fn() },
    ...over,
  };
  const shares: any = { create: jest.fn().mockResolvedValue({ url: 'https://lubao.kz/co/abc' }) };
  return { prisma, shares, service: new CompanyDriversService(prisma, shares) };
}

describe('058 п.6: «Создать водителя»', () => {
  it('номер нормализуется: пробелы и скобки убираются; без «+» — нельзя', () => {
    expect(normalizeInvitePhone('+7 (701) 123-45-67')).toBe('+77011234567');
    expect(normalizeInvitePhone('+998 90 123 45 67')).toBe('+998901234567');
    expect(normalizeInvitePhone('87011234567')).toBeNull();
  });

  it('новый номер — только имя и телефон до входа, ссылка — компании, в журнал без телефона', async () => {
    const { prisma, service } = setup();
    const res = await service.create(ctx, 'Ерлан', '+7 701 123 45 67');
    expect(res).toEqual({ result: 'CREATED', url: 'https://lubao.kz/co/abc' });
    expect(prisma.companyDriver.upsert).toHaveBeenCalledWith(expect.objectContaining({ create: expect.objectContaining({ companyId: 'c1', phone: '+77011234567', name: 'Ерлан', source: 'CREATED', status: 'PENDING' }) }));
    expect(JSON.stringify(prisma.auditLog.create.mock.calls)).not.toContain('+7701');
  });

  it('номер уже в Lubao — не дубль, а приглашение этому водителю', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValue({ id: 'u2', driver: { id: 'd2' } });
    const res = await service.create(ctx, 'Ерлан', '+77011234567');
    expect(res.result).toBe('INVITED_EXISTING');
    expect(prisma.companyDriver.create).toHaveBeenCalledWith({ data: expect.objectContaining({ driverId: 'd2', status: 'PENDING', source: 'CREATED' }) });
    expect(prisma.companyDriver.upsert).not.toHaveBeenCalled();
  });

  it(`лимит ${CREATE_DRIVER_DAILY_LIMIT} в сутки на компанию`, async () => {
    const { prisma, service } = setup();
    prisma.companyDriver.count.mockResolvedValue(CREATE_DRIVER_DAILY_LIMIT);
    await expect(service.create(ctx, 'Ерлан', '+77011234567')).rejects.toMatchObject({ response: { code: 'CREATE_DRIVER_LIMIT' } });
  });
});

describe('058 п.6: согласие водителя и выход из списка', () => {
  it('вход по коду на номер — приглашение привязывается к водителю', async () => {
    const { prisma, service } = setup();
    prisma.companyDriver.findMany.mockResolvedValueOnce([{ id: 'row1', companyId: 'c1', phone: '+77011234567', driverId: null }]);
    await service.attachByPhone('d1', '+77011234567');
    expect(prisma.companyDriver.update).toHaveBeenCalledWith({ where: { id: 'row1' }, data: { driverId: 'd1', phone: null } });
  });

  it('«Принять» — в списке; «Отказаться» — нет', async () => {
    const { prisma, service } = setup();
    prisma.companyDriver.findUnique.mockResolvedValue({ id: 'row1', status: 'PENDING' });
    expect(await service.respond('d1', 'c1', 'ACCEPT', 'u1')).toEqual({ status: 'ACTIVE' });
    expect(await service.respond('d1', 'c1', 'DECLINE', 'u1')).toEqual({ status: 'DECLINED' });
  });

  it('до «Принять» компания видит только имя и «ждёт входа»', async () => {
    const { prisma, service } = setup();
    prisma.companyDriver.findMany.mockResolvedValue([{ id: 'row1', driverId: 'd1', name: 'Ерлан', status: 'PENDING', source: 'CREATED' }]);
    prisma.driver.findMany.mockResolvedValue([{ id: 'd1', fullName: 'Ерлан Сейткали', isVerified: true, ratingAvg: 4.9, ratingCount: 10, user: { lastSeenAt: new Date() } }]);
    const [entry] = await service.list('c1');
    expect(entry).toMatchObject({ driverId: 'd1', name: 'Ерлан', status: 'PENDING', isVerified: false, lastSeenAt: null, ratingCount: 0 });
  });

  it('вышел из списка — компания его не видит, даже если были сделки; ☆ заново нельзя', async () => {
    const { prisma, service } = setup();
    prisma.companyDriver.findMany.mockResolvedValue([{ id: 'row1', driverId: 'd1', status: 'LEFT', source: 'SAVED' }]);
    prisma.deal.findMany.mockResolvedValue([{ driverId: 'd1' }]);
    prisma.driver.findMany.mockImplementation(async ({ where }: any) => (where.id.in.includes('d1') ? [{ id: 'd1' }] : []));
    expect(await service.list('c1')).toEqual([]);
    prisma.companyDriver.findUnique.mockResolvedValue({ id: 'row1', status: 'LEFT', source: 'SAVED' });
    await expect(service.save('c1', 'd1', 'logist-1')).rejects.toMatchObject({ response: { code: 'DRIVER_LEFT_LIST' } });
  });

  it('выйти можно и из списка «по сделкам» — строка LEFT', async () => {
    const { prisma, service } = setup();
    await service.leave('d1', 'c1', 'u1');
    expect(prisma.companyDriver.upsert).toHaveBeenCalledWith(expect.objectContaining({ create: expect.objectContaining({ status: 'LEFT' }), update: expect.objectContaining({ status: 'LEFT' }) }));
  });
});
