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
const otherCategoryId = ref040.cargoCategories.find((c) => c.code === 'OTHER').id;
const cargoBody = { destinationCountryId: refCountry.id, bodyTypeId: ref040.bodyTypes[0].id, categoryId: otherCategoryId, price: 100, currency: 'USD', readyDate: '2030-01-01' };
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
// 049 п.1: догруз за флагом (по умолчанию выкл.) — пометка не отдаётся; включили — видна.
assert(feed.json.items[0].allowPartial === false && (await api('GET', '/reference-data')).json.partialLoadsEnabled === false, 'догруз выключен по умолчанию: бейджа нет');
assert((await api('PATCH', '/admin/settings/partialLoadsEnabled', { token, body: { value: 'true', reason: 'E2E 049' } })).status < 300, 'админ включает догруз');
await new Promise((r) => setTimeout(r, 5200)); // кэш флага в ленте — 5 с
assert((await api('GET', '/cargos?limit=2&offset=0', { token: d6 })).json.items[0].allowPartial === true, 'догруз включён — груз 6 «можно догрузом»');
assert((await api('PATCH', '/admin/settings/partialLoadsEnabled', { token, body: { value: 'false', reason: 'E2E 049' } })).status < 300, 'админ выключает догруз обратно');
await new Promise((r) => setTimeout(r, 5200));
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

// 042 п.1, п.7: push-токен регистрируется (мок — без Firebase) и снимается только владельцем.
const fakeToken = `e2e-fcm-token-${Date.now()}`;
const pushReg = await api('POST', '/notifications/device-tokens', { token: d6, body: { token: fakeToken, platform: 'FCM' } });
assert(pushReg.status < 300, 'водитель регистрирует push-токен (FCM)', `status=${pushReg.status}`);
const unreg = await api('DELETE', `/notifications/device-tokens/${encodeURIComponent(fakeToken)}`, { token: d6 });
assert(unreg.status < 300, 'водитель снимает свой push-токен при выходе', `status=${unreg.status}`);

// 042 п.3: каналы кода входа из админки — порядок/вкл без релиза.
const channelsAdmin = await get('/admin/login-code-channels');
assert(channelsAdmin.status === 200 && channelsAdmin.json.map((c) => c.id).join() === 'telegram_bot,whatsapp,telegram,sms' && channelsAdmin.json.every((c) => c.configured), 'каналы входа: бот Telegram (050) и три канала кода, по умолчанию все настроены (e2e — консольные/заглушка бота)', JSON.stringify(channelsAdmin.json));
const setChannels = (value) => api('PATCH', '/admin/settings/loginCodeChannels', { token, body: { value: JSON.stringify(value), reason: 'E2E' } });
assert((await setChannels([{ id: 'telegram', enabled: true }, { id: 'whatsapp', enabled: false }, { id: 'sms', enabled: true }])).status < 300, 'админ меняет порядок и выключает WhatsApp');
const publicChannels = await api('GET', '/auth/phone/channels');
assert(publicChannels.json.channels.join() === 'telegram,sms', 'водитель видит только включённые, в порядке из админки', JSON.stringify(publicChannels.json));
assert(publicChannels.json.methods.join() === 'telegram_bot,telegram,sms', '050: кнопки входа — бот Telegram первым, затем каналы кода', JSON.stringify(publicChannels.json.methods));
const viaDefault = await api('POST', '/auth/phone/request-code', { body: { phone: '+77010000060' } });
assert(viaDefault.status < 300 && viaDefault.json.channel === 'telegram', 'код уходит первым включённым (Telegram)', JSON.stringify(viaDefault.json));
const viaOff = await api('POST', '/auth/phone/request-code', { body: { phone: '+77010000061', channel: 'whatsapp' } });
assert(viaOff.status < 300 && viaOff.json.channel === 'telegram', 'выключенный WhatsApp не используется даже по выбору', JSON.stringify(viaOff.json));
assert((await api('PATCH', '/admin/settings/loginCodeChannels', { token, body: { value: '[{"id":"viber","enabled":true}]', reason: 'E2E' } })).status === 400, 'неизвестный канал админка не сохраняет');
assert((await setChannels([{ id: 'whatsapp', enabled: true }, { id: 'telegram', enabled: true }, { id: 'sms', enabled: true }])).status < 300, 'настройка каналов возвращена (остальные сценарии)');

