import { PrismaClient, Currency } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

if (process.env.NODE_ENV === 'production') {
  console.error('prisma:seed:e2e is blocked when NODE_ENV=production');
  process.exit(1);
}

const prisma = new PrismaClient();

/// Сквозные сценарии (задача 034) запускаются против отдельной БД
/// `lubao_e2e`, поэтому фиксированные id безопасны — это не демо-данные
/// в общей базе. Дни считаем от «сегодня», чтобы повторный запуск в любой
/// день давал тот же результат (п. «Готово когда»).
const E2E_PASSWORD = 'E2eLubao2026!';
const E2E_CARGO_ID = '11111111-1111-4111-8111-111111111001';
const E2E_CARGO_2_ID = '11111111-1111-4111-8111-111111111002';
const E2E_CARGO_3_ID = '11111111-1111-4111-8111-111111111003';

export const E2E_FIXTURES = {
  // Три водителя: SMS-лимит 1 код/мин на номер — сценарии не должны делить
  // один телефон. D1 — сценарий «лента→чат», D2 — «сделка и догруз»,
  // D3 — виден логисту (анонс на точке уже есть).
  driverPhone2: '+77010000002',
  driverPhone3: '+77010000003',
  driverPhone: '+77010000001',
  driverFullName: 'Эдуард Тестов',
  companyOwnerEmail: 'e2e-owner@lubao-test.cn',
  companyLogistEmail: 'e2e-logist@lubao-test.cn',
  adminEmail: 'e2e-admin@lubao-test.kz',
  password: E2E_PASSWORD,
  cargoId: E2E_CARGO_ID,
  cargo2Id: E2E_CARGO_2_ID,
  cargo3Id: E2E_CARGO_3_ID,
};

function daysFromNow(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + days);
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

async function khorgosPoint() {
  return prisma.point.findFirstOrThrow({});
}

