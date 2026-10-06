import { SmtpEmailProvider } from './smtp-email.provider';

describe('SmtpEmailProvider (задача 042, п.2)', () => {
  const OLD = { ...process.env };
  afterEach(() => {
    process.env = { ...OLD };
  });

  function setup() {
    const sendMail = jest.fn().mockResolvedValue({});
    const provider = new SmtpEmailProvider();
    provider.createTransport = jest.fn().mockReturnValue({ sendMail }) as never;
    return { provider, sendMail };
  }

  it('код — случайные 6 цифр с ведущими нулями', () => {
    const { provider } = setup();
    for (let i = 0; i < 50; i++) expect(provider.generateCode()).toMatch(/^\d{6}$/);
  });

  it('письмо с кодом уходит от SMTP_FROM на языке получателя', async () => {
    process.env.SMTP_FROM = 'Lubao <no-reply@lubao.kz>';
    const { provider, sendMail } = setup();

    await provider.sendCode('logist@example.com', '654321', 'en');

    expect(sendMail).toHaveBeenCalledWith({
      from: 'Lubao <no-reply@lubao.kz>',
      to: 'logist@example.com',
      subject: 'Your Lubao verification code',
      text: expect.stringContaining('654321'),
    });
  });

  it('транспорт создаётся один раз и переиспользуется', async () => {
    const { provider } = setup();
    await provider.sendMessage('a@example.com', 's', 't');
    await provider.sendMessage('b@example.com', 's', 't');
    expect(provider.createTransport).toHaveBeenCalledTimes(1);
  });

  it('сбой SMTP пробрасывается вызывающему (приглашение его глотает сознательно), в логе нет адреса', async () => {
    const { provider, sendMail } = setup();
    sendMail.mockRejectedValue(new Error('connection refused'));
    const logger = jest.spyOn((provider as any).logger, 'error').mockImplementation(() => undefined);

    await expect(provider.sendMessage('secret@example.com', 's', 'код 123456')).rejects.toThrow('connection refused');
    expect(JSON.stringify(logger.mock.calls)).not.toContain('secret@example.com');
    expect(JSON.stringify(logger.mock.calls)).not.toContain('123456');
  });
});
