import { Injectable } from '@nestjs/common';
import { DevicePlatform } from '@prisma/client';
import { ApnsPushProvider } from './apns-push.provider';
import { FcmPushProvider } from './fcm-push.provider';
import { JpushPushProvider } from './jpush-push.provider';
import { PushMessage, PushProvider } from './push-provider';

/// Выбирает реальный канал по платформе токена (задача 011, п.2: FCM/APNs/
/// JPush — не альтернативы друг другу, а разные устройства одновременно).
@Injectable()
export class RealPushProvider extends PushProvider {
  constructor(
    private readonly fcm: FcmPushProvider,
    private readonly apns: ApnsPushProvider,
    private readonly jpush: JpushPushProvider,
  ) {
    super();
  }

  async send(token: string, platform: DevicePlatform, message: PushMessage): Promise<void> {
    switch (platform) {
      case 'FCM':
        return this.fcm.send(token, message);
      case 'APNS':
        return this.apns.send(token, message);
      case 'JPUSH':
        return this.jpush.send(token, message);
    }
  }
}