async function main() {
  const passwordHash = await bcrypt.hash(E2E_PASSWORD, 10);

  const [kz, cn] = await Promise.all([country('KZ'), country('CN')]);
  const [almaty] = await Promise.all([cityByRuName('Алматы')]);
  const tent = await bodyType('TENT');
  const khorgos = await khorgosPoint();

  // -----------------------------------------------------------------
  // Водители — зарегистрированы, машины ПРОВЕРЕНЫ (иначе «Подтверждаю
  // перевозку» упёрлось бы в VEHICLE_NOT_VERIFIED), трейлер 20 т.
  // -----------------------------------------------------------------
  const driverDefs = [
    { n: 1, phone: E2E_FIXTURES.driverPhone, name: E2E_FIXTURES.driverFullName },
    { n: 2, phone: E2E_FIXTURES.driverPhone2, name: 'Давид Сделкин' },
    { n: 3, phone: E2E_FIXTURES.driverPhone3, name: 'Борис Точкин' },
  ];
  const driverIds: Record<number, string> = {};
  // Машины первой версии сида (другие id, прицеп не проверен) — убираем,
  // иначе гараж-фолбэк мог бы подобрать их вместо проверенных.
  await prisma.vehicle.deleteMany({
    where: { id: { in: ['22222222-2222-4222-8222-222222222001', '22222222-2222-4222-8222-222222222002'] } },
  });
  for (const def of driverDefs) {
    const user = await prisma.user.upsert({
      where: { phone: def.phone },
      update: { locale: 'ru' },
      create: { role: 'DRIVER', phone: def.phone, locale: 'ru' },
    });
    const driver = await prisma.driver.upsert({
      where: { userId: user.id },
      update: { fullName: def.name, homeCityId: almaty.id, anyCountry: true, isVerified: true },
      create: { userId: user.id, fullName: def.name, homeCityId: almaty.id, anyCountry: true, isVerified: true },
    });
    driverIds[def.n] = driver.id;

    const tractorId = `aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa00${def.n}`;
    const trailerId = `bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb00${def.n}`;
    await prisma.vehicle.upsert({
      where: { id: tractorId },
      update: { isVerified: true },
      create: { id: tractorId, driverId: driver.id, kind: 'TRACTOR', plateNumber: `E2E00${def.n}KZ`, brand: 'Volvo FH', isVerified: true },
    });
    await prisma.vehicle.upsert({
      where: { id: trailerId },
      update: { isVerified: true, capacityTons: 20 },
      create: { id: trailerId, driverId: driver.id, kind: 'TRAILER', bodyTypeId: tent.id, capacityTons: 20, lengthM: 13.6, isVerified: true },
    });

    // Сброс следов прошлых прогонов: анонсы, чаты, отклики, сделки.
    // Просмотры анонса логистом (arrival_views) ссылаются на анонс — первыми.
    await prisma.arrivalView.deleteMany({ where: { arrival: { driverId: driver.id } } });
    await prisma.arrival.deleteMany({ where: { driverId: driver.id } });
    if (def.n === 3) {
      // D3 уже на точке — логист видит его в «Водители» без участия других сценариев.
      await prisma.arrival.create({
        data: {
          driverId: driver.id,
          pointId: khorgos.id,
          plannedAt: new Date(),
          arrivedAt: new Date(Date.now() - 15 * 60 * 1000),
          status: 'ON_SITE',
          anyCountry: true,
          tractorId,
          trailerId,
        },
      });
    }
  }

  // -----------------------------------------------------------------
  // Компания — логист и владелец.
  // -----------------------------------------------------------------
  const company = await prisma.company.upsert({
    where: { id: '33333333-3333-4333-8333-333333333001' },
    update: { isVerified: true },
    create: {
      id: '33333333-3333-4333-8333-333333333001',
      name: 'E2E Test Logistics',
      countryId: cn.id,
      city: 'Урумчи',
      isVerified: true,
    },
  });

  const ownerUser = await prisma.user.upsert({
    where: { email: E2E_FIXTURES.companyOwnerEmail },
    update: { locale: 'ru', passwordHash },
    create: { role: 'COMPANY', email: E2E_FIXTURES.companyOwnerEmail, passwordHash, locale: 'ru' },
  });
  await prisma.companyMember.upsert({
    where: { userId: ownerUser.id },
    update: { companyId: company.id, role: 'OWNER' },
    create: { companyId: company.id, userId: ownerUser.id, role: 'OWNER' },
  });

  const logistUser = await prisma.user.upsert({
    where: { email: E2E_FIXTURES.companyLogistEmail },
    update: { locale: 'ru', passwordHash },
    create: { role: 'COMPANY', email: E2E_FIXTURES.companyLogistEmail, passwordHash, locale: 'ru' },
  });
  await prisma.companyMember.upsert({
    where: { userId: logistUser.id },
    update: { companyId: company.id, role: 'LOGIST' },
    create: { companyId: company.id, userId: logistUser.id, role: 'LOGIST' },
  });

  // -----------------------------------------------------------------
  // Админ.
  // -----------------------------------------------------------------
  await prisma.user.upsert({
    where: { email: E2E_FIXTURES.adminEmail },
    update: { locale: 'ru', passwordHash },
    create: { role: 'ADMIN', email: E2E_FIXTURES.adminEmail, passwordHash, locale: 'ru' },
  });

  // -----------------------------------------------------------------
  // Грузы — фиксированные id; вес 10 + 8 т помещаются в 20-тонный прицеп
  // (догруз), третий на 10 т уже не помещается («Машина заполнена»).
  // Сначала сброс следов прошлого прогона (сделки → отклики → чаты).
  // -----------------------------------------------------------------
  const readyDate = daysFromNow(1);
  const cargoDefs = [
    { id: E2E_FIXTURES.cargoId, weightKg: 10000, price: 1000, note: 'E2E — груз 1 (10 т)' },
    { id: E2E_FIXTURES.cargo2Id, weightKg: 8000, price: 800, note: 'E2E — груз 2 (8 т, догруз)' },
    { id: E2E_FIXTURES.cargo3Id, weightKg: 10000, price: 900, note: 'E2E — груз 3 (10 т, не поместится)' },
  ];
  const cargoIds = cargoDefs.map((c) => c.id);
  await prisma.deal.deleteMany({ where: { cargoId: { in: cargoIds } } });
  await prisma.message.deleteMany({ where: { chat: { cargoId: { in: cargoIds } } } });
  await prisma.chat.deleteMany({ where: { cargoId: { in: cargoIds } } });
  await prisma.response.deleteMany({ where: { cargoId: { in: cargoIds } } });

  for (const def of cargoDefs) {
    const data = {
      status: 'PUBLISHED' as const,
      weightKg: def.weightKg,
      price: def.price,
      currency: Currency.USD,
      readyDate,
      expiresAt: daysFromNow(3),
      archivedAt: null,
    };
    await prisma.cargo.upsert({
      where: { id: def.id },
      update: data,
      create: {
        id: def.id,
        companyId: company.id,
        pointId: khorgos.id,
        destinationCountryId: kz.id,
        destinationCityId: almaty.id,
        bodyTypeId: tent.id,
        photoUrls: [],
        description: def.note,
        publishedAt: new Date(),
        ...data,
      },
    });
  }

  // -----------------------------------------------------------------
  // Жалоба для сценария админки (13): новая → «в работе» → закрыта.
  // -----------------------------------------------------------------
  await prisma.complaint.deleteMany({ where: { reason: { startsWith: 'E2E:' } } });
  await prisma.complaint.create({
    data: {
      reporterUserId: ownerUser.id,
      targetType: 'CARGO',
      targetId: E2E_FIXTURES.cargoId,
      reason: 'E2E: синтетическая жалоба для проверки админки',
      status: 'OPEN',
    },
  });

  console.log('E2E-данные готовы.');
  console.log(`Водители: ${E2E_FIXTURES.driverPhone}, ${E2E_FIXTURES.driverPhone2}, ${E2E_FIXTURES.driverPhone3} (код 1111)`);
  console.log(`Компания: ${E2E_FIXTURES.companyOwnerEmail} / ${E2E_FIXTURES.password}`);
  console.log(`Админ: ${E2E_FIXTURES.adminEmail} / ${E2E_FIXTURES.password}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
