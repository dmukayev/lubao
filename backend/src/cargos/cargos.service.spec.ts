import { cargoFitsBody, DriverBody } from '../body-types/profile-fit';
import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { CargosService } from './cargos.service';

function baseCargo(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'cargo1',
    companyId: 'c1',
    publishedByUserId: null,
    publishedBy: null,
    pointId: 'p1',
    point: { cityId: 'almaty', lat: 43.2389, lng: 76.8897, city: { id: 'almaty', regionId: null, lat: 43.2389, lng: 76.8897 } },
    allowPartial: false,
    destinationCountryId: 'kz',
    destinationCityId: null,
    bodyTypeId: 'bt1',
    weightKg: null,
    volumeM3: null,
    photoUrls: [],
    price: 100,
    currency: 'USD',
    readyDate: new Date(),
    description: null,
    status: 'PUBLISHED',
    publishedAt: new Date(),
    expiresAt: new Date(),
    archivedAt: null,
    closeOutcome: null,
    closedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    company: { name: 'Acme', isVerified: true, ratingAvg: 4.5, ratingCount: 3, country: { code: 'KZ' } },
    ...overrides,
  };
}

describe('CargosService — logist contact resolution (задача 017, decisions.md «Компания: проверка, роли, контакты»)', () => {
  it('uses the publishing logist\'s own contacts (CompanyMember.fullName/contactPhone/wechatId) when set, задача 012', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: { id: 'logist1', name: 'Li Wei (User.name)', phone: '+86000' } })) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ fullName: 'Ли Вэй', contactPhone: '+86123', wechatId: 'liwei88' }) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.byId('cargo1');

    expect(prisma.companyMember.findFirst).toHaveBeenCalledWith({ where: { userId: 'logist1' } });
    expect(result.contactUserId).toBe('logist1');
    expect(result.contactName).toBe('Ли Вэй');
    // 043 п.11: номера в карточке нет, только признак.
    expect(result).not.toHaveProperty('contactPhone');
    expect(result.hasContactPhone).toBe(true);
    expect(result.contactWechatId).toBe('liwei88');
  });

  it('falls back to User.name/phone when the publishing logist has not filled in «Мой профиль» yet', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: { id: 'logist1', name: 'Ли Вэй', phone: '+86123' } })) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue({ fullName: null, contactPhone: null, wechatId: null }) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.byId('cargo1');

    expect(result.contactName).toBe('Ли Вэй');
    expect(result.hasContactPhone).toBe(true);
    expect(result.contactWechatId).toBeNull();
  });

  it('falls back to the oldest OWNER when the cargo predates publishedByUserId', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: null })) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: {
        findFirst: jest.fn().mockResolvedValue({ fullName: 'Owner Contact', contactPhone: '+77001112233', wechatId: null, user: { id: 'owner1', name: 'Owner', phone: '+77001112233' } }),
      },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.byId('cargo1');

    expect(prisma.companyMember.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: { companyId: 'c1', role: 'OWNER' }, orderBy: { createdAt: 'asc' } }),
    );
    expect(result.contactUserId).toBe('owner1');
    expect(result.contactName).toBe('Owner Contact');
  });

  it('flags isWhatsappBlocked for a China-based company', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ company: { name: 'Acme CN', isVerified: true, ratingAvg: 5, ratingCount: 1, country: { code: 'CN' } } })) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.byId('cargo1');
    expect(result.isWhatsappBlocked).toBe(true);
  });
});

describe('CargosService.closeCargo — закрытие только с исходом (задача 017, п.6)', () => {
  it('refuses to close a cargo that is already closed', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ status: 'CANCELLED' })) } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_OUTSIDE' } as any)).rejects.toThrow(BadRequestException);
  });

  it('FOUND_IN_APP without driverId throws', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()) } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP' } as any)).rejects.toThrow(BadRequestException);
  });

  it('FOUND_IN_APP invites the driver (creating the deal) and marks the cargo CANCELLED with the outcome', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() },
      response: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const responses = { createDealDirect: jest.fn(), closeForCargo: jest.fn() };
    const service = new CargosService(prisma, responses as any, {} as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP', driverId: 'd1' } as any);

    expect(responses.createDealDirect).toHaveBeenCalledWith('cargo1', 'd1', 'c1');
    expect(prisma.cargo.update).toHaveBeenCalledWith({
      where: { id: 'cargo1' },
      data: { status: 'CANCELLED', closeOutcome: 'FOUND_IN_APP', closedAt: expect.any(Date) },
    });
  });

  it('FOUND_IN_APP does not re-invite a driver whose response is already SELECTED (deal already exists)', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() },
      response: { findUnique: jest.fn().mockResolvedValue({ status: 'SELECTED' }) },
    };
    const responses = { createDealDirect: jest.fn(), closeForCargo: jest.fn() };
    const service = new CargosService(prisma, responses as any, {} as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_IN_APP', driverId: 'd1' } as any);

    expect(responses.createDealDirect).not.toHaveBeenCalled();
    expect(prisma.cargo.update).toHaveBeenCalled();
  });

  it('FOUND_OUTSIDE and CARGO_CANCELLED just close the cargo, no invite', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()), update: jest.fn() } };
    const responses = { createDealDirect: jest.fn(), closeForCargo: jest.fn() };
    const service = new CargosService(prisma, responses as any, {} as any);

    await service.closeCargo('c1', 'u1', 'OWNER', 'cargo1', { outcome: 'FOUND_OUTSIDE' } as any);

    expect(responses.createDealDirect).not.toHaveBeenCalled();
    expect(prisma.cargo.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ closeOutcome: 'FOUND_OUTSIDE' }) }));
    // 056 п.1: ждущие отклики закрываются «груз снят».
    expect(responses.closeForCargo).toHaveBeenCalledWith('cargo1');
  });
});

