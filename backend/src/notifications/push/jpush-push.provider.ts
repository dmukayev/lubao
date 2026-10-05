import { Injectable, Logger } from '@nestjs/common';
import { PushMessage } from './push-provider';

/// JPush REST v3 (Android в Китае, без Google Play Services — задача 011,
/// п.2). .env: JPUSH_APP_KEY, JPUSH_MASTER_SECRET. Без них — предупреждение
/// и no-op.
@Injectable()
export class JpushPushProvider {
  private readonly logger = new Logger(JpushPushProvider.name);
  private readonly configured: boolean;

  constructor() {
    this.configured = !!(process.env.JPUSH_APP_KEY && process.env.JPUSH_MASTER_SECRET);
  }

  async send(token: string, message: PushMessage): Promise<void> {
    if (!this.configured) {
      this.logger.warn(`JPush credentials not set — skipping real JPush send to ${token.slice(0, 12)}…`);
      return;
    }
    const auth = Buffer.from(`${process.env.JPUSH_APP_KEY}:${process.env.JPUSH_MASTER_SECRET}`).toString('base64');
    const res = await fetch('https://api.jpush.cn/v3/push', {
      method: 'POST',
      headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        platform: 'android',
        audience: { registration_id: [token] },
        notification: { android: { title: message.title, alert: message.body, extras: message.data } },
      }),
    });
    if (!res.ok) {
      throw new Error(`JPush send failed: ${res.status} ${await res.text()}`);
    }
  }
}
