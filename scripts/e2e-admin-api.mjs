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

console.log(`Готово: ${checks} проверок.`);
