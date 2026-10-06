import { createHash } from 'crypto';
import { PrismaClient, Currency } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

if (process.env.NODE_ENV === 'production') {
  console.error('prisma:seed:demo is blocked when NODE_ENV=production');
  process.exit(1);
}

const prisma = new PrismaClient();

const DEMO_PASSWORD = 'DemoLubao2026!';

function demoId(seed: string): string {
  const hash = createHash('sha1').update(`lubao-demo:${seed}`).digest('hex');
  return [hash.slice(0, 8), hash.slice(8, 12), hash.slice(12, 16), hash.slice(16, 20), hash.slice(20, 32)].join('-');
}

function daysFromNow(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

function hoursFromDate(date: Date, hours: number): Date {
  const d = new Date(date);
  d.setHours(d.getHours() + hours);
  return d;
}

async function country(code: string) {
  return prisma.country.findFirstOrThrow({ where: { code } });
}

async function cityByRuName(ru: string) {
  return prisma.city.findFirstOrThrow({ where: { name: { path: ['ru'], equals: ru } } });
}

async function bodyType(code: string) {
  return prisma.bodyType.findFirstOrThrow({ where: { code } });
}

async function permit(code: string) {
  return prisma.permit.findFirstOrThrow({ where: { code } });
}

async function khorgosPoint() {
  return prisma.point.findFirstOrThrow({});
}

async function main() {
  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);

  const [kz, cn, ru, kg, uz, az] = await Promise.all([
    country('KZ'),
    country('CN'),
    country('RU'),
    country('KG'),
    country('UZ'),
    country('AZ'),
  ]);

  const [almaty, shymkent, taraz, karagandy, zharkent, aktau, moscow, novosibirsk, bishkek, tashkent, baku] =
    await Promise.all([
      cityByRuName('Алматы'),
      cityByRuName('Шымкент'),
      cityByRuName('Тараз'),
      cityByRuName('Караганда'),
      cityByRuName('Жаркент'),
      cityByRuName('Актау'),
      cityByRuName('Москва'),
      cityByRuName('Новосибирск'),
      cityByRuName('Бишкек'),
      cityByRuName('Ташкент'),
      cityByRuName('Баку'),
    ]);

  const [urumqi, dushanbe, minsk, tehran] = await Promise.all([
    cityByRuName('Урумчи'),
    cityByRuName('Душанбе'),
    cityByRuName('Минск'),
    cityByRuName('Тегеран'),
  ]);

  const [tent, refrigerator, flatbed, container, tank, lowloader, grain, carcarrier, isotherm, dump] =
    await Promise.all([
      bodyType('TENT'),
      bodyType('REFRIGERATOR'),
      bodyType('FLATBED'),
      bodyType('CONTAINER'),
      bodyType('TANK'),
      bodyType('LOWLOADER'),
      bodyType('GRAIN'),
      bodyType('CARCARRIER'),
      bodyType('ISOTHERM'),
      bodyType('DUMP'),
    ]);

  const [tir, cmr] = await Promise.all([permit('TIR'), permit('CMR')]);
  const khorgos = await khorgosPoint();

  // ---------------------------------------------------------------------
  // Водители
  // ---------------------------------------------------------------------
  const driverDefs = [
    {
      key: 'driver-1',
      phone: '+77011234501',
      fullName: 'Ерлан Тохтаров',
      homeCity: almaty,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [tir, cmr],
      vehicle: { bodyType: tent, plate: '123ABC02', brand: 'Volvo FH', capacityTons: 20, lengthM: 13.6 },
    },
    {
      key: 'driver-2',
      phone: '+77011234502',
      fullName: 'Асхат Ниязов',
      homeCity: shymkent,
      anyCountry: false,
      isVerified: true,
      directions: [ru, kg],
      permits: [cmr],
      vehicle: { bodyType: refrigerator, plate: '456DEF02', brand: 'Scania R', capacityTons: 18, lengthM: 13.6 },
    },
    {
      key: 'driver-3',
      phone: '+77011234503',
      fullName: 'Данияр Сагынов',
      homeCity: taraz,
      anyCountry: false,
      isVerified: false,
      directions: [uz, kg],
      permits: [] as { id: string }[],
      vehicle: { bodyType: flatbed, plate: '789GHI02', brand: 'MAN TGX', capacityTons: 22, lengthM: 13.6 },
    },
    {
      key: 'driver-4',
      phone: '+77011234504',
      fullName: 'Владимир Ким',
      homeCity: karagandy,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [tir],
      vehicle: { bodyType: container, plate: '321JKL02', brand: 'Mercedes Actros', capacityTons: 20, lengthM: 13.6 },
    },
    {
      key: 'driver-5',
      phone: '+77011234505',
      fullName: 'Нурлан Жаркентов',
      homeCity: zharkent,
      anyCountry: false,
      isVerified: true,
      directions: [ru, kz],
      permits: [tir, cmr],
      vehicle: { bodyType: lowloader, plate: '654MNO02', brand: 'DAF XF', capacityTons: 25, lengthM: 13.6 },
    },
    {
      key: 'driver-6',
      phone: '+77011234506',
      fullName: 'Бахтияр Оспанов',
      homeCity: aktau,
      anyCountry: false,
      isVerified: false,
      directions: [az],
      permits: [] as { id: string }[],
      vehicle: { bodyType: tank, plate: '987PQR02', brand: 'Iveco Stralis', capacityTons: 24, lengthM: 12 },
    },
    // Иностранные водители — на Хоргосе встречаются машины со всего региона,
    // не только казахстанские.
    {
      key: 'driver-ru',
      phone: '+79261234567',
      fullName: 'Дмитрий Волков',
      homeCity: novosibirsk,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [tir, cmr],
      vehicle: { bodyType: refrigerator, plate: 'A123BC154', brand: 'KamAZ', capacityTons: 20, lengthM: 13.6 },
    },
    {
      key: 'driver-cn',
      phone: '+8613912345678',
      fullName: '王强 (Ван Цян)',
      homeCity: urumqi,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [tir],
      vehicle: { bodyType: container, plate: '新A12345', brand: 'Sinotruk HOWO', capacityTons: 30, lengthM: 13.6 },
    },
    {
      key: 'driver-uz',
      phone: '+998901234567',
      fullName: 'Шерзод Каримов',
      homeCity: tashkent,
      anyCountry: true,
      isVerified: false,
      directions: [] as { id: string }[],
      permits: [tir],
      vehicle: { bodyType: tent, plate: '01A123AA', brand: 'Isuzu Giga', capacityTons: 18, lengthM: 12 },
    },
    {
      key: 'driver-kg',
      phone: '+996550123456',
      fullName: 'Нурбек Асанов',
      homeCity: bishkek,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [] as { id: string }[],
      vehicle: { bodyType: isotherm, plate: '01KG234A', brand: 'Hyundai HD', capacityTons: 12, lengthM: 9 },
    },
    {
      key: 'driver-tj',
      phone: '+992917654321',
      fullName: 'Фарход Рахимов',
      homeCity: dushanbe,
      anyCountry: true,
      isVerified: false,
      directions: [] as { id: string }[],
      permits: [tir],
      vehicle: { bodyType: dump, plate: '01TJ567B', brand: 'FAW', capacityTons: 25, lengthM: 8 },
    },
    {
      key: 'driver-ir',
      phone: '+989121234567',
      fullName: 'Реза Хосейни',
      homeCity: tehran,
      anyCountry: true,
      isVerified: false,
      directions: [] as { id: string }[],
      permits: [tir, cmr],
      vehicle: { bodyType: grain, plate: '12ایران34', brand: 'Volvo FH', capacityTons: 22, lengthM: 13.6 },
    },
    {
      key: 'driver-by',
      phone: '+375291234567',
      fullName: 'Виктор Ковалёв',
      homeCity: minsk,
      anyCountry: true,
      isVerified: true,
      directions: [] as { id: string }[],
      permits: [tir, cmr],
      vehicle: { bodyType: carcarrier, plate: '1234 AB-7', brand: 'MAZ', capacityTons: 16, lengthM: 13.6 },
    },
  ];

  const drivers: Record<string, { userId: string; driverId: string }> = {};

  for (const def of driverDefs) {
    const user = await prisma.user.upsert({
      where: { phone: def.phone },
      update: { locale: 'ru' },
      create: { role: 'DRIVER', phone: def.phone, locale: 'ru' },
    });

    const driver = await prisma.driver.upsert({
      where: { userId: user.id },
      update: {
        fullName: def.fullName,
        homeCityId: def.homeCity.id,
        anyCountry: def.anyCountry,
        isVerified: def.isVerified,
      },
      create: {
        userId: user.id,
        fullName: def.fullName,
        homeCityId: def.homeCity.id,
        anyCountry: def.anyCountry,
        isVerified: def.isVerified,
      },
    });

    for (const c of def.directions) {
      await prisma.driverDirection.upsert({
        where: { driverId_countryId: { driverId: driver.id, countryId: c.id } },
        update: {},
        create: { driverId: driver.id, countryId: c.id },
      });
    }

    for (const p of def.permits) {
      await prisma.driverPermit.upsert({
        where: { driverId_permitId: { driverId: driver.id, permitId: p.id } },
        update: {},
        create: { driverId: driver.id, permitId: p.id },
      });
    }

    // Задача 031, этап A — гараж: тягач (госномер/марка) и прицеп (кузов/
    // тоннаж/длина) отдельными записями вместо одной Vehicle на всю связку.
    const tractorId = demoId(`vehicle:${def.key}:tractor`);
    const trailerId = demoId(`vehicle:${def.key}:trailer`);
    await prisma.vehicle.upsert({
      where: { id: tractorId },
      update: { plateNumber: def.vehicle.plate, brand: def.vehicle.brand },
      create: { id: tractorId, driverId: driver.id, kind: 'TRACTOR', plateNumber: def.vehicle.plate, brand: def.vehicle.brand },
    });
    await prisma.vehicle.upsert({
      where: { id: trailerId },
      update: { bodyTypeId: def.vehicle.bodyType.id, capacityTons: def.vehicle.capacityTons, lengthM: def.vehicle.lengthM },
      create: {
        id: trailerId,
        driverId: driver.id,
        kind: 'TRAILER',
        bodyTypeId: def.vehicle.bodyType.id,
        capacityTons: def.vehicle.capacityTons,
        lengthM: def.vehicle.lengthM,
      },
    });

    await prisma.notificationSetting.upsert({
      where: { userId_channel: { userId: user.id, channel: 'PUSH' } },
      update: {},
      create: { userId: user.id, channel: 'PUSH', enabled: true },
    });
    await prisma.notificationSetting.upsert({
      where: { userId_channel: { userId: user.id, channel: 'SMS' } },
      update: {},
      create: { userId: user.id, channel: 'SMS', enabled: true },
    });

    drivers[def.key] = { userId: user.id, driverId: driver.id };

    await prisma.arrival.upsert({
      where: { id: demoId(`arrival:${def.key}`) },
      update: { status: 'ON_SITE' },
      create: {
        id: demoId(`arrival:${def.key}`),
        driverId: driver.id,
        pointId: khorgos.id,
        plannedAt: daysFromNow(-1),
        plannedDay: new Date(daysFromNow(-1).toISOString().slice(0, 10) + 'T00:00:00.000Z'),
        arrivedAt: daysFromNow(-1),
        status: 'ON_SITE',
      },
    });
  }

  // ---------------------------------------------------------------------
  // Компании
  // ---------------------------------------------------------------------
  const companyDefs = [
    {
      key: 'company-yidao',
      name: 'Xinjiang Yidao Logistics 新疆一道物流',
      country: cn,
      city: 'Урумчи',
      ownerEmail: 'owner@yidao-logistics.cn',
      logistEmail: 'logist@yidao-logistics.cn',
      isVerified: true,
    },
    {
      key: 'company-silkbridge',
      name: 'Horgos Silk Bridge Trading 霍尔果斯丝路桥贸易',
      country: cn,
      city: 'Хоргос (Хуэрготос), СУАР',
      ownerEmail: 'owner@silkbridge-trade.cn',
      logistEmail: null,
      isVerified: true,
    },
    {
      key: 'company-transeurasia',
      name: 'Beijing Trans-Eurasia Cargo 北京欧亚货运',
      country: cn,
      city: 'Пекин',
      ownerEmail: 'owner@transeurasia-cargo.cn',
      logistEmail: null,
      isVerified: false,
    },
    {
      key: 'company-nurlyzhol',
      name: 'Nurly Zhol Terminal Logistics',
      country: kz,
      city: 'Алматы',
      ownerEmail: 'owner@nurlyzhol-terminal.kz',
      logistEmail: null,
      isVerified: true,
    },
  ];

  const companies: Record<string, { companyId: string; ownerUserId: string }> = {};

  for (const def of companyDefs) {
    const companyId = demoId(`company:${def.key}`);
    const company = await prisma.company.upsert({
      where: { id: companyId },
      update: { name: def.name, countryId: def.country.id, city: def.city, isVerified: def.isVerified },
      create: {
        id: companyId,
        name: def.name,
        countryId: def.country.id,
        city: def.city,
        isVerified: def.isVerified,
      },
    });

    const ownerUser = await prisma.user.upsert({
      where: { email: def.ownerEmail },
      update: { locale: 'zh', passwordHash },
      create: { role: 'COMPANY', email: def.ownerEmail, passwordHash, locale: 'zh' },
    });

    await prisma.companyMember.upsert({
      where: { userId: ownerUser.id },
      update: { companyId: company.id, role: 'OWNER' },
      create: { companyId: company.id, userId: ownerUser.id, role: 'OWNER' },
    });

    await prisma.notificationSetting.upsert({
      where: { userId_channel: { userId: ownerUser.id, channel: 'PUSH' } },
      update: {},
      create: { userId: ownerUser.id, channel: 'PUSH', enabled: true },
    });
    await prisma.notificationSetting.upsert({
      where: { userId_channel: { userId: ownerUser.id, channel: 'EMAIL' } },
      update: {},
      create: { userId: ownerUser.id, channel: 'EMAIL', enabled: true },
    });
    await prisma.notificationSetting.upsert({
      where: { userId_channel: { userId: ownerUser.id, channel: 'WECOM' } },
      update: {},
      create: { userId: ownerUser.id, channel: 'WECOM', enabled: true },
    });

    if (def.logistEmail) {
      const logistUser = await prisma.user.upsert({
        where: { email: def.logistEmail },
        update: { locale: 'zh', passwordHash },
        create: { role: 'COMPANY', email: def.logistEmail, passwordHash, locale: 'zh' },
      });
      await prisma.companyMember.upsert({
        where: { userId: logistUser.id },
        update: { companyId: company.id, role: 'LOGIST' },
        create: { companyId: company.id, userId: logistUser.id, role: 'LOGIST' },
      });
      await prisma.notificationSetting.upsert({
        where: { userId_channel: { userId: logistUser.id, channel: 'WECOM' } },
        update: {},
        create: { userId: logistUser.id, channel: 'WECOM', enabled: true },
      });
    }

    companies[def.key] = { companyId: company.id, ownerUserId: ownerUser.id };
  }

  // ---------------------------------------------------------------------
  // Грузы
  // ---------------------------------------------------------------------
  const now = new Date();

  const cargoDefs = [
    {
      key: 'cargo-1',
      company: companies['company-yidao'],
      destinationCountry: kz,
      destinationCity: almaty,
      bodyType: tent,
      weightKg: 18000,
      volumeM3: 54,
      photoUrls: ['https://placehold.co/800x600?text=Cargo+Photo+1', 'https://placehold.co/800x600?text=Cargo+Photo+2'],
      price: 1500,
      currency: Currency.USD,
      readyDate: daysFromNow(1),
      description: 'Стройматериалы, требуется тент, разгрузка в Алматы.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-2',
      company: companies['company-yidao'],
      destinationCountry: ru,
      destinationCity: novosibirsk,
      bodyType: refrigerator,
      weightKg: 16000,
      volumeM3: 45,
      photoUrls: [] as string[],
      price: 9000,
      currency: Currency.CNY,
      readyDate: daysFromNow(2),
      description: 'Замороженные продукты, рефрижератор, -18°C.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-3',
      company: companies['company-silkbridge'],
      destinationCountry: kg,
      destinationCity: bishkek,
      bodyType: flatbed,
      weightKg: 20000,
      volumeM3: 30,
      photoUrls: ['https://placehold.co/800x600?text=Metal+Coils'],
      price: 800,
      currency: Currency.USD,
      readyDate: now,
      description: 'Металлопрокат, бортовой прицеп.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-4',
      company: companies['company-silkbridge'],
      destinationCountry: kz,
      destinationCity: shymkent,
      bodyType: container,
      weightKg: 22000,
      volumeM3: 67,
      photoUrls: [] as string[],
      price: 1200,
      currency: Currency.USD,
      readyDate: daysFromNow(-1),
      description: 'Бытовая техника в контейнере, 40 футов.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-5',
      company: companies['company-transeurasia'],
      destinationCountry: uz,
      destinationCity: tashkent,
      bodyType: tank,
      weightKg: 24000,
      volumeM3: 28,
      photoUrls: [] as string[],
      price: 2000,
      currency: Currency.USD,
      readyDate: daysFromNow(3),
      description: 'Наливной груз, пищевая цистерна.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-6',
      company: companies['company-transeurasia'],
      destinationCountry: kz,
      destinationCity: taraz,
      bodyType: lowloader,
      weightKg: 30000,
      volumeM3: 15,
      photoUrls: [] as string[],
      price: 2500,
      currency: Currency.USD,
      readyDate: daysFromNow(-4),
      description: 'Негабаритное оборудование, низкорамный трал.',
      status: 'ARCHIVED' as const,
    },
    {
      key: 'cargo-7',
      company: companies['company-nurlyzhol'],
      destinationCountry: ru,
      destinationCity: moscow,
      bodyType: tent,
      weightKg: 19000,
      volumeM3: 50,
      photoUrls: [] as string[],
      price: 500000,
      currency: Currency.KZT,
      readyDate: daysFromNow(1),
      description: 'Сборный груз до Москвы, тент.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-8',
      company: companies['company-yidao'],
      destinationCountry: az,
      destinationCity: baku,
      bodyType: grain,
      weightKg: 26000,
      volumeM3: 60,
      photoUrls: [] as string[],
      price: 1800,
      currency: Currency.USD,
      readyDate: daysFromNow(5),
      description: 'Зерновые культуры насыпью.',
      status: 'PUBLISHED' as const,
    },
    {
      key: 'cargo-9',
      company: companies['company-silkbridge'],
      destinationCountry: kz,
      destinationCity: null,
      bodyType: carcarrier,
      weightKg: 12000,
      volumeM3: 90,
      photoUrls: [] as string[],
      price: 1600,
      currency: Currency.USD,
      readyDate: daysFromNow(-3),
      description: 'Перевозка легковых автомобилей, автовоз на 6 машин.',
      status: 'EXPIRED' as const,
    },
  ];

  const cargos: Record<string, { id: string; companyId: string }> = {};

  for (const def of cargoDefs) {
    const cargoId = demoId(`cargo:${def.key}`);
    const expiresAt = hoursFromDate(def.readyDate, 48);
    const archivedAt = def.status === 'ARCHIVED' ? hoursFromDate(def.readyDate, 72) : null;

    const cargo = await prisma.cargo.upsert({
      where: { id: cargoId },
      update: {
        status: def.status,
        price: def.price,
        currency: def.currency,
        readyDate: def.readyDate,
        expiresAt,
        archivedAt,
      },
      create: {
        id: cargoId,
        companyId: def.company.companyId,
        pointId: khorgos.id,
        destinationCountryId: def.destinationCountry.id,
        destinationCityId: def.destinationCity?.id ?? null,
        bodyTypeId: def.bodyType.id,
        weightKg: def.weightKg,
        volumeM3: def.volumeM3,
        photoUrls: def.photoUrls,
        price: def.price,
        currency: def.currency,
        readyDate: def.readyDate,
        description: def.description,
        status: def.status,
        publishedAt: hoursFromDate(def.readyDate, -12),
        expiresAt,
        archivedAt,
      },
    });

    cargos[def.key] = { id: cargo.id, companyId: def.company.companyId };
  }

  // ---------------------------------------------------------------------
  // Отклики и сделки
  // ---------------------------------------------------------------------
  async function upsertResponse(key: string, cargoKey: string, driverKey: string, status: 'PENDING' | 'SELECTED' | 'REJECTED') {
    const cargo = cargos[cargoKey];
    const driver = drivers[driverKey];
    return prisma.response.upsert({
      where: { cargoId_driverId: { cargoId: cargo.id, driverId: driver.driverId } },
      update: { status },
      create: { id: demoId(`response:${key}`), cargoId: cargo.id, driverId: driver.driverId, status },
    });
  }

  const respA = await upsertResponse('a', 'cargo-1', 'driver-1', 'SELECTED');
  const respB = await upsertResponse('b', 'cargo-3', 'driver-2', 'SELECTED');
  const respC = await upsertResponse('c', 'cargo-5', 'driver-3', 'SELECTED');
  const respD = await upsertResponse('d', 'cargo-7', 'driver-5', 'SELECTED');
  const respE = await upsertResponse('e', 'cargo-8', 'driver-6', 'SELECTED');
  const respF = await upsertResponse('f', 'cargo-4', 'driver-4', 'SELECTED');
  await upsertResponse('g', 'cargo-8', 'driver-1', 'REJECTED');
  await upsertResponse('h', 'cargo-2', 'driver-4', 'PENDING');

  async function upsertDeal(
    key: string,
    response: { id: string },
    cargoKey: string,
    driverKey: string,
    companyKey: string,
    status: 'SELECTED' | 'CONFIRMED_BY_DRIVER' | 'LOADED' | 'IN_TRANSIT' | 'DELIVERED' | 'CANCELLED',
    extra: { cancelReason?: string; cancelledByRole?: 'DRIVER' | 'COMPANY' } = {},
  ) {
    const cargo = cargos[cargoKey];
    const driver = drivers[driverKey];
    const company = companies[companyKey];
    const now2 = new Date();
    return prisma.deal.upsert({
      where: { responseId: response.id },
      update: { status, ...extra },
      create: {
        id: demoId(`deal:${key}`),
        responseId: response.id,
        cargoId: cargo.id,
        driverId: driver.driverId,
        companyId: company.companyId,
        status,
        confirmedAt: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED'].includes(status) ? now2 : null,
        loadedAt: ['LOADED', 'IN_TRANSIT', 'DELIVERED'].includes(status) ? now2 : null,
        inTransitAt: ['IN_TRANSIT', 'DELIVERED'].includes(status) ? now2 : null,
        deliveredAt: status === 'DELIVERED' ? now2 : null,
        ...extra,
      },
    });
  }

  const dealA = await upsertDeal('a', respA, 'cargo-1', 'driver-1', 'company-yidao', 'DELIVERED');
  const dealB = await upsertDeal('b', respB, 'cargo-3', 'driver-2', 'company-silkbridge', 'IN_TRANSIT');
  const dealC = await upsertDeal('c', respC, 'cargo-5', 'driver-3', 'company-transeurasia', 'LOADED');
  const dealD = await upsertDeal('d', respD, 'cargo-7', 'driver-5', 'company-nurlyzhol', 'CONFIRMED_BY_DRIVER');
  const dealE = await upsertDeal('e', respE, 'cargo-8', 'driver-6', 'company-yidao', 'SELECTED');
  const dealF = await upsertDeal('f', respF, 'cargo-4', 'driver-4', 'company-silkbridge', 'CANCELLED', {
    cancelReason: 'Водитель заболел и не смог выехать вовремя.',
    cancelledByRole: 'DRIVER',
  });

  // ---------------------------------------------------------------------
  // Контакты
  // ---------------------------------------------------------------------
  async function upsertContactEvent(
    key: string,
    driverKey: string,
    companyKey: string,
    cargoKey: string,
    actorUserId: string,
    type: 'CALL' | 'WHATSAPP',
  ) {
    const driver = drivers[driverKey];
    const company = companies[companyKey];
    const cargo = cargos[cargoKey];
    await prisma.contactEvent.upsert({
      where: { id: demoId(`contact:${key}`) },
      update: { type },
      create: {
        id: demoId(`contact:${key}`),
        driverId: driver.driverId,
        companyId: company.companyId,
        cargoId: cargo.id,
        actorUserId,
        type,
      },
    });
  }

  await upsertContactEvent('1', 'driver-1', 'company-yidao', 'cargo-1', drivers['driver-1'].userId, 'CALL');
  await upsertContactEvent('2', 'driver-3', 'company-transeurasia', 'cargo-5', drivers['driver-3'].userId, 'WHATSAPP');
  await upsertContactEvent('3', 'driver-5', 'company-nurlyzhol', 'cargo-7', drivers['driver-5'].userId, 'CALL');

  // ---------------------------------------------------------------------
  // Чаты и сообщения
  // ---------------------------------------------------------------------
  const chat1Id = demoId('chat:1');
  await prisma.chat.upsert({
    where: { id: chat1Id },
    update: {},
    create: {
      id: chat1Id,
      cargoId: cargos['cargo-1'].id,
      dealId: dealA.id,
      driverId: drivers['driver-1'].driverId,
      companyId: companies['company-yidao'].companyId,
    },
  });

  await prisma.message.upsert({
    where: { id: demoId('message:1-1') },
    update: {},
    create: {
      id: demoId('message:1-1'),
      chatId: chat1Id,
      senderUserId: drivers['driver-1'].userId,
      originalText: 'Здравствуйте, я готов забрать груз сегодня.',
      originalLang: 'ru',
      translations: { kk: 'Сәлеметсіз бе, жүкті бүгін алуға дайынмын.', zh: '您好,我今天可以来取货。' },
      isRead: true,
    },
  });
  await prisma.message.upsert({
    where: { id: demoId('message:1-2') },
    update: {},
    create: {
      id: demoId('message:1-2'),
      chatId: chat1Id,
      senderUserId: companies['company-yidao'].ownerUserId,
      originalText: '好的,请在装货点等待,半小时内到达。',
      originalLang: 'zh',
      translations: { ru: 'Хорошо, ждите на точке загрузки, будем в течение получаса.', kk: 'Жарайды, тиеу нүктесінде күтіңіз, жарты сағат ішінде боламыз.' },
      isRead: true,
    },
  });

  const chat2Id = demoId('chat:2');
  await prisma.chat.upsert({
    where: { id: chat2Id },
    update: {},
    create: {
      id: chat2Id,
      cargoId: cargos['cargo-7'].id,
      dealId: dealD.id,
      driverId: drivers['driver-5'].driverId,
      companyId: companies['company-nurlyzhol'].companyId,
    },
  });

  await prisma.message.upsert({
    where: { id: demoId('message:2-1') },
    update: {},
    create: {
      id: demoId('message:2-1'),
      chatId: chat2Id,
      senderUserId: drivers['driver-5'].userId,
      originalText: 'Когда можно подъехать за грузом?',
      originalLang: 'ru',
      translations: { kk: 'Жүкті қашан алуға болады?', zh: '什么时候可以来取货?' },
      isRead: false,
    },
  });
  await prisma.message.upsert({
    where: { id: demoId('message:2-2') },
    update: {},
    create: {
      id: demoId('message:2-2'),
      chatId: chat2Id,
      senderUserId: companies['company-nurlyzhol'].ownerUserId,
      originalText: 'Можно уже сейчас, водитель на месте?',
      originalLang: 'ru',
      translations: { kk: 'Қазір де болады, жүргізуші орында ма?', zh: '现在就可以,司机到了吗?' },
      isRead: false,
    },
  });

  // ---------------------------------------------------------------------
  // Отзывы (только для завершённой сделки A)
  // ---------------------------------------------------------------------
  await prisma.review.upsert({
    where: { dealId_authorRole: { dealId: dealA.id, authorRole: 'DRIVER' } },
    update: {},
    create: {
      id: demoId('review:a-driver'),
      dealId: dealA.id,
      authorUserId: drivers['driver-1'].userId,
      authorRole: 'DRIVER',
      rating: 5,
      comment: 'Быстро оформили, оплата вовремя.',
    },
  });
  await prisma.review.upsert({
    where: { dealId_authorRole: { dealId: dealA.id, authorRole: 'COMPANY' } },
    update: {},
    create: {
      id: demoId('review:a-company'),
      dealId: dealA.id,
      authorUserId: companies['company-yidao'].ownerUserId,
      authorRole: 'COMPANY',
      rating: 5,
      comment: 'Надёжный водитель, груз доставлен без задержек.',
    },
  });

  // ---------------------------------------------------------------------
  // Админ
  // ---------------------------------------------------------------------
  const adminEmail = 'admin@lubao.kz';
  const adminUser = await prisma.user.upsert({
    where: { email: adminEmail },
    update: { locale: 'ru', passwordHash },
    create: { role: 'ADMIN', email: adminEmail, passwordHash, locale: 'ru' },
  });

  // ---------------------------------------------------------------------
  // Документы на верификацию
  // ---------------------------------------------------------------------
  await prisma.verificationDocument.upsert({
    where: { id: demoId('doc:driver-3-license') },
    update: {},
    create: {
      id: demoId('doc:driver-3-license'),
      driverId: drivers['driver-3'].driverId,
      userId: drivers['driver-3'].userId,
      type: 'DRIVER_LICENSE',
      fileUrl: 'https://placehold.co/600x400?text=Driver+License',
      status: 'PENDING',
    },
  });
  await prisma.verificationDocument.upsert({
    where: { id: demoId('doc:driver-6-license') },
    update: {},
    create: {
      id: demoId('doc:driver-6-license'),
      driverId: drivers['driver-6'].driverId,
      userId: drivers['driver-6'].userId,
      vehicleId: demoId('vehicle:driver-6:tractor'),
      type: 'VEHICLE_PASSPORT',
      fileUrl: 'https://placehold.co/600x400?text=Vehicle+Passport',
      status: 'PENDING',
    },
  });
  await prisma.verificationDocument.upsert({
    where: { id: demoId('doc:transeurasia-registration') },
    update: {},
    create: {
      id: demoId('doc:transeurasia-registration'),
      companyId: companies['company-transeurasia'].companyId,
      userId: companies['company-transeurasia'].ownerUserId,
      type: 'COMPANY_REGISTRATION',
      fileUrl: 'https://placehold.co/600x400?text=Company+Registration',
      status: 'PENDING',
    },
  });
  await prisma.verificationDocument.upsert({
    where: { id: demoId('doc:driver-1-license') },
    update: {},
    create: {
      id: demoId('doc:driver-1-license'),
      driverId: drivers['driver-1'].driverId,
      userId: drivers['driver-1'].userId,
      type: 'DRIVER_LICENSE',
      fileUrl: 'https://placehold.co/600x400?text=Driver+License',
      status: 'APPROVED',
      reviewedByUserId: adminUser.id,
      reviewedAt: daysFromNow(-2),
    },
  });

  // ---------------------------------------------------------------------
  // Жалобы
  // ---------------------------------------------------------------------
  await prisma.complaint.upsert({
    where: { id: demoId('complaint:1') },
    update: {},
    create: {
      id: demoId('complaint:1'),
      reporterUserId: drivers['driver-2'].userId,
      targetType: 'CARGO',
      targetId: cargos['cargo-9'].id,
      reason: 'Груз висел с истёкшим статусом, компания не отвечала',
      status: 'OPEN',
    },
  });
  await prisma.complaint.upsert({
    where: { id: demoId('complaint:2') },
    update: {},
    create: {
      id: demoId('complaint:2'),
      reporterUserId: companies['company-silkbridge'].ownerUserId,
      targetType: 'DEAL',
      targetId: dealF.id,
      reason: 'Водитель отменил сделку без предупреждения в последний момент',
      status: 'OPEN',
    },
  });

  console.log('Демо-данные созданы.');
  console.log(`Пароль для всех демо-аккаунтов (компании и админ): ${DEMO_PASSWORD}`);
  console.log(`Админ: ${adminEmail}`);
  console.log('Телефоны водителей: ' + driverDefs.map((d) => d.phone).join(', '));
  console.log('Email компаний: ' + companyDefs.map((c) => c.ownerEmail).join(', '));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
