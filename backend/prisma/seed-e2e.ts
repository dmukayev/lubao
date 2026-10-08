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
const E2E_CARGO_5_ID = '11111111-1111-4111-8111-111111111005';
const E2E_CARGO_6_ID = '11111111-1111-4111-8111-111111111006';
const E2E_CARGO_7_ID = '11111111-1111-4111-8111-111111111007';
const E2E_CARGO_KZ_ID = '11111111-1111-4111-8111-111111111008';

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
  /// Груз 5 — свободный до конца прогона: на него откликается НЕПРОВЕРЕННЫЙ новичок (041, п.1).
  cargo5Id: E2E_CARGO_5_ID,
  /// Груз 6 — из Алматы, «можно догрузом»; груз 7 — из Астаны (задача 040: порядок ленты по городу анонса).
  cargo6Id: E2E_CARGO_6_ID,
  cargo7Id: E2E_CARGO_7_ID,
  /// Груз казахстанской компании — у неё есть WhatsApp (у китайской кнопка скрыта).
  cargoKzId: E2E_CARGO_KZ_ID,
  kzCompanyOwnerEmail: 'e2e-owner@lubao-test.kz',
  kzCompanyPhone: '+77010000050',
  /// D6 — анонсировал «свободен в Алматы» на сегодня (040: «Кто свободен» с выбором города).
  driverPhone6: '+77010000008',
};

