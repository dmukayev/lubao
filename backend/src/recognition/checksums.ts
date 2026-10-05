/// Задача 031, этап D, п.19 — контрольные суммы: главная защита от ошибок
/// OCR. Поле без прошедшей проверки или с низкой уверенностью помечается
/// `needsReview` в recognition.service.ts, а не отклоняется само по себе
/// (кроме явно некорректного формата).

/// ИИН/БИН (РК) — 12 цифр, 12-я контрольная. Два прохода весов: если
/// первый даёт остаток 10 (неоднозначность), берём второй набор весов;
/// если и он даёт 10 — контрольную цифру посчитать нельзя, число невалидно.
const IIN_WEIGHTS_1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
const IIN_WEIGHTS_2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];

export function isValidIinOrBin(value: string): boolean {
  if (!/^\d{12}$/.test(value)) return false;
  const digits = value.split('').map(Number);

  const weighted = (weights: number[]) => digits.slice(0, 11).reduce((sum, d, i) => sum + d * weights[i], 0) % 11;

  let check = weighted(IIN_WEIGHTS_1);
  if (check === 10) check = weighted(IIN_WEIGHTS_2);
  if (check === 10) return false;
  return check === digits[11];
}

/// 统一社会信用代码 (GB 32100-2015) — 18 символов. Алфавит кода (31 символ,
/// без I/O/S/V/Z — визуально спутываемых с цифрами) и свои веса на каждую
/// из первых 17 позиций; 18-я — контрольная.
const USCC_ALPHABET = '0123456789ABCDEFGHJKLMNPQRTUWXY';
const USCC_WEIGHTS = [1, 3, 9, 27, 19, 26, 16, 17, 20, 29, 25, 13, 8, 24, 10, 30, 28];

export function isValidUscc(value: string): boolean {
  if (value.length !== 18) return false;
  const chars = value.toUpperCase().split('');
  if (!chars.every((c) => USCC_ALPHABET.includes(c))) return false;

  const sum = chars
    .slice(0, 17)
    .reduce((acc, c, i) => acc + USCC_ALPHABET.indexOf(c) * USCC_WEIGHTS[i], 0);
  const remainder = sum % 31;
  const checkValue = remainder === 0 ? 0 : 31 - remainder;
  return USCC_ALPHABET[checkValue] === chars[17];
}

/// VIN — 17 символов, без I/O/Q (визуально путаются с 1/0). Формат
/// проверяем всегда; контрольная цифра (позиция 9, стандарт Северной
/// Америки) — необязательна вне NA, поэтому возвращает null, если формат
/// в принципе не похож на VIN, а не бросает ошибку.
const VIN_TRANSLITERATION: Record<string, number> = {
  A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8,
  J: 1, K: 2, L: 3, M: 4, N: 5, P: 7, R: 9,
  S: 2, T: 3, U: 4, V: 5, W: 6, X: 7, Y: 8, Z: 9,
};
const VIN_WEIGHTS = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

export function isValidVinFormat(value: string): boolean {
  return /^[A-HJ-NPR-Z0-9]{17}$/.test(value.toUpperCase());
}

/// true/false — цифра совпала/не совпала; null — формат не VIN вовсе,
/// проверять нечего (вызывающий код уже отсеял это через isValidVinFormat).
export function vinCheckDigitOk(value: string): boolean {
  const vin = value.toUpperCase();
  const values = vin.split('').map((c) => (c >= '0' && c <= '9' ? Number(c) : (VIN_TRANSLITERATION[c] ?? NaN)));
  if (values.some((v) => Number.isNaN(v))) return false;

  const sum = values.reduce((acc, v, i) => acc + v * VIN_WEIGHTS[i], 0);
  const remainder = sum % 11;
  const expected = remainder === 10 ? 'X' : String(remainder);
  return vin[8] === expected;
}

/// Госномер РК (задача 031, п.19) — физлица/юрлица (3 цифры + 3 буквы + 2
/// региона) и прицепы (2 цифры + 3 буквы + 2 региона). Значение уже
/// нормализовано (кириллица → латинские двойники, без пробелов) до вызова.
export function matchesKzPlateFormat(value: string): 'STANDARD' | 'TRAILER' | null {
  if (/^\d{3}[A-Z]{3}\d{2}$/.test(value)) return 'STANDARD';
  if (/^\d{2}[A-Z]{3}\d{2}$/.test(value)) return 'TRAILER';
  return null;
}
