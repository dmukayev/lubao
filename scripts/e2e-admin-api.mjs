// Задача 034, сценарии админки 10 / 13 / 14 — на уровне API.
//
// Playwright/Flutter-Web-семантика для UI админки и `chromedriver` на этой
// машине не заведены (см. итог 034), поэтому здесь проверяется то, что
// бэкенд отдаёт админке: данные сводки согласованы со списками, жалоба
// проходит «Новые → В работе → Закрытые», карточки открываются, а правка
// имени водителя не трогает госномер. Это НЕ проверка интерфейса.
//
// Использование: E2E_API_URL=http://localhost:3100 node scripts/e2e-admin-api.mjs
const BASE = process.env.E2E_API_URL ?? 'http://localhost:3100';
const ADMIN = { email: 'e2e-admin@lubao-test.kz', password: 'E2eLubao2026!' };

let checks = 0;
function ok(name) {
  checks++;
  console.log(`ok ${name}`);
}
function assert(cond, name, detail = '') {
  if (!cond) {
    console.error(`FAIL ${name} ${detail}`);
    process.exit(1);
  }
  ok(name);
}

async function api(method, path, { token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    // не JSON — оставим null
  }
  return { status: res.status, json, text };
}

const login = await api('POST', '/auth/admin/login', {
  body: { ...ADMIN, deviceName: 'e2e', platform: 'web' },
});
assert(login.status === 201 || login.status === 200, 'вход админа', `status=${login.status} ${login.text.slice(0, 120)}`);
const token = login.json.accessToken;
const get = (path) => api('GET', path, { token });

// ---- 10. Сводка: плитки совпадают со списками --------------------------------
const stats = (await get('/admin/stats')).json;
const attention = (await get('/admin/attention')).json;
const [drivers, companies, complaintCounts, queue] = await Promise.all([
  get('/admin/drivers').then((r) => r.json),
  get('/admin/companies').then((r) => r.json),
  get('/admin/complaints/counts').then((r) => r.json),
  get('/admin/verification/queue').then((r) => r.json),
]);
assert(stats.drivers === drivers.total, 'плитка «Водители» = число строк списка', `${stats.drivers} vs ${drivers.total}`);
assert(stats.companies === companies.total, 'плитка «Компании» = число строк списка', `${stats.companies} vs ${companies.total}`);
assert(
  stats.openComplaints === complaintCounts.newCount + complaintCounts.inReviewCount,
  'плитка «Открытые жалобы» = новые + в работе',
);
assert(attention.openComplaints === stats.openComplaints, '«Требует внимания»: жалобы совпадают с плиткой');
assert(
  stats.pendingDocs === queue.reduce((sum, s) => sum + s.pendingCount, 0),
  'плитка «Документы на проверке» = сумма очереди проверки',
);

// ---- Чёрный список: телефон при регистрации (039, п.2) ----------------------
const attentionBefore = (await get('/admin/attention')).json.blacklistMatches;
const BLOCKED_PHONE = '+77010000099';
const refData = (await api('GET', '/reference-data')).json;
await api('POST', '/auth/phone/request-code', { body: { phone: BLOCKED_PHONE } });
const reg = await api('POST', '/auth/phone/verify', { body: { phone: BLOCKED_PHONE, code: '1111', deviceName: 'e2e', platform: 'ios' } });
assert(reg.status < 300, 'номер из чёрного списка проходит SMS-вход (аккаунт не блокируется молча)', `status=${reg.status} ${reg.text.slice(0, 120)}`);
const newDriverToken = reg.json.accessToken;
const setup = await api('PATCH', '/drivers/me', {
  token: newDriverToken,
  body: {
    fullName: 'Нурлан Блоков',
    homeCityId: refData.cities[0].id,
    anyCountry: true,
    directionCountryIds: [],
    permitIds: [],
    bodyTypeId: refData.bodyTypes[0].id,
    plateNumber: '999ZZZ99',
    capacityTons: 20,
  },
});
assert(setup.status < 300, 'профиль водителя с заблокированным номером создаётся', `status=${setup.status} ${setup.text.slice(0, 160)}`);
const attentionAfter = (await get('/admin/attention')).json.blacklistMatches;
assert(attentionAfter === attentionBefore + 1, '«Требует внимания»: совпадение с чёрным списком появилось', `${attentionBefore} → ${attentionAfter}`);
const blockedDriver = (await get('/admin/drivers?search=%2B77010000099')).json.items.find((d) => d.phone === BLOCKED_PHONE);
assert(!!blockedDriver, 'зарегистрированный по номеру из ЧС водитель виден в админке');
const blockedCard = (await get(`/admin/drivers/${blockedDriver.id}`)).json;
assert(blockedCard.blockedByPhone === true, 'карточка админа: явный признак blockedByPhone (039, п.24)', JSON.stringify(blockedCard.blockedByPhone));
const respond = await api('POST', `/cargos/11111111-1111-4111-8111-111111111001/responses`, { token: newDriverToken, body: {} });
assert(respond.status === 403, 'водитель с заблокированным номером не может откликаться (403)', `status=${respond.status}`);

