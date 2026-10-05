import { Locale } from '@prisma/client';

export const TRANSLATION_QUEUE = 'translation';

/// DI-токен очереди (задача 029, п.6) — отдельный от `Queue` (bullmq),
/// который уже занят под уведомления (notifications.module.ts): если
/// оба глобальных модуля провайдят один и тот же класс-токен `Queue`,
/// один из них незаметно перекрывает другой.
export const TRANSLATION_QUEUE_TOKEN = 'TRANSLATION_QUEUE_TOKEN';

/// Перевод — в фоне, не на пути отправки сообщения (задача 029, п.6):
/// `ChatsService.send` кладёт задание и отвечает мгновенно, провайдер
/// может «висеть» секундами без влияния на UX отправки.
export interface TranslationJob {
  messageId: string;
  chatId: string;
  text: string;
  from: Locale;
  to: Locale;
  senderUserId: string;
}
