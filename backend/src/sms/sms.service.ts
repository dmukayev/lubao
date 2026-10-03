import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { SmsProvider } from './sms-provider';

const CODE_TTL_SECONDS = 5 * 60;
const MINUTE_LOCK_SECONDS = 60;
const HOUR_WINDOW_SECONDS = 60 * 60;
const MAX_PER_HOUR = 5;

@Injectable()
export class SmsService {
  constructor(
    private readonly redis: RedisService,
    private readonly provider: SmsProvider,
  ) {}

  private minuteKey(phone: string) {
    return `sms:lock:${phone}`;
  }
  private hourKey(phone: string) {
    return `sms:count:${phone}`;
  }
  private codeKey(phone: string) {
    return `sms:code:${phone}`;
  }

  /// Генерирует и отправляет код, предварительно проверив лимиты:
  /// не больше 1 SMS в минуту и 5 в час на номер.
  async requestCode(phone: string): Promise<void> {
    const client = this.redis.client;

    const locked = await client.get(this.minuteKey(phone));
    if (locked) {
      throw new HttpException('Слишком частые запросы кода, попробуйте через минуту', HttpStatus.TOO_MANY_REQUESTS);
    }

    const hourCount = Number((await client.get(this.hourKey(phone))) ?? 0);
    if (hourCount >= MAX_PER_HOUR) {
      throw new HttpException('Превышен лимит SMS за час, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
    }

    const code = this.provider.generateCode();
    await Promise.all([
      client.set(this.codeKey(phone), code, 'EX', CODE_TTL_SECONDS),
      client.set(this.minuteKey(phone), '1', 'EX', MINUTE_LOCK_SECONDS),
      hourCount === 0 ? client.set(this.hourKey(phone), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.hourKey(phone)),
    ]);

    await this.provider.sendCode(phone, code);
  }

  /// Сверяет код и удаляет его (одноразовый). true — код верный и ещё
  /// не истёк (5 минут).
  async verifyCode(phone: string, code: string): Promise<boolean> {
    const client = this.redis.client;
    const stored = await client.get(this.codeKey(phone));
    if (!stored || stored !== code) return false;
    await client.del(this.codeKey(phone));
    return true;
  }
}