// 043 п.4: ручной чёрный список — добавить (значение только маской, в журнале
// без исходного), увидеть в списке, снять с причиной; неизвестный тип — 400.
// ИИН — чувствительный (маска), госномер маской не скрывается (он и так на машине).
const BL_IIN = `9901013${String(Date.now()).slice(-5)}`;
const blAdd = await api('POST', '/admin/blacklist', { token, body: { type: 'IIN', value: BL_IIN, reason: 'E2E: ручная блокировка' } });
assert(blAdd.status < 300 && blAdd.json.valueMasked && !blAdd.json.valueMasked.includes(BL_IIN), 'админ добавляет ИИН в чёрный список, ответ — маской', JSON.stringify(blAdd.json));
assert((await api('POST', '/admin/blacklist', { token, body: { type: 'PASSPORT', value: 'X', reason: 'E2E' } })).status === 400, 'неизвестный тип идентификатора — 400');
assert((await api('POST', '/admin/blacklist', { token, body: { type: 'IIN', value: BL_IIN } })).status === 400, 'без причины не добавляется');
const blActive = (await get('/admin/blacklist?active=true')).json;
assert(blActive.some((r) => r.id === blAdd.json.id && r.reason === 'E2E: ручная блокировка'), 'запись видна в активном списке');
assert(!JSON.stringify(blActive).includes(BL_IIN), 'в списке нет исходного значения');
const blAudit = (await get('/admin/audit?entityType=BlockedIdentifier&limit=20')).json;
assert(!JSON.stringify(blAudit).includes(BL_IIN), 'в журнале действий нет исходного значения');
assert((await api('POST', `/admin/blacklist/${blAdd.json.id}/lift`, { token, body: { reason: 'E2E: снято' } })).status < 300, 'админ снимает блокировку с причиной');
assert(!(await get('/admin/blacklist?active=true')).json.some((r) => r.id === blAdd.json.id), 'снятая запись ушла из активных');
assert((await get('/admin/blacklist?active=false')).json.some((r) => r.id === blAdd.json.id && r.liftedAt && r.liftReason === 'E2E: снято'), 'снятая видна с «Показать снятые»');

