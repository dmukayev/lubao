import { maskEmail, maskPhone, scrubText } from './mask';

describe('маски для логов (задача 043, п.6)', () => {
  it('телефон: код страны и 2 последние цифры', () => {
    expect(maskPhone('+77010000001')).toBe('+7701***01');
    expect(maskPhone('7 701 000 00 01')).toBe('+7701***01');
    expect(maskPhone('123')).toBe('***');
  });

  it('email: первая буква и домен', () => {
    expect(maskEmail('logist@example.com')).toBe('l***@example.com');
    expect(maskEmail('nonsense')).toBe('***');
  });

  it('scrubText вырезает телефоны, ИИН и email из произвольного текста', () => {
    const text = 'Не удалось отправить на +77010000001 (ИИН 950302502008), копия logist@example.com; код 1234';
    const scrubbed = scrubText(text);
    expect(scrubbed).not.toContain('77010000001');
    expect(scrubbed).not.toContain('950302502008');
    expect(scrubbed).not.toContain('logist@');
    expect(scrubbed).toContain('код 1234');
  });

  it('обычные числа (суммы, id) не трогает', () => {
    expect(scrubText('rows=15, price=1500, status 429')).toBe('rows=15, price=1500, status 429');
    expect(scrubText('2026-10-07 12:00, order 1234567')).toBe('2026-10-07 12:00, order 1234567');
  });
});
