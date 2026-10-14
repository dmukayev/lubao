// Решения админа для второго устройства полного прогона: интерфейс админки
// в Chrome уже проверен на первом (он не зависит от телефона), а сценариям
// «после решений админа» (logist_publish) нужна одобренная компания — делаем
// то же, что 11-verification.spec.ts, но через API, за секунды.
//
// Использование: E2E_API_URL=http://localhost:3100 node scripts/e2e-admin-approve.mjs
const BASE = process.env.E2E_API_URL ?? 'http://localhost:3100';
const ADMIN = { email: 'e2e-admin@lubao-test.kz', password: 'E2eLubao2026!' };
const COMPANY = 'Urumqi Test Logistics';

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
  } catch {}
  return { status: res.status, json, text };
}

function fail(msg) {
  console.error(`FAIL ${msg}`);
  process.exit(1);
}

const login = await api('POST', '/auth/admin/login', { body: { ...ADMIN, deviceName: 'e2e', platform: 'web' } });
if (login.status >= 300) fail(`вход админа: ${login.status}`);
const token = login.json.accessToken;

const list = await api('GET', `/admin/companies?search=${encodeURIComponent('Urumqi')}`, { token });
const company = list.json?.items?.find((c) => c.name === COMPANY);
if (!company) fail(`нет компании ${COMPANY}`);

// Документы компании — одобрить, как админ в очереди проверки.
const detail = await api('GET', `/admin/companies/${company.id}`, { token });
const docs = [...(detail.json?.documents ?? []), ...(detail.json?.verificationDocuments ?? [])];
for (const d of docs.filter((d) => d.status === 'PENDING')) {
  const r = await api('PATCH', `/admin/verification-documents/${d.id}`, { token, body: { status: 'APPROVED' } });
  if (r.status >= 300) fail(`документ ${d.id}: ${r.status} ${r.text.slice(0, 120)}`);
}
const verify = await api('PATCH', `/admin/companies/${company.id}/verify`, {
  token,
  body: { isVerified: true, reason: 'E2E: одобрено через API (админка проверена на первом устройстве)', force: true },
});
if (verify.status >= 300) fail(`подтверждение компании: ${verify.status} ${verify.text.slice(0, 160)}`);
console.log(`ok компания «${COMPANY}» подтверждена (документов одобрено: ${docs.filter((d) => d.status === 'PENDING').length})`);
