import * as Sentry from '@sentry/node';
import { ClientErrorsController } from './client-errors.controller';

jest.mock('@sentry/node', () => ({ captureMessage: jest.fn() }));

// 043 п.6: ошибки Flutter — в лог и Sentry без ПДн.
describe('ClientErrorsController', () => {
  it('телефон, ИИН и email вычищаются из сообщения и стека', () => {
    new ClientErrorsController().report({
      message: 'Null check failed for +7 701 123 45 67, ИИН 900101300123, mail test.user@example.com',
      stack: '#0 main (+77011234567)',
      platform: 'android',
      app: 'app',
      appVersion: '1.0.0',
    });
    const [message, ctx] = (Sentry.captureMessage as jest.Mock).mock.calls[0];
    const all = JSON.stringify([message, ctx]);
    expect(all).not.toMatch(/123 45 67|900101300123|test\.user|7011234567/);
    expect(ctx.tags).toMatchObject({ source: 'flutter', platform: 'android', appVersion: '1.0.0' });
  });
});
