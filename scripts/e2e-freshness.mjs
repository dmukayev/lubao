// Задача 040, п.4 — правило свежести анонса на РЕАЛЬНОЙ базе (не на моках):
// «Доехали?» в день приезда, «Ещё ищете груз?» каждые 12 ч, гашение без
// ответа, геозона терминала. Время подставляется параметром `now`, поэтому
// ждать сутки не нужно. Работает только с анонсами водителя D5 и убирает их
// за собой — остальные сценарии не затрагиваются.
//
// Использование: DATABASE_URL=<lubao_e2e> node scripts/e2e-freshness.mjs
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { PrismaClient } = require('../backend/node_modules/@prisma/client');
const { ArrivalsService } = require('../backend/dist/src/arrivals/arrivals.service.js');
const { leaveTerminalIfOutside } = require('../backend/dist/src/arrivals/arrival-lifecycle.js');
const { localDateOnly } = require('../backend/dist/src/common/date-only.js');

const prisma = new PrismaClient();
const notified = [];
const service = new ArrivalsService(prisma, {
  notify: async (target, event, payload) => {
    notified.push({ target, event, payload });
  },
});

let checks = 0;
function assert(cond, name, detail = '') {
  if (!cond) {
    console.error(`FAIL ${name} ${detail}`);
    process.exitCode = 1;
    throw new Error(name);
  }
  checks++;
  console.log(`ok ${name}`);
}

const H = 3600 * 1000;
const driver = await prisma.driver.findUniqueOrThrow({ where: { id: 'dddddddd-dddd-4ddd-8ddd-ddddddddd005' }, include: { user: true } });
const almaty = await prisma.point.findFirstOrThrow({ where: { city: { code: 'KZ-ALMATY' } } });
const khorgos = await prisma.point.findFirstOrThrow({ where: { city: { code: 'KZ-ZHETYSU-KHORGOS' } } });

async function cleanup() {
  await prisma.arrivalView.deleteMany({ where: { arrival: { driverId: driver.id } } });
  await prisma.arrivalDirection.deleteMany({ where: { arrival: { driverId: driver.id } } });
  await prisma.arrival.deleteMany({ where: { driverId: driver.id } });
}
const sweep = (now) => service.sweep({ now, notify: true, driverId: driver.id });
const events = () => notified.map((n) => n.event);
const reload = (id) => prisma.arrival.findUniqueOrThrow({ where: { id } });

