import { emailHtml, inviteLink, localeFromAcceptLanguage, renderEmail } from './email-messages';

describe('письма на 4 языках (задача 042, п.2/п.6)', () => {
  const locales = ['kk', 'ru', 'zh', 'en'] as const;

  it.each(locales)('код подтверждения (%s): код и срок в тексте, тема не пустая', (locale) => {
    const { subject, text } = renderEmail('CODE', locale, { code: '123456', minutes: 10 });
    expect(subject.length).toBeGreaterThan(3);
    expect(text).toContain('123456');
    expect(text).toContain('10');
  });

  it.each(locales)('приглашение (%s): https-ссылка, название компании, срок', (locale) => {
    const link = 'https://app.lubao.kz/invite/abc';
    const { subject, text } = renderEmail('INVITE', locale, { company: 'Yidao', days: 7, link });
    expect(subject).toContain('Yidao');
    expect(text).toContain(link);
    expect(text).not.toContain('lubao://');
  });

  it.each(locales)('«Договорились?»-дайджест (%s): число звонков и ссылка', (locale) => {
    const { text } = renderEmail('AGREED_DIGEST', locale, { count: 3, link: 'https://app.lubao.kz/chats' });
    expect(text).toContain('3');
    expect(text).toContain('https://app.lubao.kz/chats');
  });

  it('язык не задан/неизвестен — русский', () => {
    expect(renderEmail('CODE', undefined, { code: '1', minutes: 10 }).subject).toBe('Код подтверждения Lubao');
    expect(renderEmail('CODE', 'fr' as never, { code: '1', minutes: 10 }).subject).toBe('Код подтверждения Lubao');
  });

  it('ни в одном письме нет названия конкретной точки (CLAUDE.md)', () => {
    for (const locale of locales) {
      for (const kind of ['CODE', 'INVITE', 'AGREED_DIGEST'] as const) {
        const { subject, text } = renderEmail(kind, locale, { code: '1', minutes: 1, company: 'X', days: 1, link: 'l', count: 1 });
        expect(`${subject} ${text}`).not.toMatch(/Хоргос|Khorgos|霍尔果斯|Қорғас/);
      }
    }
  });

  describe('Accept-Language', () => {
    it('берёт первый поддерживаемый язык', () => {
      expect(localeFromAcceptLanguage('zh-CN,zh;q=0.9,en;q=0.8')).toBe('zh');
      expect(localeFromAcceptLanguage('de,kk;q=0.5')).toBe('kk');
      expect(localeFromAcceptLanguage('en-US')).toBe('en');
    });
    it('нет заголовка/чужой язык — ru', () => {
      expect(localeFromAcceptLanguage(undefined)).toBe('ru');
      expect(localeFromAcceptLanguage('de,fr')).toBe('ru');
    });
  });

  describe('inviteLink', () => {
    it('https://<хост>/invite/<токен>, без двойного слэша', () => {
      expect(inviteLink('tok', 'https://app.lubao.kz/')).toBe('https://app.lubao.kz/invite/tok');
      expect(inviteLink('tok', 'https://app.lubao.kz')).toBe('https://app.lubao.kz/invite/tok');
    });
  });
});

describe('emailHtml', () => {
  it('шапка с логотипом со своего сервера, текст экранирован, ссылки кликабельны', () => {
    const html = emailHtml('Код <b>1</b>\nhttps://app.lubao.kz/invite/abc', 'https://app.lubao.kz');
    expect(html).toContain('src="https://app.lubao.kz/assets/packages/lubao_core/assets/brand/logo-horizontal.png"');
    expect(html).toContain('&lt;b&gt;1&lt;/b&gt;');
    expect(html).toContain('<a href="https://app.lubao.kz/invite/abc"');
    expect(html).not.toMatch(/googleapis|gstatic/);
  });
});