// ---- 13. Жалоба: Новые → В работе (не исчезает) → решение → Закрытые --------
const findE2e = (list) => list.find((c) => String(c.reason).startsWith('E2E:'));
const fresh = findE2e((await get('/admin/complaints?tab=NEW')).json);
assert(!!fresh, 'жалоба видна во вкладке «Новые»');

const assigned = await api('POST', `/admin/complaints/${fresh.id}/assign`, { token });
assert(assigned.status < 300, 'взять жалобу в работу', `status=${assigned.status}`);
assert(!findE2e((await get('/admin/complaints?tab=NEW')).json), 'из «Новых» жалоба ушла');
assert(!!findE2e((await get('/admin/complaints?tab=IN_REVIEW')).json), 'в «В работе» жалоба не исчезла');
const inReviewCounts = (await get('/admin/complaints/counts')).json;
assert(inReviewCounts.inReviewCount >= 1, 'счётчик «В работе» учитывает жалобу');

const noNote = await api('PATCH', `/admin/complaints/${fresh.id}`, { token, body: { resolution: 'DISMISSED', resolutionNote: '' } });
assert(noNote.status === 400, 'решение без ответа автору отклоняется (400)');
const resolved = await api('PATCH', `/admin/complaints/${fresh.id}`, {
  token,
  body: { resolution: 'DISMISSED', resolutionNote: 'E2E: проверено, нарушений нет' },
});
assert(resolved.status < 300, 'решение с ответом принято', `status=${resolved.status} ${resolved.text.slice(0, 120)}`);
assert(!!findE2e((await get('/admin/complaints?tab=CLOSED')).json), 'жалоба во вкладке «Закрытые»');

// ---- 14. Карточки открываются; правка имени не трогает госномер -------------
const firstId = async (path) => (await get(path)).json.items?.[0]?.id;
for (const [label, list, card] of [
  ['водителя', '/admin/drivers', (id) => `/admin/drivers/${id}`],
  ['компании', '/admin/companies', (id) => `/admin/companies/${id}`],
  ['груза', '/admin/cargos', (id) => `/admin/cargos/${id}`],
]) {
  const id = await firstId(list);
  assert(!!id, `в списке есть хотя бы одна запись (${label})`);
  const res = await get(card(id));
  assert(res.status === 200 && res.json && typeof res.json === 'object', `карточка ${label} открывается (200, JSON)`, `status=${res.status}`);
}

const e2eDriver = drivers.items.find((d) => d.phone === '+77010000001');
assert(!!e2eDriver, 'сидовый водитель найден');
const before = (await get(`/admin/drivers/${e2eDriver.id}`)).json;
const platesOf = (card) => (card.vehicles ?? []).map((v) => `${v.kind}:${v.plateNumber ?? ''}`).sort().join('|');
const platesBefore = platesOf(before);
assert(platesBefore.includes('TRACTOR:E2E001KZ'), 'у водителя есть тягач с госномером E2E001KZ', platesBefore);

