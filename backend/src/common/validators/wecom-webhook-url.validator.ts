import { ValidationOptions, registerDecorator } from 'class-validator';

/// Защита от SSRF (задача 029, п.2): владелец компании не должен суметь
/// сохранить `http://minio:9000/…`, `http://169.254.169.254/…` или любой
/// другой адрес — бэкенд потом реально сходит туда по кнопке «Проверить»
/// и при каждом событии NEW_RESPONSE/DEAL_STATUS (011). Разрешён только
/// настоящий вебхук группового бота WeCom — конкретный хост, схема,
/// путь; `key` — обязательный query-параметр, но его значение не
/// ограничиваем (это секрет самого бота).
export function isValidWeComWebhookUrl(value: unknown): boolean {
  if (typeof value !== 'string') return false;
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    return false;
  }
  return (
    url.protocol === 'https:' &&
    url.hostname === 'qyapi.weixin.qq.com' &&
    url.pathname === '/cgi-bin/webhook/send' &&
    url.searchParams.has('key') &&
    url.searchParams.get('key')!.length > 0
  );
}

export function IsWeComWebhookUrl(validationOptions?: ValidationOptions) {
  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isWeComWebhookUrl',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate: isValidWeComWebhookUrl,
        defaultMessage: () => 'wecomWebhookUrl must be a https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=... URL',
      },
    });
  };
}
