import { TelegramCodeSender } from './telegram-code.sender';

describe('TelegramCodeSender (задача 042, п.3)', () => {
  const OLD = { ...process.env };
  afterEach(() => {
    process.env = { ...OLD };
  });

  it('выключен без TELEGRAM_GATEWAY_TOKEN', () => {
    delete process.env.TELEGRAM_GATEWAY_TOKEN;
    expect(new TelegramCodeSender().enabled()).toBe(false);
    process.env.TELEGRAM_GATEWAY_TOKEN = 't';
    expect(new TelegramCodeSender().enabled()).toBe(true);
  });

  it('шлёт код в Gateway с номером в формате +7… и сроком 5 минут', async () => {
    process.env.TELEGRAM_GATEWAY_TOKEN = 'gw-token';
    const sender = new TelegramCodeSender();
    sender.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '{"ok":true,"result":{}}' });
    await sender.sendCode('+77010000001', '4829');
    const [url, init] = (sender.fetchFn as jest.Mock).mock.calls[0];
    expect(url).toBe('https://gateway.telegram.org/sendVerificationMessage');
    expect(init.headers.Authorization).toBe('Bearer gw-token');
    expect(JSON.parse(init.body)).toEqual({ phone_number: '+77010000001', code: '4829', ttl: 300 });
  });

  it('«нет Telegram на номере» (ok:false при HTTP 200) — ошибка, чтобы сработал следующий канал', async () => {
    process.env.TELEGRAM_GATEWAY_TOKEN = 'gw-token';
    const sender = new TelegramCodeSender();
    jest.spyOn((sender as any).logger, 'warn').mockImplementation(() => undefined);
    sender.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '{"ok":false,"error":"PHONE_NUMBER_NOT_FOUND"}' });
    await expect(sender.sendCode('+77010000001', '4829')).rejects.toThrow('PHONE_NUMBER_NOT_FOUND');
  });
});
