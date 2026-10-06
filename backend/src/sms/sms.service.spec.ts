import { BadRequestException, HttpException } from '@nestjs/common';
import { SmsService } from './sms.service';
import { SmsProvider } from './sms-provider';

/// Минимальная in-memory замена ioredis-клиента — покрывает только методы,
/// которые реально использует SmsService (get/set/del/incr/ttl).
class FakeRedisClient {
  private store = new Map<string, { value: string; ttlSeconds: number }>();

  async get(key: string): Promise<string | null> {
    return this.store.get(key)?.value ?? null;
  }

  async set(key: string, value: string | number, _ex: 'EX', ttlSeconds: number): Promise<void> {
    this.store.set(key, { value: String(value), ttlSeconds });
  }

  async del(key: string): Promise<void> {
    this.store.delete(key);
  }

  async incr(key: string): Promise<number> {
    const current = Number(this.store.get(key)?.value ?? 0) + 1;
    const ttlSeconds = this.store.get(key)?.ttlSeconds ?? 3600;
    this.store.set(key, { value: String(current), ttlSeconds });
    return current;
  }

  async ttl(key: string): Promise<number> {
    return this.store.get(key)?.ttlSeconds ?? -1;
  }

  async expire(key: string, ttlSeconds: number): Promise<void> {
    const entry = this.store.get(key);
    if (entry) this.store.set(key, { ...entry, ttlSeconds });
  }
}

class FakeSmsProvider extends SmsProvider {
  generateCode(): string {
    return '1234';
  }
  sendCode = jest.fn().mockResolvedValue(undefined);
}

describe('SmsService', () => {
  let client: FakeRedisClient;
  let provider: FakeSmsProvider;
  let service: SmsService;

  beforeEach(() => {
    client = new FakeRedisClient();
    provider = new FakeSmsProvider();
    service = new SmsService({ client } as any, provider);
  });

  describe('verifyCode attempt limiting', () => {
    beforeEach(async () => {
      await service.requestCode('+77001112233', '1.1.1.1');
    });

    it('tolerates up to 5 wrong attempts, still returning false', async () => {
      for (let i = 0; i < 5; i++) {
        await expect(service.verifyCode('+77001112233', '0000')).resolves.toBe(false);
      }
    });

    it('burns the code on the 6th wrong attempt — even the correct code is then rejected', async () => {
      for (let i = 0; i < 5; i++) {
        await service.verifyCode('+77001112233', '0000');
      }
      await expect(service.verifyCode('+77001112233', '0000')).rejects.toThrow(BadRequestException);
      // код сгорел — верный код тоже больше не проходит, нужен новый
      await expect(service.verifyCode('+77001112233', '1234')).resolves.toBe(false);
    });

    it('accepts the correct code within the attempt budget and clears state', async () => {
      await service.verifyCode('+77001112233', '0000');
      await expect(service.verifyCode('+77001112233', '1234')).resolves.toBe(true);
      // после успеха — код одноразовый, повторная проверка не проходит
      await expect(service.verifyCode('+77001112233', '1234')).resolves.toBe(false);
    });

    it('returns false when no code was ever requested for the phone', async () => {
      await expect(service.verifyCode('+77009998877', '1234')).resolves.toBe(false);
    });

    it('20 parallel wrong attempts (race) still cap at 5 comparisons — old get→set logic let all 20 through (024 п.2)', async () => {
      const results = await Promise.allSettled(
        Array.from({ length: 20 }, () => service.verifyCode('+77001112233', '0000')),
      );
      const falses = results.filter((r) => r.status === 'fulfilled' && r.value === false).length;
      const rejected = results.filter((r) => r.status === 'rejected').length;
      // Атомарный INCR гарантирует: ровно 5 запросов получают attempts 1..5
      // (сравнение кода), остальные 15 видят attempts>5 и падают с 429/400
      // до какого-либо сравнения кода.
      expect(falses).toBe(5);
      expect(rejected).toBe(15);
      for (const r of results) {
        if (r.status === 'rejected') expect(r.reason).toBeInstanceOf(BadRequestException);
      }
    });
  });

  describe('per-phone rate limiting (regression)', () => {
    it('rejects a second code request within the same minute', async () => {
      await service.requestCode('+77001112233', '1.1.1.1');
      await expect(service.requestCode('+77001112233', '1.1.1.1')).rejects.toThrow(HttpException);
    });

    it('rejects the 6th request within an hour even across different minutes', async () => {
      // симулируем прошедшую минуту, удаляя лок между запросами
      for (let i = 0; i < 5; i++) {
        await service.requestCode('+77001112233', '1.1.1.1');
        await client.del('sms:lock:+77001112233');
      }
      await expect(service.requestCode('+77001112233', '1.1.1.1')).rejects.toThrow(HttpException);
    });
  });

  describe('per-IP verify rate limiting (024 п.2)', () => {
    it('rejects the 31st verify from the same IP within an hour, regardless of phone', async () => {
      await service.requestCode('+77001112233', '3.3.3.3');
      for (let i = 0; i < 30; i++) {
        await service.verifyCode('+77001112233', '0000', '3.3.3.3').catch(() => undefined);
      }
      await expect(service.verifyCode('+77001112233', '1234', '3.3.3.3')).rejects.toThrow(HttpException);
    });

    it('verify without an ip (e.g. older caller) is not rate-limited by IP', async () => {
      await service.requestCode('+77001112233', '4.4.4.4');
      for (let i = 0; i < 40; i++) {
        await service.verifyCode('+77001112233', '0000').catch(() => undefined);
      }
      // не 429 — просто код давно сгорел от собственного лимита попыток, не от IP
      await expect(service.verifyCode('+77001112233', '0000')).resolves.toBe(false);
    });
  });

  describe('per-IP rate limiting', () => {
    it('rejects the 21st request from the same IP within an hour, across different phones', async () => {
      for (let i = 0; i < 20; i++) {
        await service.requestCode(`+7700111${String(i).padStart(4, '0')}`, '2.2.2.2');
      }
      await expect(service.requestCode('+77009999999', '2.2.2.2')).rejects.toThrow(HttpException);
    });

    it('does not rate-limit a different IP', async () => {
      for (let i = 0; i < 20; i++) {
        await service.requestCode(`+7700111${String(i).padStart(4, '0')}`, '2.2.2.2');
      }
      await expect(service.requestCode('+77009999999', '3.3.3.3')).resolves.toEqual({ channel: 'sms' });
    });
  });
});

