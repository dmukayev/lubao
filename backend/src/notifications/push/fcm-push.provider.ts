import { readFileSync } from 'fs';
import { resolve } from 'path';
import { Injectable, Logger } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';
import { PushMessage, fcmMessage } from './push-provider';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/// FCM HTTP v1 (Android вне Китая — задача 011, п.2). Учётные данные — сервисный
/// аккаунт Firebase, целиком через .env: FCM_SERVICE_ACCOUNT_JSON (содержимое
/// JSON-файла сервисного аккаунта целиком, в одну строку) + FCM_PROJECT_ID
/// (есть и в самом JSON, но держим отдельно — проще проверить, что настроено).
/// Без них — предупреждение в лог и no-op: падать всему запросу из-за того,
/// что прод-учётка ещё не заведена, не должно (как и у остальных каналов).
@Injectable()
export class FcmPushProvider {
  private readonly logger = new Logger(FcmPushProvider.name);
  private account: ServiceAccount | null = null;
  private cachedToken: { value: string; expiresAt: number } | null = null;

  private readonly configured: boolean;

  constructor() {
    // Ключ сервисного аккаунта: содержимое (FCM_SERVICE_ACCOUNT_JSON) или путь
    // к файлу (FCM_SERVICE_ACCOUNT_FILE / FCM_SERVICE_ACCOUNT, относительно
    // backend/ — например ./secrets/firebase.json, папка в .gitignore).
    let raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
    const file = process.env.FCM_SERVICE_ACCOUNT_FILE || process.env.FCM_SERVICE_ACCOUNT;
    if (!raw && file) {
      try {
        raw = readFileSync(resolve(file), 'utf8');
      } catch {
        // Путь и причину пишем, содержимое — нет.
        this.logger.error(`Файл ключа FCM не прочитан (${file}) — FCM push выключен`);
      }
    }
    if (raw) {
      try {
        this.account = JSON.parse(raw);
      } catch {
        this.logger.error('FCM_SERVICE_ACCOUNT_JSON is not valid JSON — FCM push disabled');
      }
    }
    this.configured = !!this.account;
  }

  private async getAccessToken(): Promise<string> {
    if (this.cachedToken && this.cachedToken.expiresAt > Date.now() + 60_000) {
      return this.cachedToken.value;
    }
    const account = this.account!;
    const now = Math.floor(Date.now() / 1000);
    const assertion = jwt.sign(
      {
        iss: account.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      },
      account.private_key,
      { algorithm: 'RS256' },
    );

    const res = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${assertion}`,
    });
    if (!res.ok) {
      throw new Error(`FCM OAuth token exchange failed: ${res.status} ${await res.text()}`);
    }
    const json = (await res.json()) as { access_token: string; expires_in: number };
    this.cachedToken = { value: json.access_token, expiresAt: Date.now() + json.expires_in * 1000 };
    return json.access_token;
  }

  async send(token: string, message: PushMessage): Promise<void> {
    if (!this.configured) {
      this.logger.warn(`FCM_SERVICE_ACCOUNT_JSON not set — skipping real FCM send to ${token.slice(0, 12)}…`);
      return;
    }
    const accessToken = await this.getAccessToken();
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${this.account!.project_id}/messages:send`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: fcmMessage(token, message),
        }),
      },
    );
    if (!res.ok) {
      throw new Error(`FCM send failed: ${res.status} ${await res.text()}`);
    }
  }
}
