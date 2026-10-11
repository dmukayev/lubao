import { isPreviewBot } from './share-pages.service';

describe('057 п.23: открытия — без роботов превью', () => {
  it('WhatsApp, TelegramBot, facebookexternalhit — роботы; браузер телефона — нет', () => {
    expect(isPreviewBot('WhatsApp/2.23.20 A')).toBe(true);
    expect(isPreviewBot('TelegramBot (like TwitterBot)')).toBe(true);
    expect(isPreviewBot('facebookexternalhit/1.1')).toBe(true);
    expect(isPreviewBot('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1')).toBe(false);
  });
});
