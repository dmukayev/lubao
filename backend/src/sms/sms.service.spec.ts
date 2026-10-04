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
      await expect(service.requestCode('+77009999999', '3.3.3.3')).resolves.toBeUndefined();
    });
  });
});
