import { Injectable, Logger } from '@nestjs/common';
import { isValidWeComWebhookUrl } from '../common/validators/wecom-webhook-url.validator';

const REQUEST_TIMEOUT_MS = 5000;

/// WeCom (企业微信) group-bot webhook — задача 011, п.2: компания вставляет
/// адрес бота своей группы в профиль, дальше шлём туда обычным POST без
/// токенов/подписей (формат самого простого «группового робота» WeCom, не
/// Work WeChat App API — не нужен корп-аккаунт разработчика).
///
/// Защита от SSRF (задача 029, п.2): владелец мог сохранить
/// `http://169.254.169.254/…`/`http://minio:9000/…` — DTO-валидатор
/// (`IsWeComWebhookUrl`) уже не даст такое сохранить, но перепроверяем
/// здесь же на каждый вызов — вторая линия защиты, если URL всё же
/// оказался в базе (старые записи, прямой доступ к БД). `redirect:
/// 'manual'` — чужой "бот" не может редиректнуть нас во внутреннюю сеть
/// 30x-ответом.
@Injectable()
export class WeComService {
  private readonly logger = new Logger(WeComService.name);

  async send(webhookUrl: string, text: string): Promise<void> {
    if (!isValidWeComWebhookUrl(webhookUrl)) {
      throw new Error('Invalid WeCom webhook URL');
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    let res: Response;
    try {
      res = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ msgtype: 'text', text: { content: text } }),
        redirect: 'manual',
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }

    // redirect: 'manual' делает 30x "opaqueredirect" (status 0) вместо
    // того, чтобы fetch сам пошёл по Location — тело недоступно, этого
    // достаточно: WeCom никогда не отвечает редиректом в норме.
    if (res.type === 'opaqueredirect' || !res.ok) {
      throw new Error(`WeCom webhook failed: ${res.status || 'redirect'}`);
    }
    const json = (await res.json().catch(() => null)) as { errcode?: number; errmsg?: string } | null;
    if (json && json.errcode) {
      throw new Error(`WeCom webhook rejected: ${json.errcode}`);
    }
    this.logger.log(`WeCom: sent to ${webhookUrl.slice(0, 48)}…`);
  }
}
