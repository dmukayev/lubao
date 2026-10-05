import { isValidWeComWebhookUrl } from './wecom-webhook-url.validator';

describe('isValidWeComWebhookUrl (задача 029, п.2 — защита от SSRF)', () => {
  it('accepts the real WeCom group-bot webhook shape', () => {
    expect(isValidWeComWebhookUrl('https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=abc-123')).toBe(true);
  });

  const rejected = [
    'http://169.254.169.254/latest/meta-data/', // cloud metadata endpoint
    'http://minio:9000/some-bucket', // internal docker service
    'http://localhost:3000/admin/stats', // internal backend itself
    'http://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=x', // http, not https
    'https://qyapi.weixin.qq.com.evil.com/cgi-bin/webhook/send?key=x', // hostname confusion
    'https://evil.com/qyapi.weixin.qq.com/cgi-bin/webhook/send?key=x',
    'https://qyapi.weixin.qq.com/some/other/path?key=x', // wrong path
    'https://qyapi.weixin.qq.com/cgi-bin/webhook/send', // missing key param
    'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=', // empty key
    'not a url at all',
    '',
    null,
    undefined,
  ];

  it.each(rejected)('rejects %p', (value) => {
    expect(isValidWeComWebhookUrl(value)).toBe(false);
  });
});
