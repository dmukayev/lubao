import * as crypto from 'crypto';
import { BadRequestException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { SmsProvider } from './sms-provider';

const CODE_TTL_SECONDS = 5 * 60;
const MINUTE_LOCK_SECONDS = 60;
const HOUR_WINDOW_SECONDS = 60 * 60;
const MAX_PER_HOUR = 5;
const MAX_PER_HOUR_PER_IP = 20;
const MAX_WRONG_ATTEMPTS = 5;

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
  private attemptsKey(phone: string) {
    return `sms:attempts:${phone}`;
  }
  private ipHourKey(ip: string) {
    return `sms:ip:${ip}`;
  }

  /// Генерирует и отправляет код, предварительно проверив лимиты:
  /// не больше 1 SMS в минуту и 5 в час на номер, не больше 20 запросов
  /// в час на IP (защита от массового перебора номеров с одного источника).
  async requestCode(phone: string, ip: string): Promise<void> {
    const client = this.redis.client;

    const locked = await client.get(this.minuteKey(phone));
    if (locked) {
      throw new HttpException('Слишком частые запросы кода, попробуйте через минуту', HttpStatus.TOO_MANY_REQUESTS);
    }

    const hourCount = Number((await client.get(this.hourKey(phone))) ?? 0);
    if (hourCount >= MAX_PER_HOUR) {
      throw new HttpException('Превышен лимит SMS за час, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
    }

    const ipHourCount = Number((await client.get(this.ipHourKey(ip))) ?? 0);
    if (ipHourCount >= MAX_PER_HOUR_PER_IP) {
      throw new HttpException('Превышен лимит запросов кода с вашего адреса, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
    }

    const code = this.provider.generateCode();
    await Promise.all([
      client.set(this.codeKey(phone), code, 'EX', CODE_TTL_SECONDS),
      client.del(this.attemptsKey(phone)),
      client.set(this.minuteKey(phone), '1', 'EX', MINUTE_LOCK_SECONDS),
      hourCount === 0 ? client.set(this.hourKey(phone), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.hourKey(phone)),
      ipHourCount === 0 ? client.set(this.ipHourKey(ip), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.ipHourKey(ip)),
    ]);

    await this.provider.sendCode(phone, code);
  }

  /// Сверяет код и удаляет его (одноразовый). true — код верный и ещё
  /// не истёк (5 минут). Максимум 5 неверных попыток на код — на 6-й код
  /// сгорает и требуется новый (защита от перебора 4-значного кода).
  async verifyCode(phone: string, code: string): Promise<boolean> {
    const client = this.redis.client;
    const stored = await client.get(this.codeKey(phone));
    if (!stored) return false;

    const attempts = Number((await client.get(this.attemptsKey(phone))) ?? 0);
    if (attempts >= MAX_WRONG_ATTEMPTS) {
      await client.del(this.codeKey(phone));
      throw new BadRequestException('Слишком много попыток, запросите новый код');
    }

    const storedBuf = Buffer.from(stored);
    const codeBuf = Buffer.from(code);
    const match = storedBuf.length === codeBuf.length && crypto.timingSafeEqual(storedBuf, codeBuf);

    if (!match) {
      const ttl = await client.ttl(this.codeKey(phone));
      await client.set(this.attemptsKey(phone), attempts + 1, 'EX', ttl > 0 ? ttl : CODE_TTL_SECONDS);
      return false;
    }

    await Promise.all([client.del(this.codeKey(phone)), client.del(this.attemptsKey(phone))]);
    return true;
  }
}
