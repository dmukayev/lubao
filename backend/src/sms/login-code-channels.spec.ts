import { isValidChannelSetting, parseChannelSetting } from './login-code-channels';

describe('настройка каналов кода (042 п.3)', () => {
  it('по умолчанию — все три включены: WhatsApp, Telegram, SMS', () => {
    expect(parseChannelSetting(null)).toEqual([
      { id: 'whatsapp', enabled: true },
      { id: 'telegram', enabled: true },
      { id: 'sms', enabled: true },
    ]);
  });

  it('порядок сохраняется, мусор и повторы отбрасываются, недостающие — в конец выключенными', () => {
    expect(parseChannelSetting('[{"id":"sms","enabled":true},{"id":"x"},{"id":"sms","enabled":false},{"id":"telegram","enabled":false}]')).toEqual([
      { id: 'sms', enabled: true },
      { id: 'telegram', enabled: false },
      { id: 'whatsapp', enabled: false },
    ]);
  });

  it('проверка значения из админки', () => {
    expect(isValidChannelSetting('[{"id":"telegram","enabled":true},{"id":"sms","enabled":false}]')).toBe(true);
    expect(isValidChannelSetting('[{"id":"viber","enabled":true}]')).toBe(false);
    expect(isValidChannelSetting('not json')).toBe(false);
  });
});
