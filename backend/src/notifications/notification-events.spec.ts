import { NOTIFICATION_EVENTS } from './notification-events';

/// Задача 029, п.11 — раньше DEAL_STATUS всегда рендерился на русском
/// (готовая строка статуса клалась в payload вызывающей стороной), а
/// CHAT_MESSAGE показывал оригинал сообщения, даже когда получатель не
/// понимает язык отправителя и перевод ещё не готов (он асинхронный,
/// п.6). Проверяем, что оба события теперь зависят от локали получателя.
describe('NOTIFICATION_EVENTS render per-recipient locale (задача 029, п.11)', () => {
  it('DEAL_STATUS body is translated for kk/zh/en, not just ru', () => {
    const payload = { dealId: 'deal1', status: 'DELIVERED' };

    expect(NOTIFICATION_EVENTS.DEAL_STATUS.render('ru', payload).body).toBe('Доставлено');
    expect(NOTIFICATION_EVENTS.DEAL_STATUS.render('kk', payload).body).toBe('Жеткізілді');
    expect(NOTIFICATION_EVENTS.DEAL_STATUS.render('zh', payload).body).toBe('已送达');
    expect(NOTIFICATION_EVENTS.DEAL_STATUS.render('en', payload).body).toBe('Delivered');
  });

  it('CHAT_MESSAGE shows the actual preview when provided (same-locale chat, no translation needed)', () => {
    const payload = { chatId: 'c1', senderName: 'Ерлан', preview: 'Груз ещё актуален?' };
    expect(NOTIFICATION_EVENTS.CHAT_MESSAGE.render('ru', payload).body).toBe('Груз ещё актуален?');
  });

  it('CHAT_MESSAGE falls back to a neutral, recipient-locale body when preview is null (translation not ready yet)', () => {
    const payload = { chatId: 'c1', senderName: 'Ерлан', preview: null };

    expect(NOTIFICATION_EVENTS.CHAT_MESSAGE.render('ru', payload).body).toBe('Новое сообщение');
    expect(NOTIFICATION_EVENTS.CHAT_MESSAGE.render('zh', payload).body).toBe('新消息');
    expect(NOTIFICATION_EVENTS.CHAT_MESSAGE.render('kk', payload).body).toBe('Жаңа хабарлама');
    expect(NOTIFICATION_EVENTS.CHAT_MESSAGE.render('en', payload).body).toBe('New message');
  });
});
