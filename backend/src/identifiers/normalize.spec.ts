import { normalizeGeneric, normalizeIdentifier, normalizePhone, normalizePlate } from './normalize';

describe('normalizePlate — задача 031, этап C, п.12', () => {
  it('strips spaces and hyphens and uppercases', () => {
    expect(normalizePlate('123 abc-02')).toBe('123ABC02');
  });

  it('maps cyrillic look-alike letters to latin', () => {
    expect(normalizePlate('А123ВЕ77')).toBe('A123BE77');
    expect(normalizePlate('777 АВР 05')).toBe('777ABP05');
  });

  it('leaves non-look-alike cyrillic untouched (not a valid plate, but must not crash)', () => {
    expect(normalizePlate('新A12345')).toBe('新A12345');
  });
});

describe('normalizePhone', () => {
  it('strips formatting and keeps a leading +', () => {
    expect(normalizePhone('+7 (701) 123-45-01')).toBe('+77011234501');
  });

  it('adds a leading + if missing', () => {
    expect(normalizePhone('77011234501')).toBe('+77011234501');
  });
});

describe('normalizeGeneric (IIN/VIN/BIN/USCC/license)', () => {
  it('strips spaces/hyphens and uppercases', () => {
    expect(normalizeGeneric('xta 123456 ab 789012')).toBe('XTA123456AB789012');
  });
});

describe('normalizeIdentifier dispatch', () => {
  it('routes PLATE through normalizePlate', () => {
    expect(normalizeIdentifier('PLATE', 'А123ВЕ77')).toBe('A123BE77');
  });

  it('routes PHONE through normalizePhone', () => {
    expect(normalizeIdentifier('PHONE', '+7 701 123 45 01')).toBe('+77011234501');
  });

  it('routes everything else through normalizeGeneric', () => {
    expect(normalizeIdentifier('IIN', '850712300123')).toBe('850712300123');
  });
});
