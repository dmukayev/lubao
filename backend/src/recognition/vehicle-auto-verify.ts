import { VerificationDocType } from '@prisma/client';
import { normalizeIdentifier } from '../identifiers/normalize';
import { isValidVinFormat, matchesKzPlateFormat, vinCheckDigitOk } from './checksums';
import { RecognizedFields } from './extract-fields';

/// Порог уверенности распознавания для автопроверки (044 п.6).
export const AUTO_VERIFY_MIN_CONFIDENCE = 0.85;

export type AutoVerifyDecision =
  | { ok: true; vin: string; plate: string }
  | { ok: false; reason: 'NOT_A_PASSPORT' | 'VIN_MISSING' | 'VIN_INVALID' | 'PLATE_MISSING' | 'PLATE_INVALID' | 'LOW_CONFIDENCE' | 'MISMATCH' };

/// Можно ли подтвердить машину без админа (decisions.md 2026-10-07): VIN
/// корректен по формату и контрольной цифре, госномер — по шаблону РК, оба
/// прочитаны уверенно и совпадают с тем, что ввёл водитель. Чёрный список
/// проверяет вызывающий (нужна БД). Не прошло — как раньше, в очередь админу.
export function autoVerifyDecision(
  docType: VerificationDocType,
  fields: RecognizedFields,
  vehicle: { plateNumber: string | null; vin: string | null },
): AutoVerifyDecision {
  if (docType !== 'VEHICLE_PASSPORT' && docType !== 'TRAILER_PASSPORT') return { ok: false, reason: 'NOT_A_PASSPORT' };
  const vinField = fields.vin;
  const plateField = fields.plateNumber;
  if (!vinField?.value) return { ok: false, reason: 'VIN_MISSING' };
  if (!plateField?.value) return { ok: false, reason: 'PLATE_MISSING' };
  const vin = normalizeIdentifier('VIN', vinField.value);
  const plate = normalizeIdentifier('PLATE', plateField.value);
  if (!isValidVinFormat(vin) || !vinCheckDigitOk(vin)) return { ok: false, reason: 'VIN_INVALID' };
  if (!matchesKzPlateFormat(plate)) return { ok: false, reason: 'PLATE_INVALID' };
  if (vinField.confidence < AUTO_VERIFY_MIN_CONFIDENCE || plateField.confidence < AUTO_VERIFY_MIN_CONFIDENCE) {
    return { ok: false, reason: 'LOW_CONFIDENCE' };
  }
  const same = (type: 'VIN' | 'PLATE', entered: string | null, recognized: string) => !entered || normalizeIdentifier(type, entered) === recognized;
  if (!same('VIN', vehicle.vin, vin) || !same('PLATE', vehicle.plateNumber, plate)) return { ok: false, reason: 'MISMATCH' };
  return { ok: true, vin, plate };
}