// 043 п.1: удаление аккаунта — водитель удаляет себя, ПДн обезличены,
// сессия больше не работает, тот же номер регистрируется заново как новый.
const DEL_PHONE = '+77010000098';
await api('POST', '/auth/phone/request-code', { body: { phone: DEL_PHONE } });
const delReg = (await api('POST', '/auth/phone/verify', { body: { phone: DEL_PHONE, code: '1111', deviceName: 'e2e', platform: 'ios' } })).json;
const delSetup = await api('PATCH', '/drivers/me', {
  token: delReg.accessToken,
  body: { fullName: 'Удаляемый Тестов', homeCityId: refData.cities[0].id, anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId: refData.bodyTypes[0].id, plateNumber: '098DEL02', capacityTons: 20 },
});
assert(delSetup.status < 300, 'водитель для удаления создан', `status=${delSetup.status}`);
const delDriverId = (await api('GET', '/auth/me', { token: delReg.accessToken })).json.driver.id;
// 043 п.2: согласие на ПДн — новый пользователь его ещё не давал, чужая версия текста не принимается.
assert((await api('GET', '/auth/me', { token: delReg.accessToken })).json.user.pdConsentRequired === true, 'новому водителю нужно согласие на ПДн');
assert((await api('POST', '/auth/me/pd-consent', { token: delReg.accessToken, body: { version: '2000-01-01' } })).status === 400, 'согласие на старую редакцию текста — 400');
assert((await api('POST', '/auth/me/pd-consent', { token: delReg.accessToken, body: { version: '2026-10-08' } })).status === 200, 'согласие на текущую редакцию принято');
assert((await api('GET', '/auth/me', { token: delReg.accessToken })).json.user.pdConsentRequired === false, 'после согласия экран больше не нужен');
// 043 п.11: телефоны — только по нажатию. В ленте и карточке номера нет;
// непроверенный водитель получает номер после отклика; лимит и contact_events — на сервере.
const KZ_CARGO = '11111111-1111-4111-8111-111111111008';
const feedJson = (await api('GET', '/cargos?limit=200', { token: delReg.accessToken })).json;
assert(feedJson.limit === 50, 'лента: не больше 50 на страницу', `limit=${feedJson.limit}`);
assert(!/contactPhone|\+7\d{10}/.test(JSON.stringify(feedJson)), 'в ленте нет телефонов');
const kzCard = (await api('GET', `/cargos/${KZ_CARGO}`, { token: delReg.accessToken })).json;
assert(kzCard.hasContactPhone === true && !('contactPhone' in kzCard), 'в карточке груза — только «номер есть», без самого номера', JSON.stringify(Object.keys(kzCard)));
const lockedContact = await api('POST', `/cargos/${KZ_CARGO}/contact`, { token: delReg.accessToken, body: { type: 'CALL' } });
assert(lockedContact.status === 403 && lockedContact.json.code === 'RESPOND_FIRST', 'непроверенный водитель без отклика номер не получает', `status=${lockedContact.status}`);
assert((await api('POST', `/cargos/${KZ_CARGO}/responses`, { token: delReg.accessToken, body: {} })).status < 300, 'водитель откликается «Готов взять»');
const openContact = await api('POST', `/cargos/${KZ_CARGO}/contact`, { token: delReg.accessToken, body: { type: 'CALL' } });
assert(openContact.status === 200 && /^\+\d{10,15}$/.test(openContact.json.phone ?? ''), 'после отклика — номер по нажатию', `status=${openContact.status}`);
const kzOwner = (await api('POST', '/auth/company/login', { body: { email: 'e2e-owner@lubao-test.kz', password: 'E2eLubao2026!', deviceName: 'e2e', platform: 'ios' } })).json.accessToken;
const arrivalsJson = (await api('GET', '/arrivals', { token: kzOwner })).json;
assert(Array.isArray(arrivalsJson) && arrivalsJson.every((a) => !('phone' in a)), '«Кто свободен»: без телефонов', JSON.stringify(arrivalsJson[0] ?? {}).slice(0, 160));
const driverContact = await api('POST', `/drivers/${delDriverId}/contact`, { token: kzOwner, body: { type: 'CALL', cargoId: KZ_CARGO } });
assert(driverContact.status === 200 && driverContact.json.phone === DEL_PHONE, 'проверенная компания получает номер водителя по нажатию', `status=${driverContact.status}`);
const newCo = await api('POST', '/auth/company/register', { body: { email: `e2e-unverified-${Date.now()}@lubao-test.kz`, password: 'E2eLubao2026!', ownerName: 'Тест Непроверенный', companyName: 'Unverified LLC', countryId: refData.countries[0].id, offerVersion: '2026-10-08' } });
assert(newCo.status < 300, 'новая компания с офертой регистрируется', `status=${newCo.status}`);
const unverifiedContact = await api('POST', `/drivers/${delDriverId}/contact`, { token: newCo.json.accessToken, body: { type: 'CALL' } });
assert(unverifiedContact.status === 403 && unverifiedContact.json.code === 'COMPANY_NOT_VERIFIED', 'непроверенная компания номер водителя не получает', `status=${unverifiedContact.status}`);
const contactAdmin = (await get(`/admin/drivers/${delDriverId}`)).json;
assert((contactAdmin.stats?.calls ?? 0) >= 2, 'звонки записаны в contact_events (карточка админки)', JSON.stringify(contactAdmin.stats ?? {}));

