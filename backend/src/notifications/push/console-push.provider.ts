import { Injectable, Logger } from '@nestjs/common';
import { DevicePlatform } from '@prisma/client';
import { PushMessage, PushProvider } from './push-provider';

/// Для локальной разработки и демо: push не отправляется — только пишется
/// в лог, чтобы было видно, что сервис вызван (как ConsoleSmsProvider/
/// ConsoleEmailProvider).
@Injectable()
export class ConsolePushProvider extends PushProvider {
  private readonly logger = new Logger(ConsolePushProvider.name);

  async send(token: string, platform: DevicePlatform, message: PushMessage): Promise<void> {
    // Задача 029, п.12 — лог не должен содержать текст уведомления (имя
    // собеседника, превью сообщения, причину отмены и т.п.), только
    // метаданные доставки: тип события и deep-link id.
    this.logger.log(`[DEV PUSH/${platform}] ${token.slice(0, 12)}… event=${message.data.event} deepLink=${message.data.deepLink}`);
  }
}
