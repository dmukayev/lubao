import * as crypto from 'crypto';
import { BadRequestException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { Locale } from '@prisma/client';
import { EmailProvider } from './email-provider';
import { EmailKind, renderEmail } from './email-messages';

const CODE_TTL_SECONDS = 10 * 60;
const MINUTE_LOCK_SECONDS = 60;
const HOUR_WINDOW_SECONDS = 60 * 60;
const MAX_PER_HOUR = 5;
const MAX_PER_HOUR_PER_IP = 20;
const MAX_WRONG_ATTEMPTS = 5;
const MAX_VERIFY_PER_HOUR_PER_IP = 30;

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
  private verifyIpHourKey(ip: string) {
    return `email:verify-ip:${ip}`;
  }

  async requestCode(email: string, ip: string, locale?: Locale): Promise<void> {
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

    await this.provider.sendCode(email, code, locale);
  }

  /// Максимум 5 неверных попыток на код — на 6-й код сгорает, как у SMS.
  /// Счётчик инкрементируется атомарно до сравнения кода — иначе
  /// параллельный перебор обходит лимит (ревью 006, 024 п.2; то же
  /// исправление, что и в SmsService.verifyCode — см. комментарий там).
  async verifyCode(email: string, code: string, ip?: string): Promise<boolean> {
    const client = this.redis.client;

    if (ip) {
      const verifyIpCount = await client.incr(this.verifyIpHourKey(ip));
      if (verifyIpCount === 1) await client.expire(this.verifyIpHourKey(ip), HOUR_WINDOW_SECONDS);
      if (verifyIpCount > MAX_VERIFY_PER_HOUR_PER_IP) {
        throw new HttpException('Превышен лимит проверок кода с вашего адреса, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
      }
    }

    const stored = await client.get(this.codeKey(email));
    if (!stored) return false;

    const attemptsKey = this.attemptsKey(email);
    const attempts = await client.incr(attemptsKey);
    if (attempts === 1) {
      const ttl = await client.ttl(this.codeKey(email));
      await client.expire(attemptsKey, ttl > 0 ? ttl : CODE_TTL_SECONDS);
    }
    if (attempts > MAX_WRONG_ATTEMPTS) {
      await client.del(this.codeKey(email));
      throw new BadRequestException('Слишком много попыток, запросите новый код');
    }

    const storedBuf = Buffer.from(stored);
    const codeBuf = Buffer.from(code);
    const match = storedBuf.length === codeBuf.length && crypto.timingSafeEqual(storedBuf, codeBuf);

    if (!match) {
      return false;
    }

    await Promise.all([client.del(this.codeKey(email)), client.del(attemptsKey)]);
    return true;
  }

  /// Письмо без кода — приглашение сотрудника (задача 025). Без лимитов
  /// requestCode: отправляется владельцем вручную, не по вводу пользователя.
  async sendMessage(email: string, subject: string, bodyText: string): Promise<void> {
    await this.provider.sendMessage(email, subject, bodyText);
  }

  /// Письмо из шаблона на языке получателя (задача 042, п.2).
  async sendTemplate(email: string, kind: EmailKind, locale: Locale | undefined, params: Record<string, string | number>): Promise<void> {
    const { subject, text } = renderEmail(kind, locale, params);
    await this.provider.sendMessage(email, subject, text);
  }
}