const delRes = await api('DELETE', '/auth/me', { token: delReg.accessToken });
assert(delRes.status === 200, 'DELETE /auth/me — аккаунт удалён', `status=${delRes.status} ${delRes.text.slice(0, 120)}`);
assert((await api('GET', '/auth/me', { token: delReg.accessToken })).status === 401, 'после удаления токен не работает');
assert((await api('POST', '/auth/refresh', { body: { refreshToken: delReg.refreshToken } })).status >= 400, 'refresh-токен отозван');
const delCard = (await get(`/admin/drivers/${delDriverId}`)).json;
assert(delCard.fullName === '—' && !delCard.user?.phone && !JSON.stringify(delCard).includes('098DEL02') && !JSON.stringify(delCard).includes('Удаляемый'), 'в админке водитель обезличен: без имени, телефона и госномера', JSON.stringify({ fullName: delCard.fullName, phone: delCard.user?.phone }));
await api('POST', '/auth/phone/request-code', { body: { phone: DEL_PHONE } });
const reReg2 = await api('POST', '/auth/phone/verify', { body: { phone: DEL_PHONE, code: '1111', deviceName: 'e2e', platform: 'ios' } });
assert(reReg2.status < 300 && reReg2.json.user?.id !== delReg.user?.id, 'тот же номер входит как новый аккаунт', `status=${reReg2.status}`);

// 043 п.2: компания регистрируется только с принятой текущей офертой.
const cnId = refData.countries.find((c) => c.code === 'CN')?.id ?? refData.countries[0].id;
const noOffer = await api('POST', '/auth/company/register', { body: { email: `e2e-nooffer-${Date.now()}@lubao-test.kz`, password: 'E2eLubao2026!', ownerName: 'Тест Офертов', companyName: 'No Offer LLC', countryId: cnId } });
assert(noOffer.status === 400, 'без оферты компания не регистрируется', `status=${noOffer.status}`);
const oldOffer = await api('POST', '/auth/company/register', { body: { email: `e2e-oldoffer-${Date.now()}@lubao-test.kz`, password: 'E2eLubao2026!', ownerName: 'Тест Офертов', companyName: 'Old Offer LLC', countryId: cnId, offerVersion: '2000-01-01' } });
assert(oldOffer.status === 400, 'старая редакция оферты не принимается', `status=${oldOffer.status}`);