describe('CargosService.closeCandidates — union of responses/contacts/chats (задача 017, п.6)', () => {
  it('deduplicates a driver who appears via multiple sources', async () => {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo()) },
      response: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd1', driver: { fullName: 'Ерлан' } }]) },
      contactEvent: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd1', driver: { fullName: 'Ерлан' } }]) },
      chat: { findMany: jest.fn().mockResolvedValue([{ driverId: 'd2', driver: { fullName: 'Нурлан' } }]) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.closeCandidates('c1', 'cargo1');

    expect(result).toEqual([{ driverId: 'd1', driverName: 'Ерлан' }, { driverId: 'd2', driverName: 'Нурлан' }]);
  });
});

describe('CargosService.feed — hides blocked companies\' cargo (задача 026, п.5)', () => {
  it('filters by company.isBlocked: false, without touching cargo status', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { count: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    await service.feed();

    expect(prisma.cargo.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { status: 'PUBLISHED', company: { isBlocked: false } } }),
    );
  });
});

describe('CargosService — отсев грузов по размеру машины (задача 033, п.8/13)', () => {
  // 049 п.10: отсев — единая функция профиля (cargoFitsBody), объёмный кузов.
  const body = { profile: 'VOLUME' as const, capacityTons: 20, volumeM3: 90, palletsEuro: 33, specs: null };
  const fits = (cargo: { weightKg: number | null; volumeM3: number | null; palletCount: number | null }, b: DriverBody) =>
    cargoFitsBody({ profiles: [], specs: null, ...cargo }, b);

  it('отсекает по весу: 25 т груза против 20 т машины', () => {
    expect(fits({ weightKg: 25000, volumeM3: null, palletCount: null }, body)).toBe(false);
  });

  it('отсекает по объёму: 100 м³ против «Стандарта» 90 м³', () => {
    expect(fits({ weightKg: null, volumeM3: 100, palletCount: null }, body)).toBe(false);
  });

  it('пропускает 100 м³ для «Меги» 100 м³ (граница включительно)', () => {
    expect(fits({ weightKg: null, volumeM3: 100, palletCount: null }, { ...body, volumeM3: 100 })).toBe(true);
  });

  it('отсекает по паллетам: 38 против 33', () => {
    expect(fits({ weightKg: null, volumeM3: null, palletCount: 38 }, body)).toBe(false);
  });

  it('машина без размера НЕ отсекается по объёму/паллетам — только по весу', () => {
    const noSize = { profile: 'VOLUME' as const, capacityTons: 20, volumeM3: null, palletsEuro: null, specs: null };
    expect(fits({ weightKg: null, volumeM3: 150, palletCount: 50 }, noSize)).toBe(true);
    expect(fits({ weightKg: 25000, volumeM3: 150, palletCount: 50 }, noSize)).toBe(false);
  });

  it('груз без параметров всегда проходит', () => {
    expect(fits({ weightKg: null, volumeM3: null, palletCount: null }, body)).toBe(true);
  });

  it('feed() без driverId (аноним/не водитель) не фильтрует вовсе', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([]) },
      deal: { count: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);
    await service.feed();
    // нет ни arrival.findFirst, ни vehicle.findFirst — мок не падает,
    // значит driverCargoBody не вызывался.
    expect(prisma.cargo.findMany).toHaveBeenCalled();
  });

  it('feed(driverId) берёт кузов из активного анонса и скрывает слишком большой груз', async () => {
    const bigCargo = baseCargo({ id: 'big', volumeM3: 100 });
    const smallCargo = baseCargo({ id: 'small', volumeM3: 80 });
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([bigCargo, smallCargo]) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: { findUnique: jest.fn().mockResolvedValue(null) },
      response: { findMany: jest.fn().mockResolvedValue([]), groupBy: jest.fn().mockResolvedValue([]) },
      bodyType: { findMany: jest.fn().mockResolvedValue([]) },
      arrival: {
        findFirst: jest.fn().mockResolvedValue({
          trailer: { capacityTons: 20, volumeM3: 90, palletsEuro: 33, kind: 'TRAILER' },
          tractor: null,
        }),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    const result = await service.feed('d1');

    expect(result.items.map((c: any) => c.id)).toEqual(['small']);
  });
});

