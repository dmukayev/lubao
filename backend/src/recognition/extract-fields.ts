import { isValidIinOrBin, isValidUscc, isValidVinFormat, matchesKzPlateFormat, vinCheckDigitOk } from './checksums';
import { namesLikelyMatch } from './name-match';
import { IdentifierTypeValue } from '../identifiers/normalize';

/// Какие ключи распознанных полей соответствуют типу идентификатора из
/// чёрного списка (задача 031, п.22) — используется и для живой проверки
/// при просмотре документа, и при подтверждении (задача 032, п.2/3/4).
export const RECOGNIZED_FIELD_IDENTIFIER_TYPE: Partial<Record<string, IdentifierTypeValue>> = {
  iin: 'IIN',
  bin: 'BIN',
  uscc: 'USCC',
  vin: 'VIN',
  plateNumber: 'PLATE',
  licenseNumber: 'DRIVER_LICENSE_NO',
};

export interface RecognizedField {
  value: string;
  confidence: number;
  /// null — для этого поля контрольной суммы не существует (например, ФИО).
  checksumOk: boolean | null;
  needsReview: boolean;
}

export type RecognizedFields = Record<string, RecognizedField>;

function field(value: string, confidence: number, checksumOk: boolean | null): RecognizedField {
  // Поле без прошедшей проверки или с низкой уверенностью -> «проверьте»
  // (задача 031, п.19) — отказ только в format-валидации самого поля, не
  // здесь.
  const needsReview = checksumOk === false || confidence < 0.7;
  return { value, confidence, checksumOk, needsReview };
}

function joinedText(lines: string[]): string {
  return lines.join('\n');
}

function findFirst(lines: string[], re: RegExp): string | null {
  for (const line of lines) {
    const m = line.match(re);
    if (m) return m[0];
  }
  return null;
}

/// 12 последовательных цифр, где-то в тексте — кандидат на ИИН/БИН.
function extractIinOrBin(lines: string[]): RecognizedField | null {
  const candidates = joinedText(lines).match(/\d{12}/g) ?? [];
  for (const candidate of candidates) {
    if (isValidIinOrBin(candidate)) return field(candidate, 0.95, true);
  }
  if (candidates.length > 0) return field(candidates[0]!, 0.4, false);
  return null;
}

function extractUscc(lines: string[]): RecognizedField | null {
  const candidates = joinedText(lines).toUpperCase().match(/[0-9A-HJ-NPQRTUWXY]{18}/g) ?? [];
  for (const candidate of candidates) {
    if (isValidUscc(candidate)) return field(candidate, 0.95, true);
  }
  if (candidates.length > 0) return field(candidates[0]!, 0.4, false);
  return null;
}

function extractVin(lines: string[]): RecognizedField | null {
  const candidates = joinedText(lines).toUpperCase().match(/[A-HJ-NPR-Z0-9]{17}/g) ?? [];
  for (const candidate of candidates) {
    if (!isValidVinFormat(candidate)) continue;
    // Контрольная цифра — подсказка, не отказ (п.19: необязательна вне
    // Северной Америки); формат уже прошёл, поэтому confidence высокий
    // в любом случае, а checksumOk просто сообщает, совпала ли цифра.
    const checkOk = vinCheckDigitOk(candidate);
    return { value: candidate, confidence: checkOk ? 0.95 : 0.75, checksumOk: checkOk, needsReview: !checkOk };
  }
  return null;
}

// Сначала «стандартный» формат (3 цифры) — иначе его хвост сам случайно
// подойдёт под формат прицепа (2 цифры + 3 буквы + 2 региона).
const PLATE_STANDARD_RE = /\d{3}[A-Z]{3}\d{2}/;
const PLATE_TRAILER_RE = /\d{2}[A-Z]{3}\d{2}/;

function extractPlate(lines: string[]): RecognizedField | null {
  for (const rawLine of lines) {
    const compact = rawLine.toUpperCase().replace(/[\s-]+/g, '');
    const match = compact.match(PLATE_STANDARD_RE) ?? compact.match(PLATE_TRAILER_RE);
    if (!match) continue;
    const kind = matchesKzPlateFormat(match[0]);
    if (kind) return field(match[0], 0.9, true);
  }
  return null;
}

const DATE_RE = /\b(\d{2})[.\/](\d{2})[.\/](\d{4})\b/;

function extractExpiryDate(lines: string[]): RecognizedField | null {
  const match = findFirst(lines, DATE_RE);
  if (!match) return null;
  return field(match, 0.6, null);
}