// 048: профили кузова — груз «цистерна, 20 000 л» виден цистерне и не виден тенту;
// у цистерны без литров груз не публикуется; сломанные поля админка не сохраняет.
const ref048 = (await api('GET', '/reference-data')).json;
const tankType = ref048.bodyTypes.find((b) => b.code === 'TANK');
const tentType = ref048.bodyTypes.find((b) => b.code === 'TENT');
assert(tankType?.profile === 'TANK' && tankType.fields.some((f) => f.key === 'liters') && !tankType.fields.some((f) => f.key === 'palletsEuro'), 'у цистерны свои поля (литры), без паллет');
const almaty048 = ref048.points.find((p) => p.name.ru === 'Алматы');
async function newDriver(phone, bodyTypeId, extra) {
  await api('POST', '/auth/phone/request-code', { body: { phone } });
  const reg = (await api('POST', '/auth/phone/verify', { body: { phone, code: '1111', deviceName: 'e2e', platform: 'ios' } })).json;
  const prof = await api('PATCH', '/drivers/me', { token: reg.accessToken, body: { fullName: 'Тест Профилев', homeCityId: almaty048.cityId, anyCountry: true, directionCountryIds: [], permitIds: [], bodyTypeId, ...extra } });
  return { token: reg.accessToken, prof };
}
const tankDriver = await newDriver('+77010000096', tankType.id, { preferredSpecs: { liters: 30000, product: 'FOOD' } });
assert(tankDriver.prof.status < 300 && tankDriver.prof.json.preferredSpecs?.liters === 30000 && tankDriver.prof.json.preferredCapacityTons == null, 'водитель цистерны: «основа» — литры и продукт, без тоннажа', JSON.stringify(tankDriver.prof.json.preferredSpecs));
const tentDriver = await newDriver('+77010000095', tentType.id, { capacityTons: 20 });
const kzOwner048 = (await api('POST', '/auth/company/login', { body: { email: 'e2e-owner@lubao-test.kz', password: 'E2eLubao2026!', deviceName: 'e2e', platform: 'ios' } })).json.accessToken;
const tankCargoBody = { pointId: almaty048.id, destinationCountryId: ref048.countries.find((c) => c.code === 'KZ').id, bodyTypeId: tankType.id, categoryId: otherCategoryId, price: 900, currency: 'USD', readyDate: '2030-02-01' };
const noLiters = await api('POST', '/cargos', { token: kzOwner048, body: { ...tankCargoBody, specs: { cargoProduct: 'FOOD' } } });
assert(noLiters.status === 400 && noLiters.json.code === 'INVALID_SPECS', 'груз для цистерны без литров не публикуется', `status=${noLiters.status}`);
const tankCargo = await api('POST', '/cargos', { token: kzOwner048, body: { ...tankCargoBody, specs: { cargoProduct: 'FOOD', cargoLiters: 20000 } } });
assert(tankCargo.status < 300 && tankCargo.json.specs?.cargoLiters === 20000, 'груз «цистерна, 20 000 л, пищевое» опубликован', `status=${tankCargo.status}`);
const feedIds = async (token) => (await api('GET', '/cargos?limit=50', { token })).json.items.map((c) => c.id);
assert((await feedIds(tankDriver.token)).includes(tankCargo.json.id), 'груз виден водителю цистерны');
assert(!(await feedIds(tentDriver.token)).includes(tankCargo.json.id), 'груз не виден водителю тента');
const fit = (await api('GET', `/cargos/fit-count?bodyTypeIds=${tankType.id}&specs=${encodeURIComponent(JSON.stringify({ cargoProduct: 'FOOD', cargoLiters: 20000 }))}`, { token: kzOwner048 })).json;
assert(typeof fit.count === 'number', '«подходит N водителям» считает по профилю', JSON.stringify(fit));
const badFields = await api('PATCH', `/admin/reference/body-types/${tankType.id}/profile`, { token, body: { profile: 'TANK', fields: [{ key: '1x', kind: 'text' }], reason: 'E2E' } });
assert(badFields.status === 400 && badFields.json.code === 'INVALID_BODY_FIELDS', 'сломанные поля типа кузова админка не сохраняет', `status=${badFields.status}`);

