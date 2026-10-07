import { autoVerifyDecision } from './vehicle-auto-verify';

// 044 п.6: автопроверка машины по распознанному техпаспорту.
const f = (value: string, confidence = 0.95, checksumOk: boolean | null = true) => ({ value, confidence, checksumOk, needsReview: false });
// 1M8GDM9AXKP042788 — корректная контрольная цифра (X).
const GOOD_VIN = '1M8GDM9AXKP042788';

describe('autoVerifyDecision', () => {
  it('корректные VIN и госномер, совпадают с введёнными — проходит', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { vin: f(GOOD_VIN), plateNumber: f('123ABC02', 0.9) }, { plateNumber: '123 ABC 02', vin: null })).toEqual({
      ok: true,
      vin: GOOD_VIN,
      plate: '123ABC02',
    });
  });

  it('прицеп: госномер прицепа (2 цифры) тоже проходит', () => {
    expect(autoVerifyDecision('TRAILER_PASSPORT', { vin: f(GOOD_VIN), plateNumber: f('12ABC02') }, { plateNumber: null, vin: null }).ok).toBe(true);
  });

  it('плохая контрольная цифра VIN — нет', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { vin: f('1M8GDM9A1KP042788'), plateNumber: f('123ABC02') }, { plateNumber: null, vin: null })).toEqual({ ok: false, reason: 'VIN_INVALID' });
  });

  it('госномер не по шаблону — нет', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { vin: f(GOOD_VIN), plateNumber: f('A123BC') }, { plateNumber: null, vin: null })).toEqual({ ok: false, reason: 'PLATE_INVALID' });
  });

  it('неуверенно прочитано — нет', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { vin: f(GOOD_VIN, 0.7), plateNumber: f('123ABC02') }, { plateNumber: null, vin: null })).toEqual({ ok: false, reason: 'LOW_CONFIDENCE' });
  });

  it('распознано не то, что ввёл водитель — нет', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { vin: f(GOOD_VIN), plateNumber: f('123ABC02') }, { plateNumber: '777ZZZ02', vin: null })).toEqual({ ok: false, reason: 'MISMATCH' });
  });

  it('чего-то нет или это не техпаспорт — нет', () => {
    expect(autoVerifyDecision('VEHICLE_PASSPORT', { plateNumber: f('123ABC02') }, { plateNumber: null, vin: null }).ok).toBe(false);
    expect(autoVerifyDecision('SELFIE', { vin: f(GOOD_VIN), plateNumber: f('123ABC02') }, { plateNumber: null, vin: null })).toEqual({ ok: false, reason: 'NOT_A_PASSPORT' });
  });
});
