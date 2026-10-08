/// Каналы кода входа водителя (задача 042 п.3, решение 2026-10-07):
/// WhatsApp, Telegram, SMS. Какие включены и в каком порядке — настройка
/// `app_settings.loginCodeChannels` из админки (без релиза).
export const LOGIN_CODE_CHANNELS = ['whatsapp', 'telegram', 'sms'] as const;
export type LoginCodeChannel = (typeof LOGIN_CODE_CHANNELS)[number];
export const LOGIN_CODE_CHANNELS_SETTING = 'loginCodeChannels';

/// 050 п.2: «Каналы входа» в админке — каналы кода плюс бот Telegram (вход
/// без кода). Порядок и вкл/выкл — одна настройка; код шлётся только по
/// LOGIN_CODE_CHANNELS.
export const LOGIN_CHANNELS = ['telegram_bot', ...LOGIN_CODE_CHANNELS] as const;
export type LoginChannel = (typeof LOGIN_CHANNELS)[number];

export type ChannelSetting = { id: LoginChannel; enabled: boolean };

const DEFAULT_SETTING: ChannelSetting[] = LOGIN_CHANNELS.map((id) => ({ id, enabled: true }));

export function isLoginCodeChannel(v: unknown): v is LoginCodeChannel {
  return typeof v === 'string' && (LOGIN_CODE_CHANNELS as readonly string[]).includes(v);
}

export function isLoginChannel(v: unknown): v is LoginChannel {
  return typeof v === 'string' && (LOGIN_CHANNELS as readonly string[]).includes(v);
}

/// Значение настройки — JSON-массив `[{id, enabled}]` в нужном порядке.
/// Неизвестные/повторы отбрасываются, недостающие каналы дописываются в
/// конец выключенными — порядок и состав всегда полные.
export function parseChannelSetting(raw: string | null | undefined): ChannelSetting[] {
  if (!raw) return DEFAULT_SETTING.map((c) => ({ ...c }));
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return DEFAULT_SETTING.map((c) => ({ ...c }));
  }
  if (!Array.isArray(parsed)) return DEFAULT_SETTING.map((c) => ({ ...c }));
  const result: ChannelSetting[] = [];
  for (const item of parsed) {
    const id = (item as { id?: unknown })?.id;
    if (!isLoginChannel(id) || result.some((c) => c.id === id)) continue;
    result.push({ id, enabled: (item as { enabled?: unknown }).enabled !== false });
  }
  for (const id of LOGIN_CHANNELS) {
    // Бот Telegram появился позже (050): в старой настройке его нет — включён в начале
    // (без токена всё равно скрыт); прочие недостающие — выключены в конце.
    if (!result.some((c) => c.id === id)) {
      if (id === 'telegram_bot') result.unshift({ id, enabled: true });
      else result.push({ id, enabled: false });
    }
  }
  return result;
}

export function isValidChannelSetting(raw: string): boolean {
  try {
    const parsed = JSON.parse(raw);
    return (
      Array.isArray(parsed) &&
      parsed.length <= LOGIN_CHANNELS.length &&
      parsed.every((c) => isLoginChannel(c?.id) && typeof c?.enabled === 'boolean')
    );
  } catch {
    return false;
  }
}

/// Dev/e2e: каналы без ключей, которые всё равно считаются доступными, —
/// код пишется в консоль (`LOGIN_CODE_CONSOLE_CHANNELS=whatsapp,telegram`).
/// В production переменная игнорируется.
export function consoleChannels(): Set<LoginCodeChannel> {
  if (process.env.NODE_ENV === 'production') return new Set();
  return new Set((process.env.LOGIN_CODE_CONSOLE_CHANNELS ?? '').split(',').map((s) => s.trim()).filter(isLoginCodeChannel));
}
