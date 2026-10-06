import { initSentry, scrubSentryEvent } from './sentry';

describe('Sentry без персональных данных (задача 043, п.6)', () => {
  it('без SENTRY_DSN выключен', () => {
    expect(initSentry({})).toBe(false);
  });

  it('из события вырезаются тело запроса, куки, авторизация и IP; пользователь — только id', () => {
    const event = scrubSentryEvent({
      request: {
        url: 'https://api.lubao.kz/auth/phone/verify',
        data: { phone: '+77010000001', code: '1234' },
        cookies: { a: 'b' },
        query_string: 'phone=+77010000001',
        headers: { Authorization: 'Bearer secret', 'X-Forwarded-For': '1.2.3.4', 'content-type': 'application/json' },
      },
      user: { id: 'u1', email: 'a@b.com', ip_address: '1.2.3.4', username: 'Эрлан' },
    });
    expect(event.request.data).toBeUndefined();
    expect(event.request.cookies).toBeUndefined();
    expect(event.request.query_string).toBeUndefined();
    expect(event.request.headers).toEqual({ 'content-type': 'application/json' });
    expect(event.user).toEqual({ id: 'u1' });
    expect(JSON.stringify(event)).not.toMatch(/77010000001|secret|1\.2\.3\.4|a@b\.com/);
  });

  it('телефоны, ИИН и email в сообщениях и исключениях маскируются; данные хлебных крошек удаляются', () => {
    const event = scrubSentryEvent({
      message: 'SMS to +77010000001 failed',
      exception: { values: [{ value: 'IIN 950302502008 not found for logist@example.com' }] },
      breadcrumbs: [{ message: 'call +77010000001', data: { phone: '+77010000001' } }],
    });
    const json = JSON.stringify(event);
    expect(json).not.toMatch(/77010000001|950302502008|logist@/);
    expect(event.breadcrumbs[0].data).toBeUndefined();
  });
});
