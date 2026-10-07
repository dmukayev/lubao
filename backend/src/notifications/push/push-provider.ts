import { DevicePlatform } from '@prisma/client';

export interface PushMessage {
  title: string;
  body: string;
  /// Для deep link на клиенте (задача 011, п.5) — всегда строки, т.к. и FCM,
  /// и APNs, и JPush передают data-payload как Map<String,String>.
  data: Record<string, string>;
  /// Кнопки в push (042 п.1): «Ещё ищете груз?» — Да / Уехал,
  /// «Договорились?» — Да / Нет.
  category?: 'STILL_LOOKING' | 'AGREED_CHECK';
}

/// Тело APNs: категория кнопок — в `aps.category` (кнопки регистрирует
/// приложение), data — рядом с `aps`, как раньше.
export function apnsPayload(message: PushMessage): Record<string, unknown> {
  return {
    aps: { alert: { title: message.title, body: message.body }, ...(message.category ? { category: message.category } : {}) },
    ...message.data,
  };
}

/// Сообщение FCM HTTP v1. С кнопками — data-only с высоким приоритетом:
/// уведомление с действиями рисует само приложение (системное
/// notification FCM кнопок не умеет). Без кнопок — как раньше.
export function fcmMessage(token: string, message: PushMessage): Record<string, unknown> {
  if (message.category) {
    return {
      token,
      data: { ...message.data, title: message.title, body: message.body, category: message.category },
      android: { priority: 'high' },
      // iOS через FCM: видимое уведомление с категорией кнопок (их
      // регистрирует приложение, нажатие ловит AppDelegate).
      apns: { payload: { aps: { alert: { title: message.title, body: message.body }, category: message.category } } },
    };
  }
  return { token, notification: { title: message.title, body: message.body }, data: message.data };
}

/// Абстракция канала push. Выбор реализации — через .env (PUSH_PROVIDER),
/// бизнес-логика (кому, через какой из трёх провайдеров, лимиты, очередь)
/// — в NotificationsService, не здесь. По аналогии с SmsProvider/EmailProvider.
export abstract class PushProvider {
  abstract send(token: string, platform: DevicePlatform, message: PushMessage): Promise<void>;
}