/// Строка «похожа на ФИО»: 2-4 слова, только буквы (кирилл./лат./кит.),
/// без цифр — достаточно грубый фильтр, чтобы не ловить номера/даты.
const NAME_LINE_RE = /^[\p{L}\s'-]{4,80}$/u;

function extractFullName(lines: string[], profileFullName?: string): RecognizedField | null {
  const candidates = lines.map((l) => l.trim()).filter((l) => NAME_LINE_RE.test(l) && l.split(/\s+/).length >= 2);
  if (candidates.length === 0) return null;

  if (profileFullName) {
    const match = candidates.find((c) => namesLikelyMatch(c, profileFullName));
    if (match) return field(match, 0.9, true);
  }
  // Ни один кандидат не совпал с профилем (или профиль не передали) —
  // лучшая догадка всё равно полезна админу, но помечена на проверку.
  return field(candidates[0], 0.5, profileFullName ? false : null);
}

function extractLicenseNumber(lines: string[]): RecognizedField | null {
  // Номер прав РК/РФ/КНР — довольно разные форматы; берём общий паттерн
  // «буквы+цифры, 6-12 символов» и полагаемся на needsReview по умолчанию
  // (confidence ниже порога) — контрольной суммы для этого поля нет.
  const match = joinedText(lines)
    .toUpperCase()
    .match(/\b[A-Z0-9]{2}\s?\d{6,9}\b/);
  if (!match) return null;
  return field(match[0].replace(/\s+/g, ''), 0.5, null);
}

/// Грузоподъёмность = макс. масса − масса без нагрузки (решение
/// 2026-10-04). OCR-текст техпаспорта обычно даёт два веса рядом —
/// берём первые два правдоподобных числа в кг, если оба нашлись.
function extractCapacityTons(lines: string[]): RecognizedField | null {
  // Без конечного \b: JS \b опирается на [A-Za-z0-9_], кириллическая «кг»
  // не входит в \w, так что \b перед ней никогда не совпадёт — граница
  // нужна только перед цифрами (сам \d уже \w).
  const numbers = (joinedText(lines).match(/\b\d{3,5}(?=\s?(?:кг|kg))/gi) ?? []).map((m) => parseInt(m, 10));
  if (numbers.length < 2) return null;
  const [maxMass, tareMass] = numbers;
  if (maxMass <= tareMass) return null;
  const tons = ((maxMass - tareMass) / 1000).toFixed(1);
  return field(tons, 0.5, null);
}

function extractBrand(lines: string[]): RecognizedField | null {
  // Чаще марка идёт после метки «Марка:» в той же строке техпаспорта.
  for (const line of lines) {
    const labeled = line.match(/марка[:\s]+([\p{L}\d]{2,20})/iu);
    if (labeled) return field(labeled[1]!, 0.6, null);
  }
  // Без метки — берём первую отдельно стоящую строку из одного «слова»
  // (частые марки — латиницей: MAN, Volvo, Shacman...), отдельно от
  // ФИО-паттерна (который требует 2+ слов).
  const standalone = lines.map((l) => l.trim()).find((l) => /^[\p{L}]{2,20}$/u.test(l));
  if (!standalone) return null;
  return field(standalone, 0.4, null);
}

/// Задача 031, этап D, п.18/20 — разбор строк OCR в структурированные
/// поля по типу документа. Поле без прошедшей проверки или с низкой
/// уверенностью -> needsReview, extractFields никогда не бросает
/// исключение на «нечитаемом» документе — просто возвращает меньше полей.
export function extractFields(
  documentType: string,
  lines: string[],
  context: { profileFullName?: string } = {},
): RecognizedFields {
  const fields: RecognizedFields = {};
  const set = (key: string, value: RecognizedField | null) => {
    if (value) fields[key] = value;
  };

  switch (documentType) {
    case 'DRIVER_LICENSE':
      set('fullName', extractFullName(lines, context.profileFullName));
      set('iin', extractIinOrBin(lines));
      set('licenseNumber', extractLicenseNumber(lines));
      set('expiryDate', extractExpiryDate(lines));
      break;
    case 'IDENTITY':
      set('fullName', extractFullName(lines, context.profileFullName));
      set('iin', extractIinOrBin(lines));
      break;
    case 'VEHICLE_PASSPORT':
      set('plateNumber', extractPlate(lines));
      set('vin', extractVin(lines));
      set('brand', extractBrand(lines));
      break;
    case 'TRAILER_PASSPORT':
      set('plateNumber', extractPlate(lines));
      set('vin', extractVin(lines));
      set('capacityTons', extractCapacityTons(lines));
      break;
    case 'COMPANY_REGISTRATION':
      set('companyName', extractFullName(lines));
      set('bin', extractIinOrBin(lines));
      set('uscc', extractUscc(lines));
      break;
    default:
      break;
  }

  return fields;
}