// 046: отмена после загрузки → у логиста в карточке водителя «после загрузки 1», рейтинг ниже;
// после «В пути» — только запросом: повтор 409, вторая сторона оспаривает, админ закрывает спор.
const kz046 = ref048.countries.find((c) => c.code === 'KZ').id;
const cancelDriver = await newDriver('+77010000094', tentType.id, { capacityTons: 20 });
async function dealFor(price) {
  const cargo = await api('POST', '/cargos', { token: kzOwner048, body: { pointId: almaty048.id, destinationCountryId: kz046, bodyTypeId: tentType.id, categoryId: otherCategoryId, price, currency: 'USD', readyDate: '2030-03-01' } });
  const resp = await api('POST', `/cargos/${cargo.json.id}/responses`, { token: cancelDriver.token, body: {} });
  const sel = await api('PATCH', `/responses/${resp.json.id}`, { token: kzOwner048, body: { status: 'SELECTED' } });
  const deal = (await api('GET', '/deals/mine', { token: cancelDriver.token })).json.find((d) => d.cargoId === cargo.json.id);
  return { cargoId: cargo.json.id, dealId: deal?.id, ok: cargo.status < 300 && resp.status < 300 && sel.status < 300 && !!deal };
}
async function adminAdvance(dealId, ...statuses) {
  for (const status of statuses) {
    const r = await api('PATCH', `/admin/deals/${dealId}/status`, { token, body: { status, reason: 'E2E 046' } });
    if (r.status >= 300) return r;
  }
  return { status: 200 };
}
const d1 = await dealFor(1046);
assert(d1.ok, 'сделка для отмены создана (отклик → выбран)');
assert((await adminAdvance(d1.dealId, 'CONFIRMED_BY_DRIVER', 'LOADED')).status < 300, 'сделка доведена до «Загружен»');
const noReason = await api('PATCH', `/deals/${d1.dealId}/cancel`, { token: cancelDriver.token, body: { reasonCode: 'OTHER' } });
assert(noReason.status === 400, '«Другое» без текста не принимается', `status=${noReason.status}`);
const c1 = await api('PATCH', `/deals/${d1.dealId}/cancel`, { token: cancelDriver.token, body: { reasonCode: 'VEHICLE_BREAKDOWN' } });
assert(c1.status < 300 && c1.json.status === 'CANCELLED' && c1.json.cancelStage === 'AFTER_LOAD' && c1.json.faultSide === 'SELF', 'отмена после загрузки: этап AFTER_LOAD, своя вина', JSON.stringify({ s: c1.status, st: c1.json?.cancelStage, f: c1.json?.faultSide }));
const respList = (await api('GET', `/cargos/${d1.cargoId}/responses`, { token: kzOwner048 })).json;
const stats1 = respList.find((r) => r.dealId === d1.dealId)?.cancelStats;
assert(stats1?.cancelled === 1 && stats1?.afterLoad === 1, 'у логиста в карточке водителя «отменил 1 · после загрузки 1»', JSON.stringify(stats1));
const me046 = (await api('GET', '/drivers/me', { token: cancelDriver.token })).json;
// 049 п.9: отзывов ещё нет — среднее 0 («—»), штраф ×3 копится до первого отзыва.
const card046 = (await get(`/admin/drivers/${me046.id}`)).json;
assert(Number(me046.ratingAvg) === 0 && me046.ratingCount === 0 && card046.pendingPenalty === 3, 'отмена по своей вине после загрузки: штраф ×3 копится до первого отзыва', JSON.stringify({ r: me046.ratingAvg, c: me046.ratingCount, p: card046.pendingPenalty }));
const complaint = await api('POST', `/deals/${d1.dealId}/complaint`, { token: kzOwner048, body: { reason: 'E2E 046: отмена с грузом в машине' } });
assert(complaint.status < 300, '«Пожаловаться» после отмены с грузом — жалоба по сделке', `status=${complaint.status}`);
assert((await api('POST', `/deals/${d1.dealId}/complaint`, { token: kzOwner048, body: { reason: 'повтор' } })).status === 409, 'вторая открытая жалоба на ту же сделку — 409');
const companyCard = (await api('GET', `/cargos/${d1.cargoId}`, { token: cancelDriver.token })).json;
assert(companyCard.companyCancelStats && typeof companyCard.companyCancelStats.cancelled === 'number', 'водителю в карточке груза — статистика отмен компании', JSON.stringify(companyCard.companyCancelStats));