describe('CargosService.create — непроверенная компания не публикует грузы (задача 012, п.4)', () => {
  it('throws COMPANY_NOT_VERIFIED when the company is not verified, without touching the database', async () => {
    const prisma: any = { point: { findUnique: jest.fn() }, cargo: { create: jest.fn() } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.create('c1', 'u1', false, { readyDate: '2026-01-01' } as any)).rejects.toThrow(ForbiddenException);
    expect(prisma.point.findUnique).not.toHaveBeenCalled();
    expect(prisma.cargo.create).not.toHaveBeenCalled();
  });

  it('a verified company publishes normally', async () => {
    const prisma: any = {
      point: { findUnique: jest.fn().mockResolvedValue({ id: 'p1', isActive: true }) },
      cargo: { create: jest.fn().mockResolvedValue({ id: 'cargo1' }), findUnique: jest.fn().mockResolvedValue(baseCargo()) },
      cargoCategory: { findUnique: jest.fn().mockResolvedValue({ isActive: true }) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      bodyType: { findUnique: jest.fn().mockResolvedValue({ fields: [] }), findMany: jest.fn().mockResolvedValue([]) },
      appSetting: { findUnique: jest.fn().mockResolvedValue({ value: 'true' }) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);

    await service.create('c1', 'u1', true, { pointId: 'p1', readyDate: '2026-01-01', destinationCountryId: 'kz', bodyTypeId: 'bt1', price: 100, currency: 'USD', allowPartial: true, categoryId: 'cat1' } as any);

    expect(prisma.cargo.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ pointId: 'p1', allowPartial: true }) }),
    );

    // 049 п.1: флаг выключен — «Можно догрузом» игнорируется.
    prisma.appSetting.findUnique.mockResolvedValue(null);
    const fresh = new CargosService(prisma, {} as any, {} as any);
    await fresh.create('c1', 'u1', true, { pointId: 'p1', readyDate: '2026-01-01', destinationCountryId: 'kz', bodyTypeId: 'bt1', price: 100, currency: 'USD', allowPartial: true, categoryId: 'cat1' } as any);
    expect(prisma.cargo.create.mock.calls[1][0].data.allowPartial).toBe(false);
  });

  it('047 п.1: без категории груз не публикуется', async () => {
    const prisma: any = {
      point: { findUnique: jest.fn().mockResolvedValue({ id: 'p1', isActive: true }) },
      cargo: { create: jest.fn() },
      cargoCategory: { findUnique: jest.fn().mockResolvedValue(null) },
      bodyType: { findUnique: jest.fn().mockResolvedValue({ fields: [] }), findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);
    await expect(service.create('c1', 'u1', true, { pointId: 'p1', readyDate: '2026-01-01', destinationCountryId: 'kz', bodyTypeId: 'bt1', price: 100, currency: 'USD' } as any)).rejects.toThrow('CATEGORY_REQUIRED');
    expect(prisma.cargo.create).not.toHaveBeenCalled();
  });

  it('040, п.7: груз без города погрузки опубликовать нельзя', async () => {
    const prisma: any = { point: { findUnique: jest.fn().mockResolvedValue(null) }, cargo: { create: jest.fn() } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.create('c1', 'u1', true, { pointId: 'missing', readyDate: '2026-01-01' } as any)).rejects.toThrow('POINT_REQUIRED');
    expect(prisma.cargo.create).not.toHaveBeenCalled();
  });

  it('040, п.7: выключенный город тоже не принимается', async () => {
    const prisma: any = { point: { findUnique: jest.fn().mockResolvedValue({ id: 'p1', isActive: false }) }, cargo: { create: jest.fn() } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.create('c1', 'u1', true, { pointId: 'p1', readyDate: '2026-01-01' } as any)).rejects.toThrow('POINT_REQUIRED');
  });
});

