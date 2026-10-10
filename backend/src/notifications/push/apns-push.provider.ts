import * as http2 from 'http2';
import { Injectable, Logger } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { PushMessage, apnsPayload, PushTokenGoneError, isApnsTokenGone } from './push-provider';

/// APNs provider API (iOS — задача 011, п.2). Токен-авторизация (ES256 JWT,
/// как требует Apple), не сертификат — .env: APNS_KEY_ID, APNS_TEAM_ID,
/// APNS_PRIVATE_KEY (содержимое .p8 целиком, \n как литеральные переводы
/// строк), APNS_BUNDLE_ID, APNS_PRODUCTION=true|false (sandbox по умолчанию).
/// Без ключа — предупреждение и no-op, как у FCM/JPush.
@Injectable()
export class ApnsPushProvider {
  private readonly logger = new Logger(ApnsPushProvider.name);
  private cachedJwt: { value: string; issuedAt: number } | null = null;
  private readonly configured: boolean;

  constructor() {
    this.configured = !!(process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID && process.env.APNS_PRIVATE_KEY && process.env.APNS_BUNDLE_ID);
  }

  /// Apple требует новый JWT не чаще раза в 20 мин и не реже раза в час —
  /// перегенерируем после 50 мин.
  private getProviderToken(): string {
    if (this.cachedJwt && Date.now() - this.cachedJwt.issuedAt < 50 * 60 * 1000) {
      return this.cachedJwt.value;
    }
    const privateKey = process.env.APNS_PRIVATE_KEY!.replace(/\\n/g, '\n');
    const token = jwt.sign({ iss: process.env.APNS_TEAM_ID!, iat: Math.floor(Date.now() / 1000) }, privateKey, {
      algorithm: 'ES256',
      keyid: process.env.APNS_KEY_ID!,
    });
    this.cachedJwt = { value: token, issuedAt: Date.now() };
    return token;
  }

  async send(token: string, message: PushMessage): Promise<void> {
    if (!this.configured) {
      this.logger.warn(`APNs credentials not set — skipping real APNs send to ${token.slice(0, 12)}…`);
      return;
    }
    const host = process.env.APNS_PRODUCTION === 'true' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
    const client = http2.connect(host);
    try {
      await new Promise<void>((resolve, reject) => {
        const req = client.request({
          ':method': 'POST',
          ':path': `/3/device/${token}`,
          authorization: `bearer ${this.getProviderToken()}`,
          'apns-topic': process.env.APNS_BUNDLE_ID!,
          'content-type': 'application/json',
        });
        let status = 0;
        req.on('response', (headers) => {
          status = Number(headers[':status'] ?? 0);
        });
        let body = '';
        req.on('data', (chunk) => (body += chunk));
        req.on('end', () => {
          if (status >= 200 && status < 300) resolve();
          else if (isApnsTokenGone(status, body)) reject(new PushTokenGoneError(`APNs token gone: ${status}`));
          else reject(new Error(`APNs send failed: ${status} ${body}`));
        });
        req.on('error', reject);
        req.end(
          JSON.stringify(apnsPayload(message)),
        );
      });
    } finally {
      client.close();
    }
  }
}