describe('SmsService — WhatsApp → SMS (задача 042, п.3)', () => {
  let client: FakeRedisClient;
  let provider: FakeSmsProvider;
  let whatsapp: { enabled: jest.Mock; sendCode: jest.Mock };
  let service: SmsService;

  beforeEach(() => {
    client = new FakeRedisClient();
    provider = new FakeSmsProvider();
    whatsapp = { enabled: jest.fn().mockReturnValue(true), sendCode: jest.fn().mockResolvedValue(undefined) };
    service = new SmsService({ client } as any, provider, whatsapp as any);
    jest.spyOn((service as any).logger, 'warn').mockImplementation(() => undefined);
  });

  it('WhatsApp настроен и отвечает — код уходит туда, SMS не тратится', async () => {
    const res = await service.requestCode('+77010000001', '1.1.1.1');
    expect(res).toEqual({ channel: 'whatsapp' });
    expect(whatsapp.sendCode).toHaveBeenCalledWith('+77010000001', '1234');
    expect(provider.sendCode).not.toHaveBeenCalled();
  });

  it('у номера нет WhatsApp / отказ API / таймаут — код тут же уходит SMS (фолбэк)', async () => {
    whatsapp.sendCode.mockRejectedValue(new Error('WhatsApp request failed: 400'));
    const res = await service.requestCode('+77010000001', '1.1.1.1');
    expect(res).toEqual({ channel: 'sms' });
    expect(provider.sendCode).toHaveBeenCalledWith('+77010000001', '1234');
    // Код один и тот же — какой бы канал ни сработал, ввести можно его.
    expect(await service.verifyCode('+77010000001', '1234')).toBe(true);
  });

  it('без ключей WhatsApp канал выключен — работает обычный SMS, WhatsApp даже не вызывается', async () => {
    whatsapp.enabled.mockReturnValue(false);
    expect(await service.requestCode('+77010000001', '1.1.1.1')).toEqual({ channel: 'sms' });
    expect(whatsapp.sendCode).not.toHaveBeenCalled();
  });

  it('«Не пришло? Отправить SMS»: тот же код SMS-ом сразу, без ожидания минуты', async () => {
    await service.requestCode('+77010000001', '1.1.1.1'); // → WhatsApp, минутный замок взведён
    await expect(service.requestCode('+77010000001', '1.1.1.1')).rejects.toBeInstanceOf(HttpException); // обычный повтор — по-прежнему 1/мин

    const res = await service.requestCode('+77010000001', '1.1.1.1', { channel: 'sms' });

    expect(res).toEqual({ channel: 'sms' });
    expect(provider.sendCode).toHaveBeenCalledTimes(1);
    expect(provider.sendCode).toHaveBeenCalledWith('+77010000001', '1234');
    expect(whatsapp.sendCode).toHaveBeenCalledTimes(1);
    expect(await service.verifyCode('+77010000001', '1234')).toBe(true);
  });

  it('SMS-повтор разрешён один раз: после SMS обычный минутный лимит снова действует', async () => {
    await service.requestCode('+77010000001', '1.1.1.1');
    await service.requestCode('+77010000001', '1.1.1.1', { channel: 'sms' });
    await expect(service.requestCode('+77010000001', '1.1.1.1', { channel: 'sms' })).rejects.toBeInstanceOf(HttpException);
  });

  it('SMS-повтор не обходит часовой лимит на номер', async () => {
    await service.requestCode('+77010000001', '1.1.1.1');
    await client.set('sms:count:+77010000001', 5, 'EX', 3600);
    await expect(service.requestCode('+77010000001', '1.1.1.1', { channel: 'sms' })).rejects.toThrow('Превышен лимит SMS за час');
  });

  it('channel=sms без предшествующего кода в WhatsApp — обычный запрос (SMS), без обхода лимитов', async () => {
    const res = await service.requestCode('+77010000009', '1.1.1.1', { channel: 'sms' });
    expect(res).toEqual({ channel: 'sms' });
    expect(whatsapp.sendCode).not.toHaveBeenCalled();
    await expect(service.requestCode('+77010000009', '1.1.1.1', { channel: 'sms' })).rejects.toBeInstanceOf(HttpException);
  });
});