describe('CargosService.assertCanEdit — логист редактирует только свой груз, владелец — любой (задача 012, п.6)', () => {
  it('the OWNER can edit a cargo published by a colleague', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'owner-1', 'OWNER')).resolves.toBeDefined();
  });

  it('a LOGIST cannot edit a colleague\'s cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'logist-2', 'LOGIST')).rejects.toThrow(ForbiddenException);
  });

  it('a LOGIST can edit their own cargo', async () => {
    const prisma: any = { cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedByUserId: 'logist-1' })) } };
    const service = new CargosService(prisma, {} as any, {} as any);

    await expect(service.assertCanEdit('cargo1', 'c1', 'logist-1', 'LOGIST')).resolves.toBeDefined();
  });
});


describe('CargosService — лента на сервере: город → область/≤200 км → остальные (задача 040, п.5)', () => {
  const city = (id: string, regionId: string | null, lat: number, lng: number) => ({ id, regionId, lat, lng });
  const point = (c: ReturnType<typeof city>) => ({ cityId: c.id, lat: c.lat, lng: c.lng, city: c });
  const almaty = city('almaty', null, 43.2389, 76.8897);
  const konaev = city('konaev', 'almaty-region', 43.8667, 77.0667); // ~70 км от Алматы
  const talgar = city('talgar', 'almaty-region', 43.3, 77.24);
  const taraz = city('taraz', 'zhambyl', 42.9, 71.3667); // ~400 км
  const taldy = city('taldy', 'zhetysu', 45.0156, 78.3739); // ~270 км
  const astana = city('astana', null, 51.1694, 71.4491);

  describe('pickupRank', () => {
    const origin = { cityId: 'almaty', regionId: null, lat: 43.2389, lng: 76.8897 };

    it('тот же город → 0', () => {
      expect(CargosService.pickupRank(point(almaty), origin)).toBe(0);
    });

    it('≤200 км по координатам → 1 (Конаев рядом с Алматы, у Алматы нет области)', () => {
      expect(CargosService.pickupRank(point(konaev), origin)).toBe(1);
    });

    it('дальше 200 км и другая область → 2 (Тараз, Талдыкорган, Астана)', () => {
      expect(CargosService.pickupRank(point(taraz), origin)).toBe(2);
      expect(CargosService.pickupRank(point(taldy), origin)).toBe(2);
      expect(CargosService.pickupRank(point(astana), origin)).toBe(2);
    });

    it('та же область → 1, даже если дальше 200 км и без координат', () => {
      const o = { cityId: 'taldy', regionId: 'zhetysu', lat: null, lng: null };
      const far = { cityId: 'sarkand', lat: null, lng: null, city: city('sarkand', 'zhetysu', 0, 0) };
      expect(CargosService.pickupRank(far, o)).toBe(1);
    });

    it('нет координат и областей — честно «остальные», а не угадывание', () => {
      const o = { cityId: 'a', regionId: null, lat: null, lng: null };
      expect(CargosService.pickupRank({ cityId: 'b', lat: null, lng: null, city: city('b', null, 0, 0) } as any, o)).toBe(2);
    });
  });

  function setupFeed(opts: { arrivals?: unknown[]; home?: unknown; directions?: string[]; cargos: unknown[]; partialLoads?: boolean }) {
    const prisma: any = {
      appSetting: { findUnique: jest.fn().mockResolvedValue(opts.partialLoads === false ? null : { value: 'true' }) },
      cargo: { findMany: jest.fn().mockResolvedValue(opts.cargos) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      arrival: { findMany: jest.fn().mockResolvedValue(opts.arrivals ?? []), findFirst: jest.fn().mockResolvedValue(null) },
      response: { findMany: jest.fn().mockResolvedValue([]), groupBy: jest.fn().mockResolvedValue([]) },
      bodyType: { findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: {
        findUnique: jest.fn().mockResolvedValue({ homeCity: opts.home ?? null, directions: (opts.directions ?? []).map((countryId) => ({ countryId })), anyCountry: false }),
      },
    };
    return new CargosService(prisma, {} as any, {} as any);
  }
  const cargoAt = (id: string, c: ReturnType<typeof city>, over: Record<string, unknown> = {}) =>
    baseCargo({ id, pointId: `p-${c.id}`, point: point(c), ...over });

  it('водитель объявил «свободен в Алматы» → груз из Алматы первым, затем Конаев (≤200 км), затем остальные', async () => {
    const service = setupFeed({
      arrivals: [{ status: 'PLANNED', point: { cityId: 'almaty', lat: 43.2389, lng: 76.8897, city: almaty } }],
      cargos: [cargoAt('from-astana', astana), cargoAt('from-konaev', konaev), cargoAt('from-almaty', almaty), cargoAt('from-taraz', taraz)],
    });

    const { items, originCityId, originSource } = await service.feed('d1');

    expect(items.map((i: any) => i.id)).toEqual(['from-almaty', 'from-konaev', 'from-astana', 'from-taraz']);
    expect(items.map((i: any) => i.pickupRank)).toEqual([0, 1, 2, 2]);
    expect(originCityId).toBe('almaty');
    expect(originSource).toBe('arrival');
  });

  it('анонс «на месте» важнее запланированного при выборе города ленты', async () => {
    const service = setupFeed({
      arrivals: [
        { status: 'PLANNED', point: { cityId: 'astana', lat: 51.1694, lng: 71.4491, city: astana } },
        { status: 'ON_SITE', point: { cityId: 'almaty', lat: 43.2389, lng: 76.8897, city: almaty } },
      ],
      cargos: [cargoAt('astana-cargo', astana), cargoAt('almaty-cargo', almaty)],
    });

    const { items, originCityId } = await service.feed('d1');

    expect(originCityId).toBe('almaty');
    expect(items[0].id).toBe('almaty-cargo');
  });

  it('без анонса фолбэк — домашний город водителя', async () => {
    const service = setupFeed({
      home: { id: 'talgar', regionId: 'almaty-region', lat: 43.3, lng: 77.24, countryId: 'kz' },
      cargos: [cargoAt('far', astana), cargoAt('near', konaev), cargoAt('here', talgar)],
    });

    const { items, originSource } = await service.feed('d1');

    expect(originSource).toBe('home');
    expect(items.map((i: any) => i.id)).toEqual(['here', 'near', 'far']);
  });

  it('049 п.8: «домой» — та же область, что и домашний город, а не вся страна', async () => {
    const service = setupFeed({
      home: { id: 'talgar', regionId: 'almaty-region', lat: 43.3, lng: 77.24, countryId: 'kz' },
      directions: [],
      cargos: [
        cargoAt('to-taraz', almaty, { destinationCountryId: 'kz', destinationCity: { regionId: 'zhambyl' } }),
        cargoAt('to-konaev', almaty, { destinationCountryId: 'kz', destinationCity: { regionId: 'almaty-region' } }),
      ],
    });
    const { items } = await service.feed('d1');
    expect(items.map((i: any) => [i.id, i.feedSection])).toEqual([['to-konaev', 'home'], ['to-taraz', 'other']]);
  });

  it('внутри одного ранга: «домой» → выбранные страны → остальные, затем по дате готовности', async () => {
    const service = setupFeed({
      home: { id: 'almaty', regionId: null, lat: 43.2389, lng: 76.8897, countryId: 'kz' },
      directions: ['uz'],
      cargos: [
        cargoAt('other-country', almaty, { destinationCountryId: 'ru' }),
        cargoAt('selected-late', almaty, { destinationCountryId: 'uz', readyDate: new Date('2026-10-20') }),
        cargoAt('selected-early', almaty, { destinationCountryId: 'uz', readyDate: new Date('2026-10-10') }),
        cargoAt('home-country', almaty, { destinationCountryId: 'kz' }),
      ],
    });

    const { items } = await service.feed('d1');

    expect(items.map((i: any) => i.id)).toEqual(['home-country', 'selected-early', 'selected-late', 'other-country']);
    expect(items.map((i: any) => i.feedSection)).toEqual(['home', 'selected', 'selected', 'other']);
  });

  it('пагинация: страница и total, порядок сохраняется между страницами', async () => {
    const service = setupFeed({
      home: { id: 'almaty', regionId: null, lat: 43.2389, lng: 76.8897, countryId: 'kz' },
      cargos: [cargoAt('c-astana', astana), cargoAt('c-almaty-1', almaty), cargoAt('c-konaev', konaev), cargoAt('c-almaty-2', almaty)],
    });

    const first = await service.feed('d1', { limit: 3, offset: 0 });
    const second = await service.feed('d1', { limit: 3, offset: 3 });

    expect(first.total).toBe(4);
    expect(first.items).toHaveLength(3);
    expect(second.items).toHaveLength(1);
    expect([...first.items, ...second.items].map((i: any) => i.id)).toEqual(['c-almaty-1', 'c-almaty-2', 'c-konaev', 'c-astana']);
  });

  it('лимит ограничен сверху (50 — 043 п.11), отрицательный offset — 0', async () => {
    const service = setupFeed({ cargos: [] });
    const page = await service.feed('d1', { limit: 5000, offset: -5 });
    expect(page.limit).toBe(50);
    expect(page.offset).toBe(0);
  });

  it('отдаёт признак догруза allowPartial', async () => {
    const service = setupFeed({ cargos: [cargoAt('partial', almaty, { allowPartial: true })] });
    const { items } = await service.feed('d1');
    expect(items[0].allowPartial).toBe(true);
  });

  it('049 п.1: догруз выключен — бейджа нет, даже у груза с пометкой', async () => {
    const service = setupFeed({ cargos: [cargoAt('partial', almaty, { allowPartial: true })], partialLoads: false });
    const { items } = await service.feed('d1');
    expect(items[0].allowPartial).toBe(false);
  });
});

describe('CargosService.partialHint — «Помещается к текущему» (задача 040, п.6)', () => {
  function setup(activeDeals: unknown[], lastDeal: unknown, trailer = { capacityTons: 20, volumeM3: null, palletsEuro: null }) {
    const prisma: any = {
      cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ weightKg: 10000 })) },
      deal: {
        findFirst: jest.fn().mockResolvedValue(lastDeal),
        findMany: jest.fn().mockResolvedValue(activeDeals),
      },
      vehicle: { findUnique: jest.fn().mockResolvedValue({ id: 'trailer1', bodyType: { profile: 'VOLUME' }, ...trailer }) },
      appSetting: { findUnique: jest.fn().mockResolvedValue({ value: 'true' }) },
    };
    return { service: new CargosService(prisma, {} as any, {} as any), prisma };
  }
  const active = (weightKg: number | null) => ({
    id: 'deal-a',
    cargo: { weightKg, volumeM3: null, palletCount: null, readyDate: new Date(), destinationCountryId: 'kz', destinationCityId: null },
  });

  it('без активной сделки подсказки нет', async () => {
    const { service } = setup([], null);
    expect(await service.partialHint('d1', 'cargo1')).toEqual({ hint: null });
  });

  it('8 т уже везёт + 10 т, машина на 20 т → помещается', async () => {
    const { service } = setup([active(8000)], { tractorId: 't1', trailerId: 'trailer1' });
    expect(await service.partialHint('d1', 'cargo1')).toEqual({
      hint: { fits: true, reason: null, committedWeightKg: 8000, cargoWeightKg: 10000, capacityKg: 20000 },
    });
  });

  it('15 т уже везёт + 10 т на 20 т → не помещается (FULL), числа для текста подсказки', async () => {
    const { service } = setup([active(15000)], { tractorId: 't1', trailerId: 'trailer1' });
    const { hint } = await service.partialHint('d1', 'cargo1');
    expect(hint).toMatchObject({ fits: false, reason: 'FULL', committedWeightKg: 15000, capacityKg: 20000 });
  });

  it('049 п.1: догруз выключен — подсказки нет', async () => {
    const { service, prisma } = setup([active(8000)], { tractorId: 't1', trailerId: 'trailer1' });
    prisma.appSetting.findUnique.mockResolvedValue(null);
    expect(await service.partialHint('d1', 'cargo1')).toEqual({ hint: null });
  });

  it('несуществующий груз — 404', async () => {
    const { service, prisma } = setup([], null);
    prisma.cargo.findUnique.mockResolvedValue(null);
    await expect(service.partialHint('d1', 'nope')).rejects.toThrow('Cargo not found');
  });
});