const rename = await api('PATCH', `/admin/drivers/${e2eDriver.id}`, {
  token,
  body: { fullName: 'Эдуард Переименованный', reason: 'E2E: проверка правки имени' },
});
assert(rename.status < 300, 'правка имени водителя принята', `status=${rename.status} ${rename.text.slice(0, 160)}`);
const after = (await get(`/admin/drivers/${e2eDriver.id}`)).json;
assert(after.fullName === 'Эдуард Переименованный', 'имя изменилось');
assert(platesOf(after) === platesBefore, 'госномер тягача и прицепа не изменились после правки имени', `${platesBefore} → ${platesOf(after)}`);

// Возвращаем имя — повторный прогон не зависит от порядка.
await api('PATCH', `/admin/drivers/${e2eDriver.id}`, {
  token,
  body: { fullName: 'Эдуард Тестов', reason: 'E2E: откат' },
});

// ---- 040. Точка → город --------------------------------------------------------
const ref040 = (await api('GET', '/reference-data')).json;
const terminal = ref040.points.find((p) => p.kind === 'TERMINAL');
assert(!!terminal && terminal.radiusM === 10000 && typeof terminal.lat === 'number', 'Хоргос — терминал с геозоной (kind=TERMINAL, радиус 10 км (042 п.0), координаты числами)', JSON.stringify(terminal));
assert(ref040.points.filter((p) => p.kind === 'CITY').length >= 20, 'справочник точек: областные центры РК — города (kind=CITY)');
assert(
  ref040.cities.filter((c) => c.lat != null).every((c) => typeof c.lat === 'number' && typeof c.lng === 'number'),
  'координаты городов в справочнике — числа, а не строки Decimal (иначе клиент не разберёт справочник)',
);
assert(ref040.cities.some((c) => c.lat != null), 'у городов-точек есть координаты');
const almatyPoint = ref040.points.find((p) => p.name.ru === 'Алматы');
const astanaPoint = ref040.points.find((p) => p.name.ru === 'Астана');
assert(!!almatyPoint && !!astanaPoint, 'в справочнике есть точки Алматы и Астана');

// Админка точек: терминал без геозоны не заводится; город ↔ терминал; выключение.
const zharkent = ref040.cities.find((c) => c.code === 'KZ-ZHETYSU-ZHARKENT');
const pointName = { kk: 'E2E Жаркент', ru: 'E2E Жаркент', zh: 'E2E Zharkent', en: 'E2E Zharkent' };
const terminalNoGeo = await api('POST', '/admin/reference/points', { token, body: { cityId: zharkent.id, kind: 'TERMINAL', name: pointName } });
assert(terminalNoGeo.status === 400, 'терминал без координат и радиуса отклоняется (400)', `status=${terminalNoGeo.status}`);
const cityPoint = await api('POST', '/admin/reference/points', { token, body: { cityId: zharkent.id, name: pointName } });
assert(cityPoint.status === 201 && cityPoint.json.kind === 'CITY' && cityPoint.json.radiusM === null, 'точка-город создаётся без геозоны', JSON.stringify(cityPoint.json));
const patchNoRadius = await api('PATCH', `/admin/reference/points/${cityPoint.json.id}`, { token, body: { kind: 'TERMINAL', reason: 'E2E' } });
assert(patchNoRadius.status === 400, 'город → терминал без радиуса отклоняется', `status=${patchNoRadius.status}`);
const patchTerminal = await api('PATCH', `/admin/reference/points/${cityPoint.json.id}`, { token, body: { kind: 'TERMINAL', radiusM: 2500, reason: 'E2E' } });
assert(patchTerminal.status < 300, 'город → терминал с радиусом принимается', `status=${patchTerminal.status} ${patchTerminal.text.slice(0, 120)}`);
const patchBack = await api('PATCH', `/admin/reference/points/${cityPoint.json.id}`, { token, body: { kind: 'CITY', isActive: false, reason: 'E2E: убираем тестовую точку' } });
assert(patchBack.status < 300, 'терминал → город и выключение точки принимаются');

