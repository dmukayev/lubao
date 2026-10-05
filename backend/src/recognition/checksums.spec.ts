import { isValidIinOrBin, isValidUscc, isValidVinFormat, matchesKzPlateFormat, vinCheckDigitOk } from './checksums';

/// Контрольные цифры строятся прогоном того же алгоритма «вперёд»
/// (синтетические, не настоящие ИИН/BIN людей — задача 031, п.21:
/// «без реальных данных людей»), а не подбираются руками — так тест ловит
/// implementation bug в самой формуле весов/модуля, а не опечатку в
/// примере.
function buildValidIin(first11: string): string {
  const digits = first11.split('').map(Number);
  const w1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  const w2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];
  let check = digits.reduce((sum, d, i) => sum + d * w1[i], 0) % 11;
  if (check === 10) check = digits.reduce((sum, d, i) => sum + d * w2[i], 0) % 11;
  return first11 + String(check);
}

describe('isValidIinOrBin — задача 031, этап D, п.19', () => {
  it('accepts a synthetically constructed valid IIN (round-trip through the same algorithm)', () => {
    const iin = buildValidIin('85071234561');
    expect(isValidIinOrBin(iin)).toBe(true);
  });

  it('rejects the same number with the last digit flipped', () => {
    const iin = buildValidIin('85071234561');
    const lastDigit = Number(iin[11]);
    const corrupted = iin.slice(0, 11) + String((lastDigit + 1) % 10);
    expect(isValidIinOrBin(corrupted)).toBe(false);
  });

  it('rejects wrong length and non-digit input', () => {
    expect(isValidIinOrBin('123')).toBe(false);
    expect(isValidIinOrBin('85071234a561')).toBe(false);
  });
});

describe('isValidUscc — задача 031, этап D, п.19 (GB 32100-2015)', () => {
  const ALPHABET = '0123456789ABCDEFGHJKLMNPQRTUWXY';
  const WEIGHTS = [1, 3, 9, 27, 19, 26, 16, 17, 20, 29, 25, 13, 8, 24, 10, 30, 28];

  function buildValidUscc(first17: string): string {
    const chars = first17.toUpperCase().split('');
    const sum = chars.reduce((acc, c, i) => acc + ALPHABET.indexOf(c) * WEIGHTS[i], 0);
    const remainder = sum % 31;
    const checkValue = remainder === 0 ? 0 : 31 - remainder;
    return first17 + ALPHABET[checkValue];
  }

  it('accepts a synthetically constructed valid USCC', () => {
    const uscc = buildValidUscc('91110000MA00ABCDE');
    expect(isValidUscc(uscc)).toBe(true);
  });

  it('rejects a corrupted check character', () => {
    const uscc = buildValidUscc('91110000MA00ABCDE');
    const corrupted = uscc.slice(0, 17) + (uscc[17] === '0' ? '1' : '0');
    expect(isValidUscc(corrupted)).toBe(false);
  });

  it('rejects wrong length and disallowed characters (I/O/S/V/Z)', () => {
    expect(isValidUscc('SHORT')).toBe(false);
    expect(isValidUscc('9111000OMA00ABCD12')).toBe(false); // contains 'O'
  });
});

describe('VIN — задача 031, этап D, п.19', () => {
  function buildValidVinCheckDigit(without9th: string): string {
    // without9th — 16 известных символов, позиция 9 временно '0'.
    const vin = without9th.slice(0, 8) + '0' + without9th.slice(8);
    const translit: Record<string, number> = {
      A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8,
      J: 1, K: 2, L: 3, M: 4, N: 5, P: 7, R: 9,
      S: 2, T: 3, U: 4, V: 5, W: 6, X: 7, Y: 8, Z: 9,
    };
    const weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];
    const values = vin.split('').map((c) => (c >= '0' && c <= '9' ? Number(c) : translit[c]));
    const sum = values.reduce((acc, v, i) => acc + v * weights[i], 0);
    const remainder = sum % 11;
    const check = remainder === 10 ? 'X' : String(remainder);
    return vin.slice(0, 8) + check + vin.slice(9);
  }

  it('accepts a valid 17-char format (no I/O/Q)', () => {
    expect(isValidVinFormat('1HGCM82633A004352')).toBe(true); // 17 chars
    expect(isValidVinFormat('1HGCM82633A00435')).toBe(false); // 16 chars — too short
  });

  it('rejects VINs containing I, O or Q', () => {
    expect(isValidVinFormat('1HGCM8263IA004352'.slice(0, 17))).toBe(false);
  });

  it('check digit round-trips through the same NHTSA algorithm (hint only — never rejects outright, see recognition.service.ts)', () => {
    const vin = buildValidVinCheckDigit('XTA123456AB78901');
    expect(vinCheckDigitOk(vin)).toBe(true);
  });

  it('flags a corrupted check digit', () => {
    const vin = buildValidVinCheckDigit('XTA123456AB78901');
    const corrupted = vin.slice(0, 8) + (vin[8] === '0' ? '1' : '0') + vin.slice(9);
    expect(vinCheckDigitOk(corrupted)).toBe(false);
  });
});

describe('matchesKzPlateFormat — задача 031, этап D, п.19', () => {
  it('matches the standard individual/legal format (3 digits + 3 letters + 2-digit region)', () => {
    expect(matchesKzPlateFormat('123ABC02')).toBe('STANDARD');
    expect(matchesKzPlateFormat('777ABP05')).toBe('STANDARD');
  });

  it('matches the trailer format (2 digits + 3 letters + 2-digit region)', () => {
    expect(matchesKzPlateFormat('45ABC05')).toBe('TRAILER');
  });

  it('returns null for anything else', () => {
    expect(matchesKzPlateFormat('ABC123')).toBeNull();
    expect(matchesKzPlateFormat('新A12345')).toBeNull();
  });
});