// 043 п.11: номер — только по нажатию, через правила и лимит.
describe('CargosService.revealContact', () => {
  const policy = () => ({
    assertDriverMayContactCargo: jest.fn().mockResolvedValue(undefined),
    consume: jest.fn().mockResolvedValue(undefined),
    record: jest.fn().mockResolvedValue(undefined),
  });
  const prismaWith = (member: unknown) => ({
    cargo: { findUnique: jest.fn().mockResolvedValue(baseCargo({ publishedBy: { id: 'logist1', name: 'Ли', phone: '+86000' } })) },
    companyMember: { findFirst: jest.fn().mockResolvedValue(member) },
  });
  const ctx: any = { user: { id: 'u-driver' }, driver: { id: 'd1', isVerified: false }, companyMember: null };

  it('отдаёт номер логиста, проверив правила, лимит и записав contact_event', async () => {
    const p = policy();
    const service = new CargosService(prismaWith({ fullName: 'Ли Вэй', contactPhone: '+86123', wechatId: null }) as any, {} as any, p as any);
    await expect(service.revealContact(ctx, 'cargo1', 'CALL')).resolves.toEqual({ phone: '+86123' });
    expect(p.assertDriverMayContactCargo).toHaveBeenCalledWith(ctx.driver, 'cargo1');
    expect(p.consume).toHaveBeenCalledWith('u-driver', 'cargo:cargo1');
    expect(p.record).toHaveBeenCalledWith(expect.objectContaining({ driverId: 'd1', cargoId: 'cargo1', type: 'CALL' }));
  });

  it('правила не пустили — номер не выдаётся и лимит не тратится', async () => {
    const p = policy();
    p.assertDriverMayContactCargo.mockRejectedValue(Object.assign(new Error('RESPOND_FIRST'), { status: 403 }));
    const service = new CargosService(prismaWith({ contactPhone: '+86123' }) as any, {} as any, p as any);
    await expect(service.revealContact(ctx, 'cargo1', 'CALL')).rejects.toThrow('RESPOND_FIRST');
    expect(p.consume).not.toHaveBeenCalled();
    expect(p.record).not.toHaveBeenCalled();
  });

  it('логист номер груза так не получает', async () => {
    const service = new CargosService({} as any, {} as any, policy() as any);
    await expect(service.revealContact({ user: { id: 'u' }, driver: null } as any, 'cargo1', 'CALL')).rejects.toThrow('Only drivers');
  });
});