// Разрез сводки по городам: Алматы — анонс D6 и груз 6.
const byCity = (await get('/admin/stats/by-city')).json;
const almatyRow = byCity.find((r) => r.pointId === almatyPoint.id);
assert(!!almatyRow && almatyRow.arrivals >= 1 && almatyRow.cargos >= 1, 'сводка по городам: у Алматы есть анонсы и грузы', JSON.stringify(almatyRow));

// Груз без города погрузки опубликовать нельзя.
const ownerLogin = await api('POST', '/auth/company/login', { body: { email: 'e2e-owner@lubao-test.cn', password: 'E2eLubao2026!', deviceName: 'e2e', platform: 'ios' } });
const ownerToken = ownerLogin.json.accessToken;
const refCountry = ref040.countries.find((c) => c.code === 'KZ');
const cargoBody = { destinationCountryId: refCountry.id, bodyTypeId: ref040.bodyTypes[0].id, price: 100, currency: 'USD', readyDate: '2030-01-01' };
const noPoint = await api('POST', '/cargos', { token: ownerToken, body: cargoBody });
assert(noPoint.status === 400, 'груз без города погрузки отклоняется (400)', `status=${noPoint.status}`);
const badPoint = await api('POST', '/cargos', { token: ownerToken, body: { ...cargoBody, pointId: cityPoint.json.id } });
assert(badPoint.status === 400, 'груз с выключенным городом отклоняется (400)', `status=${badPoint.status}`);

// Лента водителя на сервере и несколько анонсов (D6 — «свободен в Алматы», код 1111).
const D6 = '+77010000008';
await api('POST', '/auth/phone/request-code', { body: { phone: D6 } });
const d6Login = await api('POST', '/auth/phone/verify', { body: { phone: D6, code: '1111', deviceName: 'e2e', platform: 'ios' } });
assert(d6Login.status < 300, 'вход водителя D6 по SMS-коду', `status=${d6Login.status}`);
const d6 = d6Login.json.accessToken;
const feed = await api('GET', '/cargos?limit=2&offset=0', { token: d6 });
assert(Array.isArray(feed.json.items) && feed.json.items.length === 2 && feed.json.total >= 7 && feed.json.limit === 2, 'лента: страница {items,total,limit} вместо голого массива', JSON.stringify(Object.keys(feed.json)));
assert(feed.json.originCityId === almatyPoint.cityId && feed.json.originSource === 'arrival', 'лента считается от города анонса (Алматы)', `${feed.json.originCityId} ${feed.json.originSource}`);
assert(feed.json.items[0].id === '11111111-1111-4111-8111-111111111006' && feed.json.items[0].pickupRank === 0, 'первым — груз из Алматы (город анонса = город погрузки)', feed.json.items[0].id);
assert(feed.json.items[0].allowPartial === true, 'груз 6 помечен «можно догрузом»');
const page2 = await api('GET', '/cargos?limit=2&offset=2', { token: d6 });
assert(page2.json.items.length === 2 && !page2.json.items.some((c) => feed.json.items.map((x) => x.id).includes(c.id)), 'вторая страница ленты без повторов');
assert(page2.json.items.every((c) => c.pickupRank >= 0), 'каждая карточка ленты несёт ранг города');
const hint = await api('GET', '/cargos/11111111-1111-4111-8111-111111111006/partial-hint', { token: d6 });
assert(hint.status === 200 && hint.json.hint === null, 'подсказка догруза: без активной сделки её нет');

