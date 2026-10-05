import { DevicePlatform } from '@prisma/client';

export interface PushMessage {
  title: string;
  body: string;
  /// Для deep link на клиенте (задача 011, п.5) — всегда строки, т.к. и FCM,
  /// и APNs, и JPush передают data-payload как Map<String,String>.
  data: Record<string, string>;
}

/// Абстракция канала push. Выбор реализации — через .env (PUSH_PROVIDER),
/// бизнес-логика (кому, через какой из трёх провайдеров, лимиты, очередь)
/// — в NotificationsService, не здесь. По аналогии с SmsProvider/EmailProvider.
export abstract class PushProvider {
  abstract send(token: string, platform: DevicePlatform, message: PushMessage): Promise<void>;
}
