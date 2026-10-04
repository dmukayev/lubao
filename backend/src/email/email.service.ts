import * as crypto from 'crypto';
import { BadRequestException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { EmailProvider } from './email-provider';

const CODE_TTL_SECONDS = 10 * 60;
const MINUTE_LOCK_SECONDS = 60;
const HOUR_WINDOW_SECONDS = 60 * 60;
const MAX_PER_HOUR = 5;
const MAX_PER_HOUR_PER_IP = 20;
const MAX_WRONG_ATTEMPTS = 5;

/// Код на email для входа/регистрации логиста без пароля (задачи 006, 022).
/// Лимиты и защита — те же, что у SmsService (задача 006), только TTL кода
/// 10 минут вместо 5 (почта медленнее SMS) и отдельное неймспейс в Redis.
@Injectable()
export class EmailService {
  constructor(
    private readonly redis: RedisService,
    private readonly provider: EmailProvider,
  ) {}

  private minuteKey(email: string) {
    return `email:lock:${email}`;
  }
  private hourKey(email: string) {
    return `email:count:${email}`;
  }
  private codeKey(email: string) {
    return `email:code:${email}`;
  }
  private attemptsKey(email: string) {
    return `email:attempts:${email}`;
  }
  private ipHourKey(ip: string) {
    return `email:ip:${ip}`;
  }

  async requestCode(email: string, ip: string): Promise<void> {
    const client = this.redis.client;

    const locked = await client.get(this.minuteKey(email));
    if (locked) {
      throw new HttpException('Слишком частые запросы кода, попробуйте через минуту', HttpStatus.TOO_MANY_REQUESTS);
    }

    const hourCount = Number((await client.get(this.hourKey(email))) ?? 0);
    if (hourCount >= MAX_PER_HOUR) {
      throw new HttpException('Превышен лимит писем за час, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
    }

    const ipHourCount = Number((await client.get(this.ipHourKey(ip))) ?? 0);
    if (ipHourCount >= MAX_PER_HOUR_PER_IP) {
      throw new HttpException('Превышен лимит запросов кода с вашего адреса, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
    }

    const code = this.provider.generateCode();
    await Promise.all([
      client.set(this.codeKey(email), code, 'EX', CODE_TTL_SECONDS),
      client.del(this.attemptsKey(email)),
      client.set(this.minuteKey(email), '1', 'EX', MINUTE_LOCK_SECONDS),
      hourCount === 0 ? client.set(this.hourKey(email), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.hourKey(email)),
      ipHourCount === 0 ? client.set(this.ipHourKey(ip), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.ipHourKey(ip)),
    ]);

    await this.provider.sendCode(email, code);
  }

  /// Максимум 5 неверных попыток на код — на 6-й код сгорает, как у SMS.
  async verifyCode(email: string, code: string): Promise<boolean> {
    const client = this.redis.client;
    const stored = await client.get(this.codeKey(email));
    if (!stored) return false;

    const attempts = Number((await client.get(this.attemptsKey(email))) ?? 0);
    if (attempts >= MAX_WRONG_ATTEMPTS) {
      await client.del(this.codeKey(email));
      throw new BadRequestException('Слишком много попыток, запросите новый код');
    }

    const storedBuf = Buffer.from(stored);
    const codeBuf = Buffer.from(code);
    const match = storedBuf.length === codeBuf.length && crypto.timingSafeEqual(storedBuf, codeBuf);

    if (!match) {
      const ttl = await client.ttl(this.codeKey(email));
      await client.set(this.attemptsKey(email), attempts + 1, 'EX', ttl > 0 ? ttl : CODE_TTL_SECONDS);
      return false;
    }

    await Promise.all([client.del(this.codeKey(email)), client.del(this.attemptsKey(email))]);
    return true;
  }

  /// Письмо без кода — приглашение сотрудника (задача 025). Без лимитов
  /// requestCode: отправляется владельцем вручную, не по вводу пользователя.
  async sendMessage(email: string, subject: string, bodyText: string): Promise<void> {
    await this.provider.sendMessage(email, subject, bodyText);
  }
}