const mineBefore = (await api('GET', '/arrivals/me', { token: d6 })).json;
assert(mineBefore.arrivals.length === 1 && mineBefore.arrival.id === mineBefore.arrivals[0].id, '/arrivals/me: один анонс D6 (текущий = единственный)');
const notOnSite = await api('POST', '/arrivals/still-looking', { token: d6, body: {} });
assert(notOnSite.status === 404, '«Да, ещё ищу» без анонса «на месте» — 404', `status=${notOnSite.status}`);
const second = await api('POST', '/arrivals', {
  token: d6,
  body: { pointId: astanaPoint.id, plannedAt: new Date(Date.now() + 2 * 86400000).toISOString(), plannedDay: new Date(Date.now() + 2 * 86400000).toISOString().slice(0, 10), anyCountry: true },
});
assert(second.status < 300, 'второй анонс (Астана, через 2 дня) создаётся рядом с первым', `status=${second.status} ${second.text.slice(0, 120)}`);
const mineTwo = (await api('GET', '/arrivals/me', { token: d6 })).json;
assert(mineTwo.arrivals.length === 2, 'у D6 два активных анонса', `${mineTwo.arrivals.length}`);
const checkin = await api('POST', '/arrivals/checkin', { token: d6, body: { arrivalId: mineBefore.arrival.id } });
assert(checkin.status < 300 && checkin.json.status === 'ON_SITE' && !!checkin.json.lastConfirmedAt, '«Я на месте» по id анонса: ON_SITE + lastConfirmedAt', JSON.stringify(checkin.json));
const confirmed = await api('POST', '/arrivals/still-looking', { token: d6, body: {} });
assert(confirmed.status < 300 && confirmed.json.status === 'ON_SITE', '«Да, ещё ищу» подтверждает анонс «на месте»');
const mineAfter = (await api('GET', '/arrivals/me', { token: d6 })).json;
assert(mineAfter.arrival.status === 'ON_SITE' && mineAfter.arrivals[0].status === 'ON_SITE', 'текущий анонс — тот, где водитель на месте, он первым в списке');
const cancelSecond = await api('POST', '/arrivals/cancel', { token: d6, body: { arrivalId: second.json.id } });
assert(cancelSecond.status < 300, 'отмена второго анонса по id');
const mineEnd = (await api('GET', '/arrivals/me', { token: d6 })).json;
assert(mineEnd.arrivals.length === 1 && mineEnd.arrival.status === 'ON_SITE', 'остался один анонс — тот, где водитель на месте (D6 виден логисту в Алматы)');

// 042 п.3: каналы кода входа из админки — порядок/вкл без релиза.
const channelsAdmin = await get('/admin/login-code-channels');
assert(channelsAdmin.status === 200 && channelsAdmin.json.map((c) => c.id).join() === 'whatsapp,telegram,sms' && channelsAdmin.json.every((c) => c.configured), 'каналы кода: три, по умолчанию все настроены (e2e — консольные)', JSON.stringify(channelsAdmin.json));
const setChannels = (value) => api('PATCH', '/admin/settings/loginCodeChannels', { token, body: { value: JSON.stringify(value), reason: 'E2E' } });
assert((await setChannels([{ id: 'telegram', enabled: true }, { id: 'whatsapp', enabled: false }, { id: 'sms', enabled: true }])).status < 300, 'админ меняет порядок и выключает WhatsApp');
const publicChannels = await api('GET', '/auth/phone/channels');
assert(publicChannels.json.channels.join() === 'telegram,sms', 'водитель видит только включённые, в порядке из админки', JSON.stringify(publicChannels.json));
const viaDefault = await api('POST', '/auth/phone/request-code', { body: { phone: '+77010000060' } });
assert(viaDefault.status < 300 && viaDefault.json.channel === 'telegram', 'код уходит первым включённым (Telegram)', JSON.stringify(viaDefault.json));
const viaOff = await api('POST', '/auth/phone/request-code', { body: { phone: '+77010000061', channel: 'whatsapp' } });
assert(viaOff.status < 300 && viaOff.json.channel === 'telegram', 'выключенный WhatsApp не используется даже по выбору', JSON.stringify(viaOff.json));
assert((await api('PATCH', '/admin/settings/loginCodeChannels', { token, body: { value: '[{"id":"viber","enabled":true}]', reason: 'E2E' } })).status === 400, 'неизвестный канал админка не сохраняет');
assert((await setChannels([{ id: 'whatsapp', enabled: true }, { id: 'telegram', enabled: true }, { id: 'sms', enabled: true }])).status < 300, 'настройка каналов возвращена (остальные сценарии)');

console.log(`Готово: ${checks} проверок.`);
