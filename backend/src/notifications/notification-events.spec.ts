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

/// 042 п.1, п.7: тап по push открывает экран через go_router — ссылка
/// должна совпадать с маршрутом приложения (app_router.dart) или быть
/// псевдонимом, который приложение раскрывает по роли.
describe('deep link push — маршруты приложения (042 п.1)', () => {
  const APP_ROUTES = [
    /^\/driver\/cargo\/[^/]+$/,
    /^\/chat\/[^/]+$/,
    /^\/deal\/[^/]+$/,
    /^\/company\/cargos\/[^/]+\/responses$/,
    /^\/company\/drivers$/,
    /^\/driver\/responses$/,
    /^\/(verification|arrival|profile)$/,
  ];
  const payload = { cargoId: 'c1', chatId: 'ch1', dealId: 'd1', complaintId: 'cp1', status: 'LOADED' };

  it.each(Object.keys(NOTIFICATION_EVENTS))('%s ведёт на известный маршрут', (event) => {
    const link = NOTIFICATION_EVENTS[event as keyof typeof NOTIFICATION_EVENTS].deepLink(payload);
    expect(link).not.toContain('lubao://');
    expect(APP_ROUTES.some((re) => re.test(link))).toBe(true);
  });

  it('кнопки есть только у «Ещё ищете груз?» и «Договорились?»', () => {
    const withButtons = Object.entries(NOTIFICATION_EVENTS).filter(([, d]) => d.category).map(([e]) => e).sort();
    expect(withButtons).toEqual(['AGREED_CHECK', 'ARRIVAL_STILL_LOOKING']);
  });
});

describe('статус сделки по роли (042 п.8)', () => {
  const p = { status: 'LOADED', driverName: 'Ерлан', companyName: 'Acme', origin: { ru: 'Хоргос', zh: '霍尔果斯' }, destination: { ru: 'Алматы', en: 'Almaty' }, reason: '' };
  it('логисту — по-человечески, с городом из справочника', () => {
    expect(NOTIFICATION_EVENTS.DEAL_FOR_LOGIST.render('ru', p).body).toBe('Ерлан загрузился, едет в Алматы');
    expect(NOTIFICATION_EVENTS.DEAL_FOR_LOGIST.render('ru', { ...p, status: 'CONFIRMED_BY_DRIVER' }).body).toBe('Ерлан подтвердил перевозку Хоргос → Алматы');
    expect(NOTIFICATION_EVENTS.DEAL_FOR_LOGIST.render('en', { ...p, status: 'DELIVERED' }).body).toBe('Ерлан delivered the cargo — rate the driver');
  });
  it('водителю — доставка и отмена с причиной', () => {
    expect(NOTIFICATION_EVENTS.DEAL_FOR_DRIVER.render('ru', { ...p, status: 'DELIVERED' }).body).toBe('Acme отметила доставку — оставьте отзыв');
    expect(NOTIFICATION_EVENTS.DEAL_FOR_DRIVER.render('ru', { ...p, status: 'CANCELLED', reason: 'Груз не готов' }).body).toBe('Причина: Груз не готов');
  });
  it('в шаблонах нет «Хоргос» строкой — только из справочника', () => {
    const noOrigin = { ...p, origin: null };
    for (const locale of ['ru', 'kk', 'zh', 'en'] as const) {
      for (const status of ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED']) {
        const r = NOTIFICATION_EVENTS.DEAL_FOR_LOGIST.render(locale, { ...noOrigin, status });
        expect(`${r.title} ${r.body}`).not.toMatch(/Хоргос|Khorgos|霍尔果斯/);
      }
    }
  });
});