// 045 п.2: в ленте — состояние груза для этого водителя и число других откликов.
describe('CargosService.feed — моё состояние и конкуренты', () => {
  it('мой отклик и сколько других откликнулись — по грузам страницы', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([baseCargo({ id: 'c1' }), baseCargo({ id: 'c2' })]) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: { findUnique: jest.fn().mockResolvedValue(null) },
      arrival: { findFirst: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      response: {
        findMany: jest.fn().mockResolvedValue([{ cargoId: 'c1', status: 'INVITED' }]),
        groupBy: jest.fn().mockResolvedValue([{ cargoId: 'c2', _count: { _all: 3 } }]),
      },
    };
    const service = new CargosService(prisma, {} as any, {} as any);
    const { items } = await service.feed('d1');
    const byId = Object.fromEntries(items.map((i: any) => [i.id, i]));
    expect(byId.c1).toMatchObject({ myResponseStatus: 'INVITED', responsesCount: 0 });
    expect(byId.c2).toMatchObject({ myResponseStatus: null, responsesCount: 3 });
    expect(prisma.response.groupBy.mock.calls[0][0].where).toMatchObject({ driverId: { not: 'd1' }, status: { in: ['PENDING', 'SELECTED'] } });
  });
});

// 045 п.7: страна с уточнёнными областями — «в выбранное» только по своим областям.
describe('CargosService.feed — области направлений', () => {
  it('груз в выбранную область — раньше груза в другую область той же страны', async () => {
    const mk = (id: string, regionId: string, day: string) =>
      baseCargo({ id, destinationCountryId: 'kz', destinationCity: { regionId }, readyDate: new Date(day), point: { cityId: 'p', lat: null, lng: null, city: { id: 'p', regionId: 'x', lat: null, lng: null } } });
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([mk('other-region', 'r-astana', '2030-01-01'), mk('my-region', 'r-almaty', '2030-01-05')]) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      arrival: { findFirst: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]) },
      vehicle: { findFirst: jest.fn().mockResolvedValue(null) },
      driver: {
        findUnique: jest.fn().mockResolvedValue({
          homeCity: { id: 'h', countryId: 'cn', regionId: 'y', lat: null, lng: null },
          directions: [{ countryId: 'kz', regionIds: ['r-almaty'] }],
          anyCountry: false,
          preferredCapacityTons: null,
        }),
      },
      response: { findMany: jest.fn().mockResolvedValue([]), groupBy: jest.fn().mockResolvedValue([]) },
      bodyType: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);
    const { items } = await service.feed('d1');
    expect(items.map((i: any) => [i.id, i.feedSection])).toEqual([
      ['my-region', 'selected'],
      ['other-region', 'other'],
    ]);
  });
});

