import { buildDriverDocumentsPdf } from './driver-documents.pdf';

// 044 п.1: PDF собирается со своими шрифтами (кириллица, иероглифы) и фото.
// 1×1 PNG.
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', 'base64');

describe('buildDriverDocumentsPdf', () => {
  it('собирает PDF: шапка, водитель, машины, страницы фото; китайское название компании не ломает', async () => {
    const pdf = await buildDriverDocumentsPdf({
      locale: 'ru',
      route: 'Алматы → Астана',
      readyDate: '2030-01-01',
      driver: { fullName: 'Ерлан Тестов', iin: '900101300123' },
      license: { number: 'AB1234567', expiryDate: '2031-05-01', documentId: 'lic1' },
      selfieId: 'selfie1',
      identityId: null,
      vehicles: [
        { kind: 'TRACTOR', plateNumber: '123ABC02', vin: '1M8GDM9AXKP042788', brand: 'MAN', isVerified: false, passportId: 'pass1' },
        { kind: 'TRAILER', plateNumber: '12ABC02', vin: null, brand: null, isVerified: true, passportId: null },
      ],
      issuedTo: 'Ли Вэй',
      companyName: '新疆测试物流',
      issuedAt: new Date('2030-01-01T10:00:00Z'),
      images: new Map([
        ['selfie1', { buffer: PNG, contentType: 'image/png' }],
        ['lic1', { buffer: Buffer.from('RIFF'), contentType: 'image/webp' }],
      ]),
    });
    expect(pdf.subarray(0, 5).toString()).toBe('%PDF-');
    // Обложка + селфи + права + 2 техпаспорта.
    expect((pdf.toString('latin1').match(/\/Type \/Page\b/g) ?? []).length).toBe(5);
    expect(pdf.length).toBeGreaterThan(3000);
  });
});
