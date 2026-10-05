/// Задача 031, этап C, п.12 — нормализация перед хешем/шифрованием: верхний
/// регистр, без пробелов/дефисов; госномер — кириллица сводится к
/// латинским двойникам (на госномерах РК/РФ/КНР встречаются буквы,
/// одинаковые по начертанию в обоих алфавитах); телефон — E.164.
const CYRILLIC_TO_LATIN_PLATE: Record<string, string> = {
  А: 'A',
  В: 'B',
  Е: 'E',
  К: 'K',
  М: 'M',
  Н: 'H',
  О: 'O',
  Р: 'P',
  С: 'C',
  Т: 'T',
  Х: 'X',
};

function stripSpacesAndHyphens(value: string): string {
  return value.replace(/[\s-]+/g, '');
}

export function normalizePlate(value: string): string {
  const upper = stripSpacesAndHyphens(value).toUpperCase();
  return upper.replace(/[АВЕКМНОРСТХ]/g, (ch) => CYRILLIC_TO_LATIN_PLATE[ch] ?? ch);
}

export function normalizePhone(value: string): string {
  const digits = value.replace(/[^\d+]/g, '');
  return digits.startsWith('+') ? digits : `+${digits}`;
}

export function normalizeGeneric(value: string): string {
  return stripSpacesAndHyphens(value).toUpperCase();
}

export type IdentifierTypeValue = 'IIN' | 'DRIVER_LICENSE_NO' | 'VIN' | 'PLATE' | 'BIN' | 'USCC' | 'PHONE';

export function normalizeIdentifier(type: IdentifierTypeValue, rawValue: string): string {
  switch (type) {
    case 'PLATE':
      return normalizePlate(rawValue);
    case 'PHONE':
      return normalizePhone(rawValue);
    default:
      return normalizeGeneric(rawValue);
  }
}