try {
  await cleanup();

  // ---- 1. Запланированный: молчим до дня приезда, в день — «Доехали?», к концу дня — гаснет.
  const today = localDateOnly(new Date());
  const day = new Date(`${today}T00:00:00.000Z`);
  const planned = await prisma.arrival.create({
    data: { driverId: driver.id, pointId: almaty.id, plannedAt: new Date(), plannedDay: day, status: 'PLANNED', anyCountry: true },
  });
  const noonAlmaty = new Date(`${today}T07:00:00.000Z`); // 12:00 по Алматы (UTC+5)
  const dayBefore = new Date(noonAlmaty.getTime() - 24 * H);
  let res = await sweep(dayBefore);
  assert(res.asked === 0 && res.expired === 0 && notified.length === 0, 'PLANNED за день до приезда — тишина');
  res = await sweep(new Date(`${today}T02:00:00.000Z`)); // 07:00 по Алматы
  assert(res.asked === 0, 'PLANNED в день приезда до 08:00 — ещё тишина');
  res = await sweep(noonAlmaty);
  assert(res.asked === 1 && events().join() === 'ARRIVAL_DAY_CHECK', 'в день приезда — одно «Доехали?»', events().join());
  assert(JSON.stringify(notified[0].payload.pointName) === JSON.stringify(almaty.name), 'push несёт название города из справочника');
  assert((await reload(planned.id)).dayAskedAt !== null, 'dayAskedAt записан');
  res = await sweep(new Date(noonAlmaty.getTime() + 3 * H));
  assert(res.asked === 0 && notified.length === 1, 'повторного «Доехали?» нет');
  const nextDay = new Date(`${today}T19:30:00.000Z`); // 00:30 следующего дня по Алматы
  res = await sweep(nextDay);
  assert(res.expired === 1 && (await reload(planned.id)).status === 'EXPIRED', 'день закончился без «Я на месте» — анонс EXPIRED');
  assert(notified.length === 1, 'при гашении push не шлётся');

  // ---- 2. «На месте»: 12 ч → «Ещё ищете груз?», ещё 12 ч без ответа → гаснет.
  notified.length = 0;
  const t0 = new Date();
  const onSite = await prisma.arrival.create({
    data: { driverId: driver.id, pointId: almaty.id, plannedAt: t0, plannedDay: day, arrivedAt: t0, lastConfirmedAt: t0, status: 'ON_SITE', waitDays: 3, anyCountry: true },
  });
  res = await sweep(new Date(t0.getTime() + 11.9 * H));
  assert(res.asked === 0 && res.expired === 0, 'на месте до 12 ч — тишина');
  const askAt = new Date(t0.getTime() + 12 * H);
  res = await sweep(askAt);
  assert(res.asked === 1 && events().join() === 'ARRIVAL_STILL_LOOKING', 'через 12 ч — «Ещё ищете груз?»', events().join());
  assert((await reload(onSite.id)).staleAskedAt?.getTime() === askAt.getTime(), 'staleAskedAt записан');
  res = await sweep(new Date(askAt.getTime() + 11 * H));
  assert(res.expired === 0 && res.asked === 0, 'после вопроса, пока не прошло ещё 12 ч, анонс жив и не переспрашивает');
  res = await sweep(new Date(askAt.getTime() + 12 * H));
  assert(res.expired === 1 && (await reload(onSite.id)).status === 'EXPIRED', 'без ответа 12 ч после вопроса — анонс гаснет');

  // ---- 3. Ответ «Да, ищу» начинает отсчёт заново.
  notified.length = 0;
  const arrived = new Date(Date.now() - 12 * H - 5 * 60 * 1000);
  const answering = await prisma.arrival.create({
    data: { driverId: driver.id, pointId: almaty.id, plannedAt: arrived, plannedDay: day, arrivedAt: arrived, lastConfirmedAt: arrived, status: 'ON_SITE', waitDays: 3, anyCountry: true },
  });
  const nowReal = new Date();
  res = await sweep(nowReal);
  assert(res.asked === 1, 'на месте 12 ч 5 мин — вопрос задан');
  const answer = await service.confirmStillLooking(driver.user.id);
  assert(answer.id === answering.id && answer.ask === null, 'после «Да, ищу» вопрос в ответе сервера снят (ask=null)');
  res = await sweep(new Date(nowReal.getTime() + 11 * H));
  assert(res.asked === 0 && res.expired === 0 && (await reload(answering.id)).status === 'ON_SITE', 'после ответа анонс жив ещё 11 ч, старый вопрос его не гасит');
  res = await sweep(new Date(nowReal.getTime() + 12.5 * H));
  assert(res.asked === 1, 'через 12 ч после ответа спрашивает снова');
  await prisma.arrival.update({ where: { id: answering.id }, data: { status: 'COMPLETED' } });

  // ---- 4. Геозона: терминал (Хоргос) — вышел за радиус → «уехал»; обычный город — нет.
  const atTerminal = await prisma.arrival.create({
    data: { driverId: driver.id, pointId: khorgos.id, plannedAt: new Date(), plannedDay: day, arrivedAt: new Date(), lastConfirmedAt: new Date(), status: 'ON_SITE', anyCountry: true },
  });
  const inside = await leaveTerminalIfOutside(prisma, driver.id, { lat: Number(khorgos.lat) + 0.005, lng: Number(khorgos.lng) });
  assert(inside === false && (await reload(atTerminal.id)).status === 'ON_SITE', 'в пределах радиуса терминала — остаётся на месте');
  const outside = await leaveTerminalIfOutside(prisma, driver.id, { lat: 43.2389, lng: 76.8897 });
  assert(outside === true && (await reload(atTerminal.id)).status === 'COMPLETED', 'ушёл из геозоны терминала — анонс завершён автоматически');
  const inAlmaty = await prisma.arrival.create({
    data: { driverId: driver.id, pointId: almaty.id, plannedAt: new Date(), plannedDay: day, arrivedAt: new Date(), lastConfirmedAt: new Date(), status: 'ON_SITE', anyCountry: true },
  });
  const cityOutside = await leaveTerminalIfOutside(prisma, driver.id, { lat: 51.1694, lng: 71.4491 });
  assert(cityOutside === false && (await reload(inAlmaty.id)).status === 'ON_SITE', 'у обычного города геозоны нет — координаты анонс не гасят');

  console.log(`Готово: ${checks} проверок.`);
} finally {
  await cleanup();
  await prisma.$disconnect();
}
