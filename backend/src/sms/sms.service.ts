import * as crypto from 'crypto';
import { BadRequestException, HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { LOGIN_CODE_CHANNELS_SETTING, LoginCodeChannel, consoleChannels, parseChannelSetting } from './login-code-channels';
import { SmsProvider } from './sms-provider';
import { TelegramCodeSender } from './telegram-code.sender';
import { WhatsappCodeSender } from './whatsapp-code.sender';

const CODE_TTL_SECONDS = 5 * 60;
const MINUTE_LOCK_SECONDS = 60;

/// Пауза между кодами на один номер. Для тестовых окружений с консольным
/// SMS (e2e, 041 п.12) её можно сократить/отключить (`SMS_MINUTE_LOCK_SECONDS=0`),
/// чтобы сценарии не ждали минуту между двумя входами одного номера. С
/// реальным провайдером и в production переменная игнорируется.
function minuteLockSeconds(): number {
  const override = process.env.SMS_MINUTE_LOCK_SECONDS;
  if (override === undefined || override === '') return MINUTE_LOCK_SECONDS;
  if (process.env.NODE_ENV === 'production' || process.env.SMS_PROVIDER === 'mobizon') return MINUTE_LOCK_SECONDS;
  const seconds = Number(override);
  return Number.isInteger(seconds) && seconds >= 0 ? seconds : MINUTE_LOCK_SECONDS;
}
const HOUR_WINDOW_SECONDS = 60 * 60;
const MAX_PER_HOUR = 5;
const MAX_PER_HOUR_PER_IP = 20;
const MAX_WRONG_ATTEMPTS = 5;
const MAX_VERIFY_PER_HOUR_PER_IP = 30;

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(
    private readonly redis: RedisService,
    private readonly provider: SmsProvider,
    private readonly whatsapp?: WhatsappCodeSender,
    private readonly telegram?: TelegramCodeSender,
    private readonly settings?: AppSettingsService,
  ) {}

  /// Канал настроен (есть ключи) — иначе в админке он серый и не используется.
  configured(id: LoginCodeChannel): boolean {
    if (id === 'sms') return true;
    if (consoleChannels().has(id)) return true;
    return id === 'whatsapp' ? !!this.whatsapp?.enabled() : !!this.telegram?.enabled();
  }

  /// Каналы, которые увидит водитель, в порядке из админки: включён и
  /// настроен. Если не осталось ни одного — страховка SMS.
  async channels(): Promise<LoginCodeChannel[]> {
    const setting = parseChannelSetting(await this.settings?.get(LOGIN_CODE_CHANNELS_SETTING));
    const list = setting.filter((c) => c.enabled && this.configured(c.id)).map((c) => c.id);
    return list.length > 0 ? list : ['sms'];
  }

  private async send(id: LoginCodeChannel, phone: string, code: string): Promise<void> {
    if (id === 'sms') return this.provider.sendCode(phone, code);
    if (consoleChannels().has(id)) {
      this.logger.log(`[DEV ${id}] ${phone}: ваш код — ${code}`);
      return;
    }
    if (id === 'whatsapp') return this.whatsapp!.sendCode(phone, code);
    return this.telegram!.sendCode(phone, code);
  }

  private channelKey(phone: string) {
    return `sms:channel:${phone}`;
  }

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
  private verifyIpHourKey(ip: string) {
    return `sms:verify-ip:${ip}`;
  }

  /// Генерирует и отправляет код, предварительно проверив лимиты:
  /// не больше 1 кода в минуту и 5 в час на номер, не больше 20 запросов
  /// в час на IP (защита от массового перебора номеров с одного источника).
  /// Лимиты общие для всех каналов.
  ///
  /// Канал (задача 042, п.3): водитель выбирает, куда прислать код (`channel`);
  /// не выбрал — первый по порядку из админки. Сбой канала (нет WhatsApp/
  /// Telegram на номере, отказ API, таймаут) — сервер сам берёт следующий и
  /// отвечает, куда ушёл код. «Не пришло? Отправить по-другому» — запрос с
  /// другим `channel`: тот же код уходит туда сразу, без минутной паузы.
  async requestCode(
    phone: string,
    ip: string,
    opts: { channel?: LoginCodeChannel } = {},
  ): Promise<{ channel: LoginCodeChannel; channels: LoginCodeChannel[] }> {
    const client = this.redis.client;
    const available = await this.channels();

    const lastChannel = (await client.get(this.channelKey(phone))) as LoginCodeChannel | null;
    const storedCode = await client.get(this.codeKey(phone));
    const resend = !!opts.channel && !!lastChannel && opts.channel !== lastChannel && !!storedCode;

    const locked = await client.get(this.minuteKey(phone));
    if (locked && !resend) {
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

    const code = resend ? storedCode! : this.provider.generateCode();
    await Promise.all([
      resend ? Promise.resolve() : client.set(this.codeKey(phone), code, 'EX', CODE_TTL_SECONDS),
      resend ? Promise.resolve() : client.del(this.attemptsKey(phone)),
      minuteLockSeconds() > 0 ? client.set(this.minuteKey(phone), '1', 'EX', minuteLockSeconds()) : Promise.resolve(),
      hourCount === 0 ? client.set(this.hourKey(phone), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.hourKey(phone)),
      ipHourCount === 0 ? client.set(this.ipHourKey(ip), '1', 'EX', HOUR_WINDOW_SECONDS) : client.incr(this.ipHourKey(ip)),
    ]);

    // Выбор водителя — первым (если канал доступен), дальше — порядок из
    // админки; при повторной отправке тот же канал не повторяем.
    const preferred = opts.channel && available.includes(opts.channel) ? [opts.channel] : [];
    let order = [...preferred, ...available.filter((c) => !preferred.includes(c))];
    if (resend) order = order.filter((c) => c !== lastChannel);
    if (order.length === 0) order = ['sms'];

    let lastError: unknown;
    for (const channel of order) {
      try {
        await this.send(channel, phone, code);
        await client.set(this.channelKey(phone), channel, 'EX', CODE_TTL_SECONDS);
        return { channel, channels: available };
      } catch (e) {
        lastError = e;
        this.logger.warn(`Код через ${channel} не ушёл, пробую следующий канал: ${(e as Error).message}`);
      }
    }
    throw lastError;
  }

  /// Сверяет код и удаляет его (одноразовый). true — код верный и ещё
  /// не истёк (5 минут). Максимум 5 неверных попыток на код — на 6-й код
  /// сгорает и требуется новый (защита от перебора 4-значного кода).
  ///
  /// Счётчик попыток инкрементируется атомарно (`INCR`) ДО сравнения кода:
  /// старая версия делала `get` → сравнить → `set` тремя отдельными
  /// командами, и параллельный перебор (например 200 запросов разом) читал
  /// attempts=0 во всех 200 — лимит в 5 попыток не работал вообще (ревью
  /// 006, 024 п.2). `INCR` в Redis — один атомарный шаг, так что при гонке
  /// только первые 5 параллельных запросов получают attempts ≤ 5 и доходят
  /// до сравнения кода, остальные сразу отваливаются.
  async verifyCode(phone: string, code: string, ip?: string): Promise<boolean> {
    const client = this.redis.client;

    if (ip) {
      const verifyIpCount = await client.incr(this.verifyIpHourKey(ip));
      if (verifyIpCount === 1) await client.expire(this.verifyIpHourKey(ip), HOUR_WINDOW_SECONDS);
      if (verifyIpCount > MAX_VERIFY_PER_HOUR_PER_IP) {
        throw new HttpException('Превышен лимит проверок кода с вашего адреса, попробуйте позже', HttpStatus.TOO_MANY_REQUESTS);
      }
    }

    const stored = await client.get(this.codeKey(phone));
    if (!stored) return false;

    const attemptsKey = this.attemptsKey(phone);
    const attempts = await client.incr(attemptsKey);
    if (attempts === 1) {
      const ttl = await client.ttl(this.codeKey(phone));
      await client.expire(attemptsKey, ttl > 0 ? ttl : CODE_TTL_SECONDS);
    }
    if (attempts > MAX_WRONG_ATTEMPTS) {
      await client.del(this.codeKey(phone));
      throw new BadRequestException('Слишком много попыток, запросите новый код');
    }

    const storedBuf = Buffer.from(stored);
    const codeBuf = Buffer.from(code);
    const match = storedBuf.length === codeBuf.length && crypto.timingSafeEqual(storedBuf, codeBuf);

    if (!match) {
      return false;
    }

    await Promise.all([client.del(this.codeKey(phone)), client.del(attemptsKey)]);
    return true;
  }
}
