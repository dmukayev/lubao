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

export const E2E_FIXTURES = {
  driverPhone: '+77010000001',
  driverFullName: 'E2E Тестов Водитель',
  companyOwnerEmail: 'e2e-owner@lubao-test.cn',
  companyLogistEmail: 'e2e-logist@lubao-test.cn',
  adminEmail: 'e2e-admin@lubao-test.kz',
  password: E2E_PASSWORD,
  cargoId: E2E_CARGO_ID,
  cargo2Id: E2E_CARGO_2_ID,
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
  // Водитель — зарегистрирован, без анонса (сценарий 4 сам его создаёт).
  // -----------------------------------------------------------------
  const driverUser = await prisma.user.upsert({
    where: { phone: E2E_FIXTURES.driverPhone },
    update: { locale: 'ru' },
    create: { role: 'DRIVER', phone: E2E_FIXTURES.driverPhone, locale: 'ru' },
  });

  const driver = await prisma.driver.upsert({
    where: { userId: driverUser.id },
    update: { fullName: E2E_FIXTURES.driverFullName, homeCityId: almaty.id, anyCountry: true, isVerified: true },
    create: {
      userId: driverUser.id,
      fullName: E2E_FIXTURES.driverFullName,
      homeCityId: almaty.id,
      anyCountry: true,
      isVerified: true,
    },
  });

  await prisma.vehicle.upsert({
    where: { id: '22222222-2222-4222-8222-222222222001' },
    update: {},
    create: {
      id: '22222222-2222-4222-8222-222222222001',
      driverId: driver.id,
      kind: 'TRACTOR',
      plateNumber: 'E2E001KZ',
      brand: 'Volvo FH',
    },
  });
  await prisma.vehicle.upsert({
    where: { id: '22222222-2222-4222-8222-222222222002' },
    update: {},
    create: {
      id: '22222222-2222-4222-8222-222222222002',
      driverId: driver.id,
      kind: 'TRAILER',
      bodyTypeId: tent.id,
      capacityTons: 20,
      lengthM: 13.6,
    },
  });

  // Сбросить анонс от предыдущего прогона — сценарий 4 начинает «с нуля».
  await prisma.arrival.deleteMany({ where: { driverId: driver.id } });

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
  // Грузы — фиксированный id для сценария «лента → карточка → чат».
  // -----------------------------------------------------------------
  const readyDate = daysFromNow(1);
  await prisma.cargo.upsert({
    where: { id: E2E_FIXTURES.cargoId },
    update: {
      status: 'PUBLISHED',
      price: 1000,
      currency: Currency.USD,
      readyDate,
      expiresAt: daysFromNow(3),
      archivedAt: null,
    },
    create: {
      id: E2E_FIXTURES.cargoId,
      companyId: company.id,
      pointId: khorgos.id,
      destinationCountryId: kz.id,
      destinationCityId: almaty.id,
      bodyTypeId: tent.id,
      weightKg: 10000,
      photoUrls: [],
      price: 1000,
      currency: Currency.USD,
      readyDate,
      description: 'E2E — синтетический груз для сценария «лента → чат».',
      status: 'PUBLISHED',
      publishedAt: new Date(),
      expiresAt: daysFromNow(3),
    },
  });

  await prisma.cargo.upsert({
    where: { id: E2E_FIXTURES.cargo2Id },
    update: { status: 'PUBLISHED', readyDate, expiresAt: daysFromNow(3), archivedAt: null },
    create: {
      id: E2E_FIXTURES.cargo2Id,
      companyId: company.id,
      pointId: khorgos.id,
      destinationCountryId: kz.id,
      destinationCityId: almaty.id,
      bodyTypeId: tent.id,
      weightKg: 8000,
      photoUrls: [],
      price: 800,
      currency: Currency.USD,
      readyDate,
      description: 'E2E — второй синтетический груз (без откликов).',
      status: 'PUBLISHED',
      publishedAt: new Date(),
      expiresAt: daysFromNow(3),
    },
  });

  // Чаты/отклики/сделки от предыдущих прогонов — сбросить, сценарий 5 сам
  // создаёт чат заново через «Написать».
  await prisma.message.deleteMany({ where: { chat: { cargoId: { in: [E2E_FIXTURES.cargoId, E2E_FIXTURES.cargo2Id] } } } });
  await prisma.chat.deleteMany({ where: { cargoId: { in: [E2E_FIXTURES.cargoId, E2E_FIXTURES.cargo2Id] } } });
  await prisma.response.deleteMany({ where: { cargoId: { in: [E2E_FIXTURES.cargoId, E2E_FIXTURES.cargo2Id] } } });

  console.log('E2E-данные готовы.');
  console.log(`Водитель: ${E2E_FIXTURES.driverPhone} (код 1111)`);
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
