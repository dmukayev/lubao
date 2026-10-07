import { levenshteinDistance, namesLikelyMatch, normalizeForMatch } from './name-match';

describe('normalizeForMatch', () => {
  it('lowercases, folds ё and kazakh letters, strips spaces/hyphens', () => {
    expect(normalizeForMatch('Ерлан Қасымов')).toBe('ерланкасымов');
    expect(normalizeForMatch('Алёна Тё-Иванова')).toBe('аленатеиванова');
  });
});

describe('namesLikelyMatch — задача 031, этап D, п.19', () => {
  it('matches identical cyrillic names', () => {
    expect(namesLikelyMatch('Ерлан Тохтаров', 'Ерлан Тохтаров')).toBe(true);
  });

  it('matches a latin OCR reading against a cyrillic profile name (transliteration)', () => {
    expect(namesLikelyMatch('Erlan Tokhtarov', 'Ерлан Тохтаров')).toBe(true);
  });

  it('tolerates a single OCR misread character', () => {
    expect(namesLikelyMatch('Ерлан Тохтвров', 'Ерлан Тохтаров')).toBe(true); // а -> в misread
  });

  it('does not match a genuinely different name', () => {
    expect(namesLikelyMatch('Виктор Ковалёв', 'Ерлан Тохтаров')).toBe(false);
  });

  it('does not match short names off by even one character (too easy to collide)', () => {
    expect(namesLikelyMatch('Ли', 'Ли Вэй')).toBe(false);
  });
});

describe('levenshteinDistance', () => {
  it('is 0 for identical strings', () => {
    expect(levenshteinDistance('абв', 'абв')).toBe(0);
  });

  it('counts a single substitution as distance 1', () => {
    expect(levenshteinDistance('кот', 'кит')).toBe(1);
  });

  it('counts insertions/deletions', () => {
    expect(levenshteinDistance('кот', 'котик')).toBe(2);
  });

  it('порядок слов и отчество не мешают: «ТЕСТОВ ЕРЛАН БОЛАТОВИЧ» ~ «Ерлан Тестов»', () => {
    expect(namesLikelyMatch('ТЕСТОВ ЕРЛАН БОЛАТОВИЧ', 'Ерлан Тестов')).toBe(true);
    expect(namesLikelyMatch('ТЕСТОВ ЕРЛАН БОЛАТОВИЧ', 'Ерлан Петров')).toBe(false);
    expect(namesLikelyMatch('ТЕСТОВ ЕРЛАН', 'Ерлан')).toBe(false);
  });
});
