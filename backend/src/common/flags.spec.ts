import { flagEmoji, routeFlags } from './flags';

describe('058 п.3: флаги стран маршрута', () => {
  it('код страны → эмодзи', () => {
    expect(flagEmoji('KZ')).toBe('🇰🇿');
    expect(flagEmoji('ge')).toBe('🇬🇪');
    expect(flagEmoji('XYZ')).toBe('');
  });

  it('флаги всегда — и внутри одной страны (decisions.md 2026-10-13)', () => {
    expect(routeFlags('KZ', 'KZ')).toEqual(['🇰🇿', '🇰🇿']);
    expect(routeFlags(null, 'KZ')).toEqual(['', '🇰🇿']);
    expect(routeFlags('KZ', 'UZ')).toEqual(['🇰🇿', '🇺🇿']);
  });
});
