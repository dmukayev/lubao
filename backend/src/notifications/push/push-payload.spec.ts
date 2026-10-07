import { apnsPayload, fcmMessage } from './push-provider';

describe('payload push с кнопками (042 п.1)', () => {
  const base = { title: 'Ещё ищете груз?', body: 'Вы на месте с утра', data: { deepLink: '/arrival', event: 'ARRIVAL_STILL_LOOKING' } };

  it('APNs: категория кнопок в aps.category, data рядом', () => {
    expect(apnsPayload({ ...base, category: 'STILL_LOOKING' })).toEqual({
      aps: { alert: { title: base.title, body: base.body }, category: 'STILL_LOOKING' },
      deepLink: '/arrival',
      event: 'ARRIVAL_STILL_LOOKING',
    });
    expect((apnsPayload(base).aps as Record<string, unknown>).category).toBeUndefined();
  });

  it('FCM с кнопками — data-only высокого приоритета (уведомление рисует приложение)', () => {
    const msg = fcmMessage('tok', { ...base, category: 'AGREED_CHECK' });
    expect(msg.notification).toBeUndefined();
    expect(msg).toMatchObject({ token: 'tok', android: { priority: 'high' }, data: { title: base.title, body: base.body, category: 'AGREED_CHECK', deepLink: '/arrival' } });
  });

  it('FCM без кнопок — обычное уведомление, как раньше', () => {
    expect(fcmMessage('tok', base)).toEqual({ token: 'tok', notification: { title: base.title, body: base.body }, data: base.data });
  });
});
