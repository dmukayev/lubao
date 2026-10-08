import { TelegramLoginService } from './telegram-login.service';

/// Redis в памяти с теми командами, что нужны сервису (Lua consume — эмулируем).
function fakeRedis() {
  const store = new Map<string, string>();
  const client: any = {
    incr: jest.fn(async (k: string) => {
      const v = Number(store.get(k) ?? 0) + 1;
      store.set(k, String(v));
      return v;
    }),
    expire: jest.fn(),
    set: jest.fn(async (k: string, v: string) => store.set(k, v)),
    get: jest.fn(async (k: string) => store.get(k) ?? null),
    del: jest.fn(async (k: string) => store.delete(k)),
    ttl: jest.fn(async () => 200),
    eval: jest.fn(async (_script: string, _n: number, key: string) => {
      const raw = store.get(key);
      if (!raw) return null;
      const state = JSON.parse(raw);
      if (state.status === 'READY') store.set(key, JSON.stringify({ ...state, status: 'USED' }));
      return raw;
    }),
  };
  return { store, redis: { client } as any };
}

describe('TelegramLoginService (050)', () => {
  const env = { ...process.env };
  beforeEach(() => {
    process.env.TELEGRAM_BOT_TOKEN = 'tkn';
    process.env.TELEGRAM_BOT_USERNAME = 'lubao_bot';
    process.env.TELEGRAM_WEBHOOK_SECRET = 'sec';
  });
  afterEach(() => (process.env = { ...env }));

  function setup(knownUser: unknown = null) {
    const { store, redis } = fakeRedis();
    const prisma: any = { user: { findFirst: jest.fn().mockResolvedValue(knownUser) } };
    const svc = new TelegramLoginService(redis, prisma);
    const sent: any[] = [];
    svc.fetchFn = jest.fn(async (_url: any, init: any) => {
      sent.push(JSON.parse(init.body));
      return { ok: true, status: 200 } as any;
    });
    return { svc, store, sent };
  }
  const msg = (extra: Record<string, unknown>) => ({ message: { chat: { id: 55 }, from: { id: 777, language_code: 'kk' }, ...extra } });

  it('старт: nonce и ссылка t.me/<бот>?start=<nonce>; без токена — кнопки нет (404)', async () => {
    const { svc } = setup();
    const r = await svc.start('1.1.1.1');
    expect(r.url).toBe(`https://t.me/lubao_bot?start=${r.nonce}`);
    expect(r.nonce).toMatch(/^[A-Za-z0-9_-]{32}$/);
    delete process.env.TELEGRAM_BOT_TOKEN;
    await expect(svc.start('1.1.1.1')).rejects.toMatchObject({ response: { code: 'TELEGRAM_DISABLED' } });
  });

  it('свой контакт → вход готов; повтор того же nonce → 409', async () => {
    const { svc, sent } = setup();
    const { nonce } = await svc.start('1.1.1.1', 'iPhone', 'ios');
    await expect(svc.consume(nonce)).resolves.toEqual({ status: 'PENDING' });
    await svc.handleUpdate(msg({ text: `/start ${nonce}` }));
    expect(sent[0].reply_markup.keyboard[0][0]).toMatchObject({ request_contact: true, text: 'Нөмірмен бөлісу' });
    await svc.handleUpdate(msg({ contact: { phone_number: '77010000123', user_id: 777 } }));
    await expect(svc.consume(nonce)).resolves.toMatchObject({ status: 'READY', phone: '+77010000123', telegramUserId: '777', deviceName: 'iPhone' });
    await expect(svc.consume(nonce)).rejects.toMatchObject({ response: { code: 'NONCE_USED' } });
  });

  it('чужой (пересланный) контакт отклоняется — вход не готов', async () => {
    const { svc, sent } = setup();
    const { nonce } = await svc.start('1.1.1.1');
    await svc.handleUpdate(msg({ text: `/start ${nonce}` }));
    await svc.handleUpdate(msg({ contact: { phone_number: '77019999999', user_id: 12345 } }));
    expect(sent[1].text).toMatch(/Өз нөміріңіз/);
    await expect(svc.consume(nonce)).resolves.toEqual({ status: 'PENDING' });
  });

  it('истёкший nonce — 410 в приложении и «ссылка устарела» в боте', async () => {
    const { svc, sent } = setup();
    await expect(svc.consume('nope-nope-nope-nope-nope')).rejects.toMatchObject({ response: { code: 'NONCE_EXPIRED' } });
    await svc.handleUpdate(msg({ text: '/start nope-nope-nope-nope-nope' }));
    expect(sent[0].text).toMatch(/мерзімі өтті/);
  });

  it('повторный вход: Telegram уже привязан к водителю — без контакта, сразу готово', async () => {
    const { svc } = setup({ phone: '+77010000123' });
    const { nonce } = await svc.start('1.1.1.1');
    await svc.handleUpdate(msg({ text: `/start ${nonce}` }));
    await expect(svc.consume(nonce)).resolves.toMatchObject({ status: 'READY', phone: '+77010000123' });
  });

  it('webhook: только с верным секретом', () => {
    const { svc } = setup();
    expect(svc.webhookSecretOk('sec')).toBe(true);
    expect(svc.webhookSecretOk('nope')).toBe(false);
    expect(svc.webhookSecretOk(undefined)).toBe(false);
  });

  it('лимит nonce с одного IP', async () => {
    const { svc } = setup();
    for (let i = 0; i < 20; i++) await svc.start('9.9.9.9');
    await expect(svc.start('9.9.9.9')).rejects.toMatchObject({ response: { code: 'TOO_MANY_REQUESTS' } });
  });
});