// 044 п.3: в списке грузов логиста — водитель сделки и её статус.
describe('CargosService.mine — сделка по грузу', () => {
  it('у груза со сделкой — водитель и статус, отменённые сделки не считаются', async () => {
    const prisma: any = {
      cargo: { findMany: jest.fn().mockResolvedValue([baseCargo({ id: 'c1' }), baseCargo({ id: 'c2' })]) },
      deal: {
        count: jest.fn().mockResolvedValue(0),
        findMany: jest.fn().mockResolvedValue([{ id: 'deal1', cargoId: 'c1', status: 'CONFIRMED_BY_DRIVER', driver: { fullName: 'Ерлан' } }]),
      },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
    };
    const service = new CargosService(prisma, {} as any, {} as any);
    const list: any[] = await service.mine('company1');
    expect(list.find((c) => c.id === 'c1').activeDeal).toEqual({ id: 'deal1', status: 'CONFIRMED_BY_DRIVER', driverName: 'Ерлан' });
    expect(list.find((c) => c.id === 'c2').activeDeal).toBeNull();
    expect(prisma.deal.findMany.mock.calls[0][0].where).toMatchObject({ status: { not: 'CANCELLED' } });
  });
});

// 048 п.2, п.4: груз — specs по полям профиля основного кузова, другие подходящие кузова.
describe('CargosService.create — профиль кузова', () => {
  const TANK_FIELDS = require('../../prisma/body-type-profiles').BODY_TYPE_PROFILES.TANK.fields;
  function setup() {
    const prisma: any = {
      point: { findUnique: jest.fn().mockResolvedValue({ id: 'p1', isActive: true }) },
      cargo: { create: jest.fn().mockResolvedValue({ id: 'cargo1' }), findUnique: jest.fn().mockResolvedValue(baseCargo()) },
      cargoCategory: { findUnique: jest.fn().mockResolvedValue({ isActive: true }) },
      deal: { count: jest.fn().mockResolvedValue(0), findMany: jest.fn().mockResolvedValue([]) },
      companyMember: { findFirst: jest.fn().mockResolvedValue(null) },
      bodyType: { findUnique: jest.fn().mockResolvedValue({ fields: TANK_FIELDS }), findMany: jest.fn().mockResolvedValue([{ id: 'bt-other' }]) },
    };
    return { prisma, service: new CargosService(prisma, {} as any, {} as any) };
  }
  const base = { pointId: 'p1', readyDate: '2030-01-01', destinationCountryId: 'kz', bodyTypeId: 'bt-tank', price: 100, currency: 'USD', categoryId: 'cat1' } as any;

  it('цистерна: продукт и литры сохраняются, другие кузова — только существующие и не основной', async () => {
    const { prisma, service } = setup();
    await service.create('c1', 'u1', true, { ...base, specs: { cargoProduct: 'FOOD', cargoLiters: 20000, palletsEuro: 5 }, extraBodyTypeIds: ['bt-tank', 'bt-other', 'bt-other'] });
    expect(prisma.cargo.create.mock.calls[0][0].data).toMatchObject({ specs: { cargoProduct: 'FOOD', cargoLiters: 20000 }, extraBodyTypeIds: ['bt-other'] });
    expect(prisma.bodyType.findMany.mock.calls[0][0].where.id.in).toEqual(['bt-other']);
  });

  it('цистерна без литров — 400 INVALID_SPECS', async () => {
    const { service } = setup();
    await expect(service.create('c1', 'u1', true, { ...base, specs: { cargoProduct: 'FOOD' } })).rejects.toMatchObject({ response: { code: 'INVALID_SPECS' } });
  });
});


