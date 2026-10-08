import { isValidChannelSetting, parseChannelSetting } from './login-code-channels';

describe('настройка каналов кода (042 п.3)', () => {
  it('по умолчанию — все включены: бот Telegram (050), WhatsApp, Telegram, SMS', () => {
    expect(parseChannelSetting(null)).toEqual([
      { id: 'telegram_bot', enabled: true },
      { id: 'whatsapp', enabled: true },
      { id: 'telegram', enabled: true },
      { id: 'sms', enabled: true },
    ]);
  });

  it('порядок сохраняется, мусор и повторы отбрасываются, недостающие — в конец выключенными', () => {
    expect(parseChannelSetting('[{"id":"sms","enabled":true},{"id":"x"},{"id":"sms","enabled":false},{"id":"telegram","enabled":false}]')).toEqual([
      // 050: в старой настройке бота нет — он добавляется первым и включённым.
      { id: 'telegram_bot', enabled: true },
      { id: 'sms', enabled: true },
      { id: 'telegram', enabled: false },
      { id: 'whatsapp', enabled: false },
    ]);
  });

  it('050: бот Telegram — не канал кода, но в порядке «Каналов входа»', () => {
    expect(isValidChannelSetting('[{"id":"telegram_bot","enabled":false},{"id":"sms","enabled":true}]')).toBe(true);
    expect(parseChannelSetting('[{"id":"sms","enabled":true},{"id":"telegram_bot","enabled":false}]').slice(0, 2)).toEqual([
      { id: 'sms', enabled: true },
      { id: 'telegram_bot', enabled: false },
    ]);
  });

  it('проверка значения из админки', () => {
    expect(isValidChannelSetting('[{"id":"telegram","enabled":true},{"id":"sms","enabled":false}]')).toBe(true);
    expect(isValidChannelSetting('[{"id":"viber","enabled":true}]')).toBe(false);
    expect(isValidChannelSetting('not json')).toBe(false);
  });
});