/// «Сегодня» по часовому поясу приложения — тем же правилом, что у правила
/// свежести анонса на сервере (APP_TIMEZONE, по умолчанию Алматы).
function localToday(): Date {
  const day = new Intl.DateTimeFormat('en-CA', {
    timeZone: process.env.APP_TIMEZONE || 'Asia/Almaty',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
  return new Date(`${day}T00:00:00.000Z`);
}

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

async function pointByCityCode(code: string) {
  return prisma.point.findFirstOrThrow({ where: { city: { code } } });
}

async function khorgosPoint() {
  // Хоргос — терминал, остальные точки (города РК) заведены сидом справочника (задача 040).
  return prisma.point.findFirstOrThrow({ where: { city: { code: 'KZ-ZHETYSU-KHORGOS' } } });
}

async function main() {
  const passwordHash = await bcrypt.hash(E2E_PASSWORD, 10);

  const [kz, cn] = await Promise.all([country('KZ'), country('CN')]);
  const [almaty] = await Promise.all([cityByRuName('Алматы')]);
  const tent = await bodyType('TENT');
  // 047: категория обязательна — синтетическим грузам «Стройматериалы».
  const category = await prisma.cargoCategory.findUniqueOrThrow({ where: { code: 'CONSTRUCTION' } });
  const khorgos = await khorgosPoint();
  const almatyPoint = await pointByCityCode('KZ-ALMATY');
  const astanaPoint = await pointByCityCode('KZ-ASTANA');

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
    { n: 6, phone: E2E_FIXTURES.driverPhone6, name: 'Алия Алматинская' },
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
    if (def.n === 6) {
      // D6 — «свободен в Алматы» на сегодня: логист видит в «Кто свободен» после выбора города.
      await prisma.arrival.create({
        data: {
          driverId: driver.id,
          pointId: almatyPoint.id,
          plannedAt: new Date(),
          plannedDay: localToday(),
          status: 'PLANNED',
          anyCountry: true,
          tractorId,
          trailerId,
        },
      });
    }
    if (def.n === 3 || def.n === 4) {
      // D3 (проверен) и D4 (нет) уже на точке — логист видит их в «Водители» без других сценариев.
      await prisma.arrival.create({
        data: {
          driverId: driver.id,
          pointId: khorgos.id,
          plannedAt: new Date(),
          plannedDay: localToday(),
          arrivedAt: new Date(Date.now() - 15 * 60 * 1000),
          lastConfirmedAt: new Date(Date.now() - 15 * 60 * 1000),
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
  // Порядок = порядок создания (createdAt): последний груз компании — груз 5
  // из Хоргоса, и именно его город «Кто свободен» берёт по умолчанию.
  const cargoDefs = [
    { id: E2E_FIXTURES.cargo6Id, weightKg: 4000, price: 500, note: 'E2E — груз 6 (из Алматы, можно догрузом)', pointId: almatyPoint.id, allowPartial: true },
    { id: E2E_FIXTURES.cargo7Id, weightKg: 4000, price: 500, note: 'E2E — груз 7 (из Астаны)', pointId: astanaPoint.id, allowPartial: false },
    { id: E2E_FIXTURES.cargoId, weightKg: 10000, price: 1000, note: 'E2E — груз 1 (10 т)', pointId: khorgos.id, allowPartial: false },
    { id: E2E_FIXTURES.cargo2Id, weightKg: 8000, price: 800, note: 'E2E — груз 2 (8 т, догруз)', pointId: khorgos.id, allowPartial: false },
    { id: E2E_FIXTURES.cargo3Id, weightKg: 10000, price: 900, note: 'E2E — груз 3 (10 т, не поместится)', pointId: khorgos.id, allowPartial: false },
    { id: E2E_FIXTURES.cargo4Id, weightKg: 5000, price: 700, note: 'E2E — груз 4 (5 т, приглашение из чата)', pointId: khorgos.id, allowPartial: false },
    { id: E2E_FIXTURES.cargo5Id, weightKg: 3000, price: 600, note: 'E2E — груз 5 (3 т, отклик новичка)', pointId: khorgos.id, allowPartial: false },
  ];
  const cargoIds = cargoDefs.map((c) => c.id);
  await prisma.deal.deleteMany({ where: { cargoId: { in: cargoIds } } });
  await prisma.message.deleteMany({ where: { chat: { cargoId: { in: cargoIds } } } });
  await prisma.chat.deleteMany({ where: { cargoId: { in: cargoIds } } });
  await prisma.response.deleteMany({ where: { cargoId: { in: cargoIds } } });

  for (const [index, def] of cargoDefs.entries()) {
    const data = {
      status: 'PUBLISHED' as const,
      createdAt: new Date(Date.now() - (cargoDefs.length - index) * 1000),
      allowPartial: def.allowPartial,
      pointId: def.pointId,
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
        destinationCountryId: kz.id,
        destinationCityId: almaty.id,
        bodyTypeId: tent.id,
        categoryId: category.id,
        photoUrls: [],
        description: def.note,
        publishedAt: new Date(),
        ...data,
      },
    });
  }

  // -----------------------------------------------------------------
  // Казахстанская компания с одним грузом: кнопка WhatsApp видна только
  // у некитайских компаний — её проверяет сценарий «лента→чат».
  // -----------------------------------------------------------------
  const kzCompany = await prisma.company.upsert({
    where: { id: '33333333-3333-4333-8333-333333333002' },
    update: { isVerified: true },
    create: { id: '33333333-3333-4333-8333-333333333002', name: 'E2E Казахстан Логистик', countryId: kz.id, city: 'Алматы', isVerified: true },
  });
  const kzOwner = await prisma.user.upsert({
    where: { email: E2E_FIXTURES.kzCompanyOwnerEmail },
    update: { locale: 'ru', passwordHash, phone: E2E_FIXTURES.kzCompanyPhone },
    create: { role: 'COMPANY', email: E2E_FIXTURES.kzCompanyOwnerEmail, phone: E2E_FIXTURES.kzCompanyPhone, passwordHash, locale: 'ru' },
  });
  await prisma.companyMember.upsert({
    where: { userId: kzOwner.id },
    update: { companyId: kzCompany.id, role: 'OWNER', contactPhone: E2E_FIXTURES.kzCompanyPhone },
    create: { companyId: kzCompany.id, userId: kzOwner.id, role: 'OWNER', contactPhone: E2E_FIXTURES.kzCompanyPhone },
  });
  await prisma.contactEvent.deleteMany({ where: { cargoId: E2E_CARGO_KZ_ID } });
  const kzCargo = {
    status: 'PUBLISHED' as const,
    allowPartial: false,
    pointId: khorgos.id,
    weightKg: 6000,
    price: 700,
    currency: Currency.USD,
    readyDate,
    expiresAt: daysFromNow(3),
    archivedAt: null,
  };
  await prisma.cargo.upsert({
    where: { id: E2E_CARGO_KZ_ID },
    update: kzCargo,
    create: {
      id: E2E_CARGO_KZ_ID,
      companyId: kzCompany.id,
      destinationCountryId: kz.id,
      destinationCityId: almaty.id,
      bodyTypeId: tent.id,
      categoryId: category.id,
      photoUrls: [],
      description: 'E2E — груз казахстанской компании (WhatsApp)',
      publishedAt: new Date(),
      createdAt: new Date(Date.now() - 60_000),
      ...kzCargo,
    },
  });

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