describe('SmsService — SMS_MINUTE_LOCK_SECONDS для тестовых окружений (041, п.12)', () => {
  const OLD = { ...process.env };
  afterEach(() => {
    process.env = { ...OLD };
  });

  function make() {
    const client = new FakeRedisClient();
    const provider = new FakeSmsProvider();
    return { service: new SmsService({ client } as any, provider), provider };
  }

  it('SMS_MINUTE_LOCK_SECONDS=0 с консольным провайдером: второй код тому же номеру сразу, без минуты', async () => {
    process.env.SMS_MINUTE_LOCK_SECONDS = '0';
    delete process.env.SMS_PROVIDER;
    process.env.NODE_ENV = 'development';
    const { service, provider } = make();
    await service.requestCode('+77010000003', '1.1.1.1');
    await service.requestCode('+77010000003', '1.1.1.1');
    expect(provider.sendCode).toHaveBeenCalledTimes(2);
  });

  it('часовой лимит на номер при этом остаётся (5 в час)', async () => {
    process.env.SMS_MINUTE_LOCK_SECONDS = '0';
    process.env.NODE_ENV = 'development';
    const { service } = make();
    for (let i = 0; i < 5; i++) await service.requestCode('+77010000003', '1.1.1.1');
    await expect(service.requestCode('+77010000003', '1.1.1.1')).rejects.toThrow('Превышен лимит SMS за час');
  });

  it('в production и с реальным провайдером переменная игнорируется — минутный лимит действует', async () => {
    process.env.SMS_MINUTE_LOCK_SECONDS = '0';
    process.env.NODE_ENV = 'production';
    let { service } = make();
    await service.requestCode('+77010000003', '1.1.1.1');
    await expect(service.requestCode('+77010000003', '1.1.1.1')).rejects.toBeInstanceOf(HttpException);

    process.env.NODE_ENV = 'development';
    process.env.SMS_PROVIDER = 'mobizon';
    ({ service } = make());
    await service.requestCode('+77010000004', '1.1.1.1');
    await expect(service.requestCode('+77010000004', '1.1.1.1')).rejects.toBeInstanceOf(HttpException);
  });

  it('мусорное значение — обычная минута', async () => {
    process.env.SMS_MINUTE_LOCK_SECONDS = 'abc';
    process.env.NODE_ENV = 'development';
    const { service } = make();
    await service.requestCode('+77010000005', '1.1.1.1');
    await expect(service.requestCode('+77010000005', '1.1.1.1')).rejects.toBeInstanceOf(HttpException);
  });
});
