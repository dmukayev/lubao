import { NOTIFICATION_EVENTS, formatCargoWeight } from './notification-events';

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

/// 053 п.6а: «Вас пригласили» и «Вас выбрали» — с сутью груза, чтобы по
/// push было понятно, стоит ли открывать.
describe('CARGO_INVITE / DEAL_SELECTED — маршрут, цена, вес, кузов, погрузка (053 п.6а)', () => {
  const payload = {
    cargoId: 'cargo1',
    dealId: 'deal1',
    companyName: 'ТОО X',
    origin: { ru: 'Алматы', kk: 'Алматы', zh: '阿拉木图', en: 'Almaty' },
    destination: { ru: 'Астана', kk: 'Астана', zh: '阿斯塔纳', en: 'Astana' },
    price: 850000,
    currency: 'KZT',
    weightKg: 20000,
    bodyType: { ru: 'Тент', kk: 'Тент', zh: '篷布车', en: 'Tent' },
    readyDate: '2026-10-10',
  };

  it('ru: заголовок с маршрутом, текст — цена как в ленте, тонны, кузов, дата, компания', () => {
    expect(NOTIFICATION_EVENTS.CARGO_INVITE.render('ru', payload)).toEqual({
      title: 'Приглашение: Алматы → Астана',
      body: '₸850 000 · 20 т · тент · погрузка 10 окт — ТОО X',
    });
    expect(NOTIFICATION_EVENTS.DEAL_SELECTED.render('ru', payload).title).toBe('Вас выбрали: Алматы → Астана');
    expect(NOTIFICATION_EVENTS.DEAL_SELECTED.render('ru', payload).body).toContain('₸850 000 · 20 т');
  });

  it('kk/zh/en — города и кузов из справочника на языке получателя', () => {
    expect(NOTIFICATION_EVENTS.CARGO_INVITE.render('kk', payload).body).toBe('₸850 000 · 20 т · тент · тиеу 10 қаз — ТОО X');
    expect(NOTIFICATION_EVENTS.CARGO_INVITE.render('zh', payload)).toEqual({
      title: '邀请：阿拉木图 → 阿斯塔纳',
      body: '₸850 000 · 20 吨 · 篷布车 · 装货 10月10日 — ТОО X',
    });
    expect(NOTIFICATION_EVENTS.CARGO_INVITE.render('en', { ...payload, currency: 'USD', price: 1500, weightKg: 12500 }).body).toBe(
      '$1 500 · 12.5 t · tent · loading Oct 10 — ТОО X',
    );
  });

  it('без сводки (сбой чтения груза) — прежний общий текст, тап всё равно ведёт на груз', () => {
    const r = NOTIFICATION_EVENTS.CARGO_INVITE.render('ru', { cargoId: 'cargo1', companyName: 'ТОО X' });
    expect(r).toEqual({ title: 'Приглашение на груз', body: 'ТОО X приглашает вас на груз' });
    expect(NOTIFICATION_EVENTS.CARGO_INVITE.deepLink(payload)).toBe('/driver/cargo/cargo1');
    expect(NOTIFICATION_EVENTS.DEAL_SELECTED.deepLink(payload)).toBe('/deal/deal1');
  });
});

describe('RESPONSE_CARGO_CLOSED — груз снят (056 п.1)', () => {
  it('маршрут и компания на языке получателя, тап — в мои отклики', () => {
    const p = { cargoId: 'c1', companyName: 'ТОО X', origin: { ru: 'Алматы', en: 'Almaty' }, destination: { ru: 'Астана', en: 'Astana' } };
    expect(NOTIFICATION_EVENTS.RESPONSE_CARGO_CLOSED.render('ru', p)).toEqual({ title: 'Груз снят', body: 'Алматы → Астана — ТОО X. В ленте есть другие грузы.' });
    expect(NOTIFICATION_EVENTS.RESPONSE_CARGO_CLOSED.render('en', p).body).toBe('Almaty → Astana — ТОО X. There are other loads in the feed.');
    expect(NOTIFICATION_EVENTS.RESPONSE_CARGO_CLOSED.render('zh', { companyName: 'ТОО X' }).body).toBe('ТОО X。货源列表中还有其他货物。');
    expect(NOTIFICATION_EVENTS.RESPONSE_CARGO_CLOSED.deepLink(p)).toBe('/driver/responses');
  });
});

describe('formatCargoWeight — вес в push как у водителя (055)', () => {
  it('тонны до одного знака без лишних нулей, меньше тонны — кг; запятая в ru/kk', () => {
    expect(formatCargoWeight(18500, 'ru')).toBe('18,5 т');
    expect(formatCargoWeight(20000, 'ru')).toBe('20 т');
    expect(formatCargoWeight(800, 'ru')).toBe('800 кг');
    expect(formatCargoWeight(18500, 'en')).toBe('18.5 t');
    expect(formatCargoWeight(18540, 'zh')).toBe('18.5 吨');
  });
});
