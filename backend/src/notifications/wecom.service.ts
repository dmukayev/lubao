import { Injectable, Logger } from '@nestjs/common';

/// WeCom (企业微信) group-bot webhook — задача 011, п.2: компания вставляет
/// адрес бота своей группы в профиль, дальше шлём туда обычным POST без
/// токенов/подписей (формат самого простого «группового робота» WeCom, не
/// Work WeChat App API — не нужен корп-аккаунт разработчика).
@Injectable()
export class WeComService {
  private readonly logger = new Logger(WeComService.name);

  async send(webhookUrl: string, text: string): Promise<void> {
    const res = await fetch(webhookUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ msgtype: 'text', text: { content: text } }),
    });
    if (!res.ok) {
      throw new Error(`WeCom webhook failed: ${res.status} ${await res.text()}`);
    }
    const json = (await res.json().catch(() => null)) as { errcode?: number; errmsg?: string } | null;
    if (json && json.errcode) {
      throw new Error(`WeCom webhook rejected: ${json.errcode} ${json.errmsg}`);
    }
    this.logger.log(`WeCom: sent to ${webhookUrl.slice(0, 48)}…`);
  }
}
