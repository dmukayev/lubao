import { isValidIinOrBin, isValidUscc, isValidVinFormat, matchesKzPlateFormat, vinCheckDigitOk } from './checksums';
import { namesLikelyMatch } from './name-match';
import { IdentifierTypeValue, transliterateCyrillicLookalikes } from '../identifiers/normalize';

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

/// В алфавите USCC нет I/O/S/Z (GB 32100) — если OCR выдал их в 18-значном
/// коде, это почти наверняка 1/0/5/2 (на синтетическом 营业执照 Tesseract
/// прочитал «…D01R» как «…DOIR», и код не находился вовсе).
const USCC_OCR_FIXES: Record<string, string> = { I: '1', O: '0', S: '5', Z: '2' };

function extractUscc(lines: string[]): RecognizedField | null {
  const candidates = (joinedText(lines).toUpperCase().match(/[0-9A-Z]{18}/g) ?? [])
    .map((c) => c.replace(/[IOSZ]/g, (ch) => USCC_OCR_FIXES[ch]!))
    .filter((c) => /^[0-9A-HJ-NPQRTUWXY]{18}$/.test(c));
  for (const candidate of candidates) {
    if (isValidUscc(candidate)) return field(candidate, 0.95, true);
  }
  if (candidates.length > 0) return field(candidates[0]!, 0.4, false);
  return null;
}

function extractVin(lines: string[]): RecognizedField | null {
  // Кириллические двойники → латиница ДО шаблона (032, п.9): OCR на VIN
  // ВАЗа часто отдаёт «ХТА…» кириллицей, и [A-HJ-NPR-Z0-9] его не ловил.
  const candidates = transliterateCyrillicLookalikes(joinedText(lines).toUpperCase()).match(/[A-HJ-NPR-Z0-9]{17}/g) ?? [];
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
// подойдёт под формат прицепа (2 цифры + 3 буквы + 2 региона). В позициях
// цифр допускаем «O» (OCR путает нуль с буквой): после матча чиним на «0».
const PLATE_STANDARD_RE = /[\dO]{3}[A-Z]{3}[\dO]{2}/;
const PLATE_TRAILER_RE = /[\dO]{2}[A-Z]{3}[\dO]{2}/;

function fixPlateDigits(plate: string): string {
  const letters = plate.length === 8 ? [3, 6] : [2, 5];
  return plate
    .split('')
    .map((ch, i) => (i < letters[0] || i >= letters[1] ? (ch === 'O' ? '0' : ch) : ch))
    .join('');
}

function extractPlate(lines: string[]): RecognizedField | null {
  for (const rawLine of lines) {
    // Транслитерация до шаблона (032, п.9): «123 АВС 02» кириллицей.
    const compact = transliterateCyrillicLookalikes(rawLine.toUpperCase()).replace(/[\s-]+/g, '');
    const match = compact.match(PLATE_STANDARD_RE) ?? compact.match(PLATE_TRAILER_RE);
    if (!match) continue;
    const plate = fixPlateDigits(match[0]);
    const kind = matchesKzPlateFormat(plate);
    if (kind) return field(plate, 0.9, true);
  }
  return null;
}

const DATE_RE = /\b(\d{2})[.\/](\d{2})[.\/](\d{4})\b/;

const DATE_G_RE = /\b(\d{2})[.\/](\d{2})[.\/](\d{4})\b/g;

function dateKey(d: string): string {
  const [dd, mm, yyyy] = d.split(/[.\/]/);
  return `${yyyy}${mm}${dd}`;
}

/// Права РК/ЕС пронумерованы по Венской конвенции: 3 — дата рождения,
/// 4a — выдачи, 4b — срок действия. Сначала ищем «4b» (OCR путает латинскую
/// b с кириллическими б/в/ь), иначе — самая поздняя дата на документе:
/// срок действия всегда позже рождения и выдачи (раньше брали первую дату,
/// и на реальной раскладке это была дата рождения или выдачи).
function extractExpiryDate(lines: string[]): RecognizedField | null {
  const labeled = joinedText(lines).match(/\b4\s?[bбвь][.)]?\s*(\d{2}[.\/]\d{2}[.\/]\d{4})/i);
  if (labeled) return field(labeled[1]!, 0.8, null);
  const dates = joinedText(lines).match(DATE_G_RE) ?? [];
  if (dates.length === 0) return null;
  const latest = dates.reduce((a, b) => (dateKey(b) > dateKey(a) ? b : a));
  return field(latest, 0.6, null);
}

/// Дата рождения — поле «3.»; сверяется с первыми шестью цифрами ИИН
/// (ГГММДД) — это и есть её «контрольная сумма».
function extractBirthDate(lines: string[], iin: string | undefined): RecognizedField | null {
  // Разделители OCR теряет («3. 12.041988») — допускаем их отсутствие.
  const labeled = joinedText(lines).match(/(?:^|\s)3[.)]\s*(\d{2})[.\/]?(\d{2})[.\/]?(\d{4})\b/m);
  if (!labeled) return null;
  const [, dd, mm, yyyy] = labeled;
  const value = `${dd}.${mm}.${yyyy}`;
  if (!iin) return field(value, 0.6, null);
  const ok = iin.startsWith(`${yyyy!.slice(2)}${mm}${dd}`);
  return field(value, ok ? 0.9 : 0.5, ok);
}