/// 056 п.2: «Грузы» логиста — три вкладки, страницами, числа на вкладках.
describe('CargosService.companyTab (056 п.2)', () => {
  function make() {
    const prisma: any = {
      cargo: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(7),
        groupBy: jest.fn().mockResolvedValue([
          { status: 'PUBLISHED', _count: { _all: 5 } },
          { status: 'IN_DEAL', _count: { _all: 2 } },
          { status: 'ARCHIVED', _count: { _all: 3 } },
          { status: 'CANCELLED', _count: { _all: 1 } },
          { status: 'EXPIRED', _count: { _all: 1 } },
        ]),
      },
      deal: { findMany: jest.fn().mockResolvedValue([]) },
    };
    return { prisma, service: new CargosService(prisma, {} as any, {} as any) };
  }

  it('Активные — только опубликованные; числа: «Активные 5 · В работе 2 · Архив 5»', async () => {
    const { prisma, service } = make();
    const r = await service.companyTab('c1', { tab: 'active' });
    expect(prisma.cargo.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { companyId: 'c1', status: { in: ['PUBLISHED'] } }, take: 20, skip: 0 }));
    expect(r.counts).toEqual({ active: 5, work: 2, archive: 5 });
    expect(r.total).toBe(7);
  });

  it('В работе — груз в сделке; лимит страницы не больше 50', async () => {
    const { prisma, service } = make();
    await service.companyTab('c1', { tab: 'work', limit: 500, offset: 40 });
    expect(prisma.cargo.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { companyId: 'c1', status: { in: ['IN_DEAL'] } }, take: 50, skip: 40 }));
  });

  it('Архив — доставлено/снят/истёк, поиск по городу и периоду погрузки, свежие сверху', async () => {
    const { prisma, service } = make();
    await service.companyTab('c1', { tab: 'archive', cityId: 'city1', from: '2026-10-01', to: '2026-10-09' });
    const arg = prisma.cargo.findMany.mock.calls[0][0];
    expect(arg.where.status).toEqual({ in: ['ARCHIVED', 'EXPIRED', 'CANCELLED'] });
    expect(arg.where.OR).toEqual([{ destinationCityId: 'city1' }, { point: { cityId: 'city1' } }]);
    expect(arg.where.readyDate).toEqual({ gte: new Date('2026-10-01T00:00:00.000Z'), lte: new Date('2026-10-09T00:00:00.000Z') });
    expect(arg.orderBy).toEqual([{ updatedAt: 'desc' }]);
  });
});