const d2 = await dealFor(2046);
assert(d2.ok && (await adminAdvance(d2.dealId, 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT')).status < 300, 'вторая сделка доведена до «В пути»');
const req = await api('PATCH', `/deals/${d2.dealId}/cancel`, { token: kzOwner048, body: { reasonCode: 'TERMS_CHANGED' } });
assert(req.status < 300 && req.json.status === 'CANCEL_REQUESTED' && req.json.cancelRequest?.byRole === 'COMPANY', 'после «В пути» отмена — запрос второй стороне', JSON.stringify({ s: req.status, st: req.json?.status }));
assert((await api('PATCH', `/deals/${d2.dealId}/cancel`, { token: cancelDriver.token, body: { reasonCode: 'TERMS_CHANGED' } })).status === 409, 'пока ждём ответа, новую отмену не начать');
assert((await api('POST', `/deals/${d2.dealId}/cancel-request/confirm`, { token: kzOwner048 })).status === 403, 'инициатор сам себе отмену не подтверждает');
const disp = await api('POST', `/deals/${d2.dealId}/cancel-request/dispute`, { token: cancelDriver.token, body: { reason: 'E2E 046: груз везу, условия не менялись' } });
assert(disp.status < 300 && disp.json.status === 'DISPUTED', 'водитель оспорил — спор', `status=${disp.status}`);
const att046 = (await get('/admin/attention')).json;
assert((att046.disputedDeals ?? []).some((d) => d.dealId === d2.dealId && d.disputeReason?.startsWith('E2E 046')), '«Требует внимания»: спор с обеими позициями', JSON.stringify(att046.disputedDeals?.[0] ?? {}));
const resolved046 = await api('POST', `/admin/deals/${d2.dealId}/resolve-dispute`, { token, body: { resolution: 'CANCEL', guilty: 'COMPANY', reason: 'E2E 046' } });
assert(resolved046.status < 300 && resolved046.json.status === 'CANCELLED' && resolved046.json.faultSide === 'SELF' && resolved046.json.cancelStage === 'IN_TRANSIT', 'админ закрыл спор: отменено, виновата компания', JSON.stringify({ s: resolved046.status, f: resolved046.json?.faultSide }));
assert(!(await get('/admin/attention')).json.disputedDeals.some((d) => d.dealId === d2.dealId), 'закрытый спор ушёл из «Требует внимания»');
const coCard = (await get(`/admin/companies/${companyCard.companyId}`)).json;
assert((coCard.cancelStats?.selfFault ?? 0) >= 1 && coCard.cancellations.some((c) => c.dealId === d2.dealId && c.atFault), 'в админке у компании — отмены с причинами и виной', JSON.stringify(coCard.cancelStats));

// 047: категория обязательна; км и ₸/км по городам; цены по маршрутам в админке.
const ref047 = (await api('GET', '/reference-data')).json;
assert(ref047.cargoCategories.length >= 8 && ref047.cargoCategories.some((c) => c.code === 'CONSTRUCTION' && c.name.zh), 'справочник категорий груза (4 языка) в /reference-data');
const astana047 = ref047.points.find((p) => p.name.ru === 'Астана');
const almatyCity047 = ref047.cities.find((c) => c.name.ru === 'Алматы');
const routeBody = { pointId: astana047.id, destinationCountryId: kz046, destinationCityId: almatyCity047.id, bodyTypeId: tentType.id, price: 1230000, currency: 'KZT', readyDate: '2030-05-01', weightKg: 20000 };
const noCategory = await api('POST', '/cargos', { token: kzOwner048, body: routeBody });
assert(noCategory.status === 400 && /CATEGORY_REQUIRED|categoryId/.test(noCategory.text), 'груз без категории не публикуется', `status=${noCategory.status}`);
const constructionId = ref047.cargoCategories.find((c) => c.code === 'CONSTRUCTION').id;
const routed = await api('POST', '/cargos', { token: kzOwner048, body: { ...routeBody, categoryId: constructionId } });
assert(routed.status < 300 && routed.json.categoryId === constructionId && routed.json.distanceKm === 1230 && routed.json.pricePerKm === 1000, 'Астана → Алматы: 1 230 км, 1 000 ₸/км', JSON.stringify({ s: routed.status, km: routed.json?.distanceKm, perKm: routed.json?.pricePerKm }));
const feedRow = (await api('GET', '/cargos?limit=100', { token: tentDriver.token })).json.items.find((c) => c.id === routed.json.id);
assert(feedRow && feedRow.distanceKm === 1230 && feedRow.pricePerKm === 1000, 'в ленте у груза км и ₸/км', JSON.stringify(feedRow ?? {}).slice(0, 120));
const hint047 = await api('GET', `/cargos/market-hint?pointId=${astana047.id}&destinationCountryId=${kz046}&destinationCityId=${almatyCity047.id}&weightKg=20000`, { token: kzOwner048 });
assert(hint047.status === 200 && hint047.json.market === null, 'мало точек по маршруту — подсказки «рынок» нет', JSON.stringify(hint047.json));
const prices = await get('/admin/route-prices');
assert(prices.status === 200 && Array.isArray(prices.json), 'админка: «Цены по маршрутам» отвечает', `status=${prices.status}`);
const csv = await api('GET', '/admin/route-prices.csv', { token });
assert(csv.status === 200 && csv.text.includes('median_kzt_per_km'), 'админка: выгрузка CSV', `status=${csv.status}`);

console.log(`Готово: ${checks} проверок.`);