/// ФИО на правах — поля «1.» (фамилия) и «2.» (имя, отчество) отдельными
/// строками; с цифрой в начале их не берёт общий фильтр «похоже на ФИО».
function extractNumberedFullName(lines: string[], profileFullName?: string): RecognizedField | null {
  const part = (n: string) =>
    lines.map((l) => l.trim().match(new RegExp(`^${n}[.)]\\s*([\\p{L}][\\p{L}\\s'-]{1,60})$`, 'u'))).find(Boolean)?.[1]?.trim();
  const surname = part('1');
  const given = part('2');
  if (!surname || !given) return null;
  const value = `${surname} ${given}`;
  if (profileFullName) return field(value, namesLikelyMatch(value, profileFullName) ? 0.9 : 0.5, namesLikelyMatch(value, profileFullName));
  return field(value, 0.6, null);
}

/// Строка «похожа на ФИО»: 2-4 слова, только буквы (кирилл./лат./кит.),
/// без цифр — достаточно грубый фильтр, чтобы не ловить номера/даты.
const NAME_LINE_RE = /^[\p{L}\s'-]{4,80}$/u;

/// Заголовок документа («ҚАЗАҚСТАН РЕСПУБЛИКАСЫ», «РЕСПУБЛИКА КАЗАХСТАН»,
/// «ЖЕКЕ КУӘЛІК», «УДОСТОВЕРЕНИЕ ЛИЧНОСТИ», «ЖүРГІЗУШІ КУӘЛІГІ»...) тоже
/// проходит NAME_LINE_RE — чистые буквы, 2+ слова — но это не ФИО (задача
/// 032, п.8а: сначала найдено на синтетическом тесте, подтверждено на
/// реальном документе пользователя). Чаще всего это САМАЯ ВЕРХНЯЯ строка
/// документа, поэтому без фильтра побеждает как `candidates[0]`.
const DOCUMENT_BOILERPLATE_RE = /КАЗАХСТАН|ҚАЗАҚСТАН|KAZAKHSTAN|РЕСПУБЛИК|УДОСТОВЕРЕНИЕ|КУӘЛІК|ЛИЧНОСТИ|ПАСПОРТ|ВОДИТЕЛЬСК|ЖҮРГІЗУШІ/iu;

function extractFullName(lines: string[], profileFullName?: string): RecognizedField | null {
  const candidates = lines
    .map((l) => l.trim())
    .filter((l) => NAME_LINE_RE.test(l) && l.split(/\s+/).length >= 2 && !DOCUMENT_BOILERPLATE_RE.test(l));
  if (candidates.length === 0) return null;

  if (profileFullName) {
    const match = candidates.find((c) => namesLikelyMatch(c, profileFullName));
    if (match) return field(match, 0.9, true);
  }
  // Ни один кандидат не совпал с профилем (или профиль не передали) —
  // лучшая догадка всё равно полезна админу, но помечена на проверку.
  return field(candidates[0], 0.5, profileFullName ? false : null);
}

/// Название юрлица: по метке («Наименование», «Атауы», «名称» — с пробелами
/// внутри, как печатают в 营业执照) или по организационно-правовой форме
/// (ТОО/АО/ИП/ЖШС/LLP, …有限公司). Раньше бралась первая «похожая на ФИО»
/// строка — в справке это подзаголовок, в китайской лицензии — мусор.
const COMPANY_LABEL_RE = /^(?:наименование|атауы|名\s*称)\s*[:：]?\s*(.*)$/iu;
const COMPANY_FORM_RE = /(?:^|\s)(?:ТОО|АО|ИП|ЖШС|LLP|LLC)\s+\S|有限公司|股份公司/u;

function extractCompanyName(lines: string[]): RecognizedField | null {
  const trimmed = lines.map((l) => l.trim()).filter(Boolean);
  for (let i = 0; i < trimmed.length; i++) {
    const m = trimmed[i]!.match(COMPANY_LABEL_RE);
    if (!m) continue;
    const value = (m[1] || trimmed[i + 1] || '').trim();
    if (value.length >= 3) return field(value, 0.8, null);
  }
  const byForm = trimmed.find((l) => COMPANY_FORM_RE.test(l));
  if (byForm) return field(byForm, 0.7, null);
  return extractFullName(lines);
}

function extractLicenseNumber(lines: string[]): RecognizedField | null {
  // Номер прав РК/РФ/КНР — довольно разные форматы; берём общий паттерн
  // «буквы+цифры, 6-12 символов» и полагаемся на needsReview по умолчанию
  // (confidence ниже порога) — контрольной суммы для этого поля нет.
  const match = transliterateCyrillicLookalikes(joinedText(lines).toUpperCase())
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
      set('fullName', extractNumberedFullName(lines, context.profileFullName) ?? extractFullName(lines, context.profileFullName));
      set('iin', extractIinOrBin(lines));
      set('birthDate', extractBirthDate(lines, fields.iin?.checksumOk ? fields.iin.value : undefined));
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
      set('companyName', extractCompanyName(lines));
      set('bin', extractIinOrBin(lines));
      set('uscc', extractUscc(lines));
      break;
    default:
      break;
  }

  return fields;
}
