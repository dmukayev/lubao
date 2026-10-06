import { PrismaClient, Currency } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { encryptIdentifier, hashIdentifier, maskIdentifier } from '../src/identifiers/crypto';
import { normalizeIdentifier } from '../src/identifiers/normalize';

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
const E2E_CARGO_4_ID = '11111111-1111-4111-8111-111111111004';

export const E2E_FIXTURES = {
  // Три водителя: SMS-лимит 1 код/мин на номер — сценарии не должны делить
  // один телефон. D1 — сценарий «лента→чат», D2 — «сделка и догруз»,
  // D3 — виден логисту (анонс на точке уже есть).
  /// Номер в чёрном списке (нет аккаунта) — сценарий «регистрируется заново».
  blacklistedPhone: '+77010000099',
  /// D4 — НЕ проверен, на точке: шаг «Проверенные» у логиста обязан менять список.
  driverPhone4: '+77010000004',
  /// D5 — с подтверждённым синтетическим ИИН: админ блокирует его (сценарий 12).
  driverPhone5: '+77010000005',
  /// Новые водители сценариев 11/12 регистрируются в приложении (+…006 — A, +…007 — B).
  newDriverPhoneA: '+77010000006',
  newDriverPhoneB: '+77010000007',
  /// Синтетический ИИН (контрольная сумма верна, не принадлежит человеку).
  syntheticIin: '900101500109',
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
  /// Груз 4 — только для приглашения логистом из чата (сценарий «цепочка 035»).
  cargo4Id: E2E_CARGO_4_ID,
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
    { n: 4, phone: E2E_FIXTURES.driverPhone4, name: 'Нурлан Холодов' },
    { n: 5, phone: E2E_FIXTURES.driverPhone5, name: 'Ержан Блоков' },
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
      update: { fullName: def.name, homeCityId: almaty.id, anyCountry: true, isVerified: def.n !== 4 },
      create: { id: `dddddddd-dddd-4ddd-8ddd-ddddddddd00${def.n}`, userId: user.id, fullName: def.name, homeCityId: almaty.id, anyCountry: true, isVerified: def.n !== 4 },
    });
    driverIds[def.n] = driver.id;

    const tractorId = `aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa00${def.n}`;
    const trailerId = `bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb00${def.n}`;
    await prisma.vehicle.upsert({
      where: { id: tractorId },
      update: { isVerified: def.n !== 4 },
      create: { id: tractorId, driverId: driver.id, kind: 'TRACTOR', plateNumber: `E2E00${def.n}KZ`, brand: 'Volvo FH', isVerified: def.n !== 4 },
    });
    await prisma.vehicle.upsert({
      where: { id: trailerId },
      update: { isVerified: def.n !== 4, capacityTons: 20 },
      create: { id: trailerId, driverId: driver.id, kind: 'TRAILER', bodyTypeId: tent.id, capacityTons: 20, lengthM: 13.6, isVerified: def.n !== 4 },
    });

    // Сброс следов прошлых прогонов: анонсы, чаты, отклики, сделки.
    // Просмотры анонса логистом (arrival_views) ссылаются на анонс — первыми.
    await prisma.arrivalView.deleteMany({ where: { arrival: { driverId: driver.id } } });
    await prisma.arrival.deleteMany({ where: { driverId: driver.id } });
    if (def.n === 3 || def.n === 4) {
      // D3 (проверен) и D4 (нет) уже на точке — логист видит их в «Водители» без других сценариев.
      await prisma.arrival.create({
        data: {
          driverId: driver.id,
          pointId: khorgos.id,
          plannedAt: new Date(),
          plannedDay: new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00.000Z'),
          arrivedAt: new Date(Date.now() - 15 * 60 * 1000),
          status: 'ON_SITE',
          anyCountry: true,
          tractorId,
          trailerId,
        },
      });
    }
  }

  // D5 — подтверждённый ИИН (сценарий 12: блокировка «по идентификаторам»).
  const iinNorm = normalizeIdentifier('IIN', E2E_FIXTURES.syntheticIin);
  await prisma.identifier.upsert({
    where: { ownerType_ownerId_type: { ownerType: 'DRIVER', ownerId: driverIds[5], type: 'IIN' } },
    update: { valueHash: hashIdentifier(iinNorm), valueMasked: maskIdentifier('IIN', iinNorm), valueEncrypted: encryptIdentifier(iinNorm) },
    create: {
      type: 'IIN',
      valueHash: hashIdentifier(iinNorm),
      valueMasked: maskIdentifier('IIN', iinNorm),
      valueEncrypted: encryptIdentifier(iinNorm),
      ownerType: 'DRIVER',
      ownerId: driverIds[5],
      confirmedAt: new Date(),
    },
  });

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
    { id: E2E_FIXTURES.cargo4Id, weightKg: 5000, price: 700, note: 'E2E — груз 4 (5 т, приглашение из чата)' },
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
  // Чёрный список по телефону без аккаунта (039, п.2): тот, кто
  // зарегистрируется с этим номером, должен попасть в «Требует внимания».
  // Чистим следы прошлого прогона (аккаунт и его идентификатор).
  // -----------------------------------------------------------------
  const adminForBlock = await prisma.user.findFirstOrThrow({ where: { email: E2E_FIXTURES.adminEmail } });
  const blockedNorm = normalizeIdentifier('PHONE', E2E_FIXTURES.blacklistedPhone);
  const blockedHash = hashIdentifier(blockedNorm);
  const oldUser = await prisma.user.findUnique({ where: { phone: E2E_FIXTURES.blacklistedPhone }, include: { driver: true } });
  if (oldUser?.driver) {
    await prisma.identifier.deleteMany({ where: { ownerType: 'DRIVER', ownerId: oldUser.driver.id } });
    await prisma.vehicle.deleteMany({ where: { driverId: oldUser.driver.id } });
    await prisma.driverDirection.deleteMany({ where: { driverId: oldUser.driver.id } });
    await prisma.driverPermit.deleteMany({ where: { driverId: oldUser.driver.id } });
    await prisma.notificationSetting.deleteMany({ where: { userId: oldUser.id } });
    await prisma.driver.delete({ where: { id: oldUser.driver.id } });
  }
  if (oldUser) {
    await prisma.session.deleteMany({ where: { userId: oldUser.id } });
    await prisma.notificationSetting.deleteMany({ where: { userId: oldUser.id } });
    await prisma.user.delete({ where: { id: oldUser.id } });
  }
  await prisma.blockedIdentifier.deleteMany({ where: { type: 'PHONE', valueHash: blockedHash } });
  await prisma.blockedIdentifier.create({
    data: {
      type: 'PHONE',
      valueHash: blockedHash,
      valueMasked: maskIdentifier('PHONE', blockedNorm),
      reason: 'E2E: номер в чёрном списке',
      blockedByUserId: adminForBlock.id,
    },
  });

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
