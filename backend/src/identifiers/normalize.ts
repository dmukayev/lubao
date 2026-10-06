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

/// Задача 032, п.9 (хвост, закрыт в 038) — кириллические двойники сводятся
/// к латинице не только в госномере, но и в VIN («ХТА…» у ВАЗа OCR часто
/// отдаёт кириллицей) и номере прав: иначе «тот же» идентификатор,
/// набранный в другом алфавите, давал другой хеш и проходил мимо чёрного
/// списка. Экспортируется для extract-fields (сопоставление с шаблоном —
/// тоже ПОСЛЕ транслитерации).
export function transliterateCyrillicLookalikes(value: string): string {
  return value.replace(/[АВЕКМНОРСТХ]/g, (ch) => CYRILLIC_TO_LATIN_PLATE[ch] ?? ch);
}

export function normalizePlate(value: string): string {
  const upper = stripSpacesAndHyphens(value).toUpperCase();
  return transliterateCyrillicLookalikes(upper);
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
    case 'VIN':
    case 'DRIVER_LICENSE_NO':
      // Те же двойники, что на госномерах (032, п.9).
      return transliterateCyrillicLookalikes(normalizeGeneric(rawValue));
    case 'PHONE':
      return normalizePhone(rawValue);
    default:
      return normalizeGeneric(rawValue);
  }
}
