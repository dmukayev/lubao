import { BadRequestException, HttpException } from '@nestjs/common';
import { EmailService } from './email.service';
import { EmailProvider } from './email-provider';

/// Минимальная in-memory замена ioredis-клиента, как в sms.service.spec.ts —
/// EmailService использует тот же набор методов, другой неймспейс ключей.
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

class FakeEmailProvider extends EmailProvider {
  generateCode(): string {
    return '123456';
  }
  sendCode = jest.fn().mockResolvedValue(undefined);
  sendMessage = jest.fn().mockResolvedValue(undefined);
}

describe('EmailService', () => {
  let client: FakeRedisClient;
  let provider: FakeEmailProvider;
  let service: EmailService;

  beforeEach(() => {
    client = new FakeRedisClient();
    provider = new FakeEmailProvider();
    service = new EmailService({ client } as any, provider);
  });

  describe('verifyCode attempt limiting', () => {
    beforeEach(async () => {
      await service.requestCode('owner@yidao-logistics.cn', '1.1.1.1');
    });

    it('tolerates up to 5 wrong attempts, still returning false', async () => {
      for (let i = 0; i < 5; i++) {
        await expect(service.verifyCode('owner@yidao-logistics.cn', '000000')).resolves.toBe(false);
      }
    });

    it('burns the code on the 6th wrong attempt — even the correct code is then rejected', async () => {
      for (let i = 0; i < 5; i++) {
        await service.verifyCode('owner@yidao-logistics.cn', '000000');
      }
      await expect(service.verifyCode('owner@yidao-logistics.cn', '000000')).rejects.toThrow(BadRequestException);
      await expect(service.verifyCode('owner@yidao-logistics.cn', '123456')).resolves.toBe(false);
    });

    it('accepts the correct code within the attempt budget and clears state', async () => {
      await service.verifyCode('owner@yidao-logistics.cn', '000000');
      await expect(service.verifyCode('owner@yidao-logistics.cn', '123456')).resolves.toBe(true);
      await expect(service.verifyCode('owner@yidao-logistics.cn', '123456')).resolves.toBe(false);
    });

    it('returns false when no code was ever requested for the email', async () => {
      await expect(service.verifyCode('nobody@example.com', '123456')).resolves.toBe(false);
    });
  });

  describe('per-email rate limiting (regression)', () => {
    it('rejects a second code request within the same minute', async () => {
      await service.requestCode('owner@yidao-logistics.cn', '1.1.1.1');
      await expect(service.requestCode('owner@yidao-logistics.cn', '1.1.1.1')).rejects.toThrow(HttpException);
    });

    it('rejects the 6th request within an hour even across different minutes', async () => {
      for (let i = 0; i < 5; i++) {
        await service.requestCode('owner@yidao-logistics.cn', '1.1.1.1');
        await client.del('email:lock:owner@yidao-logistics.cn');
      }
      await expect(service.requestCode('owner@yidao-logistics.cn', '1.1.1.1')).rejects.toThrow(HttpException);
    });
  });

  describe('per-IP rate limiting', () => {
    it('rejects the 21st request from the same IP within an hour, across different emails', async () => {
      for (let i = 0; i < 20; i++) {
        await service.requestCode(`user${i}@example.com`, '2.2.2.2');
      }
      await expect(service.requestCode('user999@example.com', '2.2.2.2')).rejects.toThrow(HttpException);
    });

    it('does not rate-limit a different IP', async () => {
      for (let i = 0; i < 20; i++) {
        await service.requestCode(`user${i}@example.com`, '2.2.2.2');
      }
      await expect(service.requestCode('user999@example.com', '3.3.3.3')).resolves.toBeUndefined();
    });
  });
});
