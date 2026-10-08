import { ConflictException, GoneException, HttpException, HttpStatus, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../prisma/prisma.service';
import { botLang, botText } from './telegram-bot.texts';

/// Вход через бот Telegram (050, decisions.md 2026-10-08 «Вход без кода»):
/// приложение получает одноразовый nonce → открывает t.me/<bot>?start=<nonce> →
/// бот просит «Поделиться номером» → свой контакт (contact.user_id == from.id)
/// привязывается к nonce → приложение забирает вход опросом. Состояние — в Redis.
export const TELEGRAM_NONCE_TTL_SECONDS = 5 * 60;
const NONCE_PER_IP_PER_HOUR = 20;
const nonceKey = (nonce: string) => `tg-login:${nonce}`;
const chatKey = (chatId: number | string) => `tg-login-chat:${chatId}`;
const ipKey = (ip: string) => `tg-login-ip:${ip}`;

type NonceState = {
  status: 'PENDING' | 'READY' | 'USED';
  deviceName?: string;
  platform?: string;
  phone?: string;
  telegramUserId?: string;
};

/// Забрать готовый вход ровно один раз: READY → USED атомарно (Lua), USED
/// остаётся до конца TTL — повтор того же nonce отличим от истёкшего.
const CONSUME_LUA = `
local raw = redis.call('GET', KEYS[1])
if not raw then return nil end
local state = cjson.decode(raw)
if state.status ~= 'READY' then return raw end
local used = cjson.decode(raw)
used.status = 'USED'
local ttl = redis.call('TTL', KEYS[1])
if ttl < 1 then ttl = 60 end
redis.call('SET', KEYS[1], cjson.encode(used), 'EX', ttl)
return raw`;

type TgMessage = {
  chat: { id: number };
  from?: { id: number; language_code?: string };
  text?: string;
  contact?: { phone_number: string; user_id?: number };
};

@Injectable()
export class TelegramLoginService {
  private readonly logger = new Logger(TelegramLoginService.name);

  constructor(
    private readonly redis: RedisService,
    private readonly prisma: PrismaService,
  ) {}

  /// Подменяется в тестах.
  fetchFn: typeof fetch = (input, init) => fetch(input, { ...init, signal: AbortSignal.timeout(10_000) });

  get configured(): boolean {
    return !!process.env.TELEGRAM_BOT_TOKEN && !!process.env.TELEGRAM_BOT_USERNAME;
  }

  /// Секрет webhook'а (заголовок X-Telegram-Bot-Api-Secret-Token).
  webhookSecretOk(header: string | undefined): boolean {
    const secret = process.env.TELEGRAM_WEBHOOK_SECRET;
    return !!secret && header === secret;
  }

  async start(ip: string, deviceName?: string, platform?: string) {
    if (!this.configured) throw new NotFoundException({ code: 'TELEGRAM_DISABLED', message: 'Telegram sign-in is not configured' });
    const client = this.redis.client;
    const count = await client.incr(ipKey(ip));
    if (count === 1) await client.expire(ipKey(ip), 3600);
    if (count > NONCE_PER_IP_PER_HOUR) {
      throw new HttpException({ code: 'TOO_MANY_REQUESTS', message: 'Too many sign-in attempts' }, HttpStatus.TOO_MANY_REQUESTS);
    }
    // Telegram: параметр start — до 64 символов [A-Za-z0-9_-].
    const nonce = randomBytes(24).toString('base64url');
    const state: NonceState = { status: 'PENDING', deviceName, platform };
    await client.set(nonceKey(nonce), JSON.stringify(state), 'EX', TELEGRAM_NONCE_TTL_SECONDS);
    return { nonce, url: `https://t.me/${process.env.TELEGRAM_BOT_USERNAME}?start=${nonce}`, expiresInSeconds: TELEGRAM_NONCE_TTL_SECONDS };
  }

  /// Опрос приложения: PENDING — ждём; READY — забрать (один раз); USED — 409.
  async consume(nonce: string): Promise<{ status: 'PENDING' } | { status: 'READY'; phone: string; telegramUserId?: string; deviceName?: string; platform?: string }> {
    const raw = (await this.redis.client.eval(CONSUME_LUA, 1, nonceKey(nonce))) as string | null;
    if (!raw) throw new GoneException({ code: 'NONCE_EXPIRED', message: 'Sign-in link expired' });
    const state = JSON.parse(raw) as NonceState;
    if (state.status === 'USED') throw new ConflictException({ code: 'NONCE_USED', message: 'Sign-in already completed' });
    if (state.status !== 'READY' || !state.phone) return { status: 'PENDING' };
    return { status: 'READY', phone: state.phone, telegramUserId: state.telegramUserId, deviceName: state.deviceName, platform: state.platform };
  }

  /// Обновление от Telegram (webhook). Ошибки не пробрасываем — Telegram
  /// повторял бы доставку; всё пишем в лог.
  async handleUpdate(update: { message?: TgMessage }): Promise<void> {
    const msg = update.message;
    if (!msg?.from) return;
    const lang = botLang(msg.from.language_code);
    try {
      const start = msg.text?.match(/^\/start(?:@\w+)?\s+([A-Za-z0-9_-]{16,64})$/);
      if (start) return await this.onStart(msg, start[1], lang);
      if (msg.contact) return await this.onContact(msg, lang);
    } catch (e) {
      this.logger.warn(`telegram update failed: ${(e as Error).message}`);
    }
  }

  private async onStart(msg: TgMessage, nonce: string, lang: ReturnType<typeof botLang>) {
    const raw = await this.redis.client.get(nonceKey(nonce));
    const state = raw ? (JSON.parse(raw) as NonceState) : null;
    if (!state || state.status !== 'PENDING') return this.send(msg.chat.id, botText('expired', lang));
    const telegramUserId = String(msg.from!.id);
    // Повторный вход: этот Telegram уже привязан к водителю — без контакта.
    const known = await this.prisma.user.findFirst({ where: { telegramUserId, role: 'DRIVER', phone: { not: null } }, select: { phone: true } });
    if (known?.phone) return this.markReady(nonce, state, known.phone, telegramUserId, msg.chat.id, lang);
    await this.redis.client.set(chatKey(msg.chat.id), nonce, 'EX', TELEGRAM_NONCE_TTL_SECONDS);
    await this.send(msg.chat.id, `${botText('hello', lang)}\n${botText('askContact', lang)}`, {
      keyboard: [[{ text: botText('shareButton', lang), request_contact: true }]],
      resize_keyboard: true,
      one_time_keyboard: true,
    });
  }

  private async onContact(msg: TgMessage, lang: ReturnType<typeof botLang>) {
    // Только свой номер: пересланный чужой контакт не принимаем.
    if (!msg.contact || msg.contact.user_id !== msg.from!.id) return this.send(msg.chat.id, botText('foreignContact', lang));
    const nonce = await this.redis.client.get(chatKey(msg.chat.id));
    const raw = nonce ? await this.redis.client.get(nonceKey(nonce)) : null;
    const state = raw ? (JSON.parse(raw) as NonceState) : null;
    if (!nonce || !state || state.status !== 'PENDING') return this.send(msg.chat.id, botText('expired', lang));
    const digits = msg.contact.phone_number.replace(/[^\d]/g, '');
    await this.markReady(nonce, state, `+${digits}`, String(msg.from!.id), msg.chat.id, lang);
  }

  private async markReady(nonce: string, state: NonceState, phone: string, telegramUserId: string, chatId: number, lang: ReturnType<typeof botLang>) {
    const ttl = await this.redis.client.ttl(nonceKey(nonce));
    const ready: NonceState = { ...state, status: 'READY', phone, telegramUserId };
    await this.redis.client.set(nonceKey(nonce), JSON.stringify(ready), 'EX', ttl > 0 ? ttl : TELEGRAM_NONCE_TTL_SECONDS);
    await this.redis.client.del(chatKey(chatId));
    const appUrl = `${process.env.APP_PUBLIC_URL || 'https://app.lubao.kz'}/login/telegram-done`;
    await this.send(chatId, botText('done', lang), { inline_keyboard: [[{ text: botText('openApp', lang), url: appUrl }]], remove_keyboard: undefined });
  }

  private async send(chatId: number, text: string, replyMarkup?: Record<string, unknown>) {
    const token = process.env.TELEGRAM_BOT_TOKEN;
    if (!token) return;
    const res = await this.fetchFn(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text, ...(replyMarkup ? { reply_markup: replyMarkup } : {}) }),
    });
    if (!res.ok) this.logger.warn(`telegram sendMessage HTTP ${res.status}`);
  }
}
