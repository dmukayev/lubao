import * as fs from 'fs';
import * as path from 'path';
import { extractFields } from './extract-fields';

/// Задача 031, этап D, п.21 — синтетические фикстуры «текста», как если бы
/// его вернул OCR-движок, вместо настоящих отрисованных изображений
/// документов (которые недоступны в этой среде и не могут быть реальными
/// данными людей по условию задачи). Файлы — backend/test/fixtures/ocr/.
const FIXTURES_DIR = path.join(__dirname, '../../test/fixtures/ocr');

interface Fixture {
  note: string;
  documentType: string;
  lines: string[];
  profileFullName?: string;
}

function loadFixture(name: string): Fixture {
  const raw = fs.readFileSync(path.join(FIXTURES_DIR, name), 'utf-8');
  return JSON.parse(raw) as Fixture;
}

function run(name: string) {
  const fixture = loadFixture(name);
  return extractFields(fixture.documentType, fixture.lines, { profileFullName: fixture.profileFullName });
}

describe('extractFields — задача 031, этап D, п.20 (фикстуры backend/test/fixtures/ocr/)', () => {
  it('every fixture file in the directory is valid, loadable JSON', () => {
    const files = fs.readdirSync(FIXTURES_DIR).filter((f) => f.endsWith('.json'));
    expect(files.length).toBeGreaterThanOrEqual(10);
    for (const file of files) expect(() => loadFixture(file)).not.toThrow();
  });

  describe('DRIVER_LICENSE', () => {
    it('extracts a verified name against the driver profile', () => {
      const fields = run('driver_license_valid.json');
      expect(fields.fullName.value).toBe('Ерлан Тохтаров');
      expect(fields.fullName.checksumOk).toBe(true);
      expect(fields.fullName.needsReview).toBe(false);
    });

    it('extracts and validates the IIN by checksum', () => {
      const fields = run('driver_license_valid.json');
      expect(fields.iin.value).toBe('850712345611');
      expect(fields.iin.checksumOk).toBe(true);
    });

    it('extracts an expiry date (no checksum concept for dates)', () => {
      const fields = run('driver_license_valid.json');
      expect(fields.expiryDate.value).toBe('15.03.2029');
      expect(fields.expiryDate.checksumOk).toBeNull();
    });

    it('flags the name for review when it does not match the profile', () => {
      const fields = run('driver_license_name_mismatch.json');
      expect(fields.fullName.checksumOk).toBe(false);
      expect(fields.fullName.needsReview).toBe(true);
    });

    it('flags an invalid IIN (bad check digit) for review without rejecting it', () => {
      const fields = run('driver_license_bad_iin_checksum.json');
      expect(fields.iin.value).toBe('850712345600');
      expect(fields.iin.checksumOk).toBe(false);
      expect(fields.iin.needsReview).toBe(true);
    });
  });

  describe('IDENTITY', () => {
    it('extracts name and IIN, tolerating an OCR misread in the name', () => {
      const fields = run('identity_name_ocr_typo.json');
      expect(fields.fullName.checksumOk).toBe(true);
      expect(fields.iin.checksumOk).toBe(true);
    });

    it('задача 032, п.8а — the document header ("ҚАЗАҚСТАН РЕСПУБЛИКАСЫ"/"РЕСПУБЛИКА КАЗАХСТАН") is never picked as the name, even when nothing matches the profile', () => {
      const fields = run('driver_license_header_not_picked_as_name.json');
      expect(fields.fullName.value).toBe('Серик Абенов');
      expect(fields.fullName.needsReview).toBe(true);
    });
  });

  describe('VEHICLE_PASSPORT', () => {
    it('чинит «O» вместо нуля в цифровых позициях госномера (OCR: «123АВСО2»)', () => {
      const fields = extractFields('VEHICLE_PASSPORT', ['Plate 123\u0410\u0412\u0421\u041e2']);
      expect(fields.plateNumber.value).toBe('123ABC02');
    });

    it('extracts plate, vin and brand', () => {
      const fields = run('vehicle_passport_valid.json');
      expect(fields.plateNumber.value).toBe('123ABC02');
      expect(fields.plateNumber.checksumOk).toBe(true);
      expect(fields.vin.value).toBe('XTA1234576AB78901');
      expect(fields.vin.checksumOk).toBe(true);
      expect(fields.brand.value).toBe('Shacman');
    });

    it('recognizes a trailer-format plate even on a VEHICLE_PASSPORT document', () => {
      const fields = run('vehicle_passport_trailer_format_plate.json');
      expect(fields.plateNumber.value).toBe('777ABP05');
    });
  });

  describe('TRAILER_PASSPORT', () => {
    it('computes capacity tons from max mass minus tare mass', () => {
      const fields = run('trailer_passport_mass_valid.json');
      expect(fields.capacityTons.value).toBe('18.0');
      expect(fields.plateNumber.value).toBe('45ABC05');
    });

    it('omits capacity when only one mass value is present', () => {
      const fields = run('trailer_passport_single_mass.json');
      expect(fields.capacityTons).toBeUndefined();
    });
  });

  describe('COMPANY_REGISTRATION', () => {
    it('extracts a USCC for a Chinese company', () => {
      const fields = run('company_registration_uscc.json');
      expect(fields.uscc.value).toBe('91440101MA5CXYB1AB');
    });

    it('extracts a BIN for a Kazakhstan company', () => {
      const fields = run('company_registration_bin.json');
      expect(fields.bin.value).toBe('850712345611');
      expect(fields.bin.checksumOk).toBe(true);
    });
  });

  it('returns an empty object for a document type with no text fields (SELFIE)', () => {
    expect(run('selfie_no_text_expected.json')).toEqual({});
  });

  it('never throws on garbled/unreadable OCR output', () => {
    expect(() => run('garbled_unreadable.json')).not.toThrow();
  });

  it('never throws on an unknown document type or empty lines', () => {
    expect(extractFields('OTHER', ['anything'])).toEqual({});
    expect(() => extractFields('DRIVER_LICENSE', [])).not.toThrow();
  });
});

describe('кириллические двойники до сопоставления с шаблоном (задача 032, п.9 / 038)', () => {
  it('госномер «123 АВС 02» кириллицей распознаётся в техпаспорте', () => {
    const fields = extractFields('VEHICLE_PASSPORT', ['Марка: КАМАЗ', '123 АВС 02']);
    expect(fields.plateNumber?.value).toBe('123ABC02');
  });

  it('VIN «ХТА…» кириллицей распознаётся', () => {
    const fields = extractFields('VEHICLE_PASSPORT', ['ХТА212130M1234567']);
    expect(fields.vin?.value).toBe('XTA212130M1234567');
  });
});
