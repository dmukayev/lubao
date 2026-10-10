import { flagEmoji, routeFlags } from './flags';

describe('058 п.3: флаги стран маршрута', () => {
  it('код страны → эмодзи', () => {
    expect(flagEmoji('KZ')).toBe('🇰🇿');
    expect(flagEmoji('ge')).toBe('🇬🇪');
    expect(flagEmoji('XYZ')).toBe('');
  });

  it('маршрут внутри одной страны — без флагов', () => {
    expect(routeFlags('KZ', 'KZ')).toEqual(['', '']);
    expect(routeFlags('KZ', 'UZ')).toEqual(['🇰🇿', '🇺🇿']);
  });
});
