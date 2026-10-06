import { WHATSAPP_TIMEOUT_MS, WhatsappCodeSender } from './whatsapp-code.sender';

describe('WhatsappCodeSender (задача 042, п.3)', () => {
  const OLD = { ...process.env };
  afterEach(() => {
    process.env = { ...OLD };
  });

  it('выключен, пока нет всех трёх ключей', () => {
    delete process.env.WHATSAPP_TOKEN;
    delete process.env.WHATSAPP_PHONE_ID;
    delete process.env.WHATSAPP_TEMPLATE;
    const sender = new WhatsappCodeSender();
    expect(sender.enabled()).toBe(false);
    process.env.WHATSAPP_TOKEN = 't';
    process.env.WHATSAPP_PHONE_ID = '123';
    expect(sender.enabled()).toBe(false);
    process.env.WHATSAPP_TEMPLATE = 'login_code';
    expect(sender.enabled()).toBe(true);
  });

  it('шлёт шаблон authentication: код в теле и в кнопке «Скопировать код», номер без «+»', async () => {
    process.env.WHATSAPP_TOKEN = 'secret-token';
    process.env.WHATSAPP_PHONE_ID = '555';
    process.env.WHATSAPP_TEMPLATE = 'login_code';
    const sender = new WhatsappCodeSender();
    sender.fetchFn = jest.fn().mockResolvedValue({ ok: true, status: 200, text: async () => '{}' });

    await sender.sendCode('+77010000001', '482913');

    const [url, init] = (sender.fetchFn as jest.Mock).mock.calls[0];
    expect(url).toBe('https://graph.facebook.com/v20.0/555/messages');
    expect(init.headers.Authorization).toBe('Bearer secret-token');
    const body = JSON.parse(init.body);
    expect(body).toMatchObject({ messaging_product: 'whatsapp', to: '77010000001', type: 'template' });
    expect(body.template).toMatchObject({ name: 'login_code', language: { code: 'ru' } });
    expect(body.template.components).toEqual([
      { type: 'body', parameters: [{ type: 'text', text: '482913' }] },
      { type: 'button', sub_type: 'url', index: '0', parameters: [{ type: 'text', text: '482913' }] },
    ]);
    expect(init.signal).toBeInstanceOf(AbortSignal);
  });

  it('отказ API (нет WhatsApp у номера и т.п.) — исключение, чтобы SmsService ушёл на SMS; номер в лог не попадает', async () => {
    process.env.WHATSAPP_TOKEN = 't';
    process.env.WHATSAPP_PHONE_ID = '1';
    process.env.WHATSAPP_TEMPLATE = 'x';
    const sender = new WhatsappCodeSender();
    sender.fetchFn = jest.fn().mockResolvedValue({ ok: false, status: 400, text: async () => '{"error":{"message":"+77010000001 not on WhatsApp"}}' });
    const warn = jest.spyOn((sender as any).logger, 'warn').mockImplementation(() => undefined);

    await expect(sender.sendCode('+77010000001', '1')).rejects.toThrow('WhatsApp request failed: 400');
    expect(JSON.stringify(warn.mock.calls)).not.toContain('77010000001');
  });

  it('таймаут запроса — 10 секунд', () => {
    expect(WHATSAPP_TIMEOUT_MS).toBe(10_000);
  });
});
