import { RecognitionService } from './recognition.service';
import * as ocrClient from './ocr-client';

jest.mock('./ocr-client');
const mockedRecognizeDocument = ocrClient.recognizeDocument as jest.Mock;

/// Задача 031, этап F, п.28 — «OCR выключен → SKIPPED, всё работает»:
/// единственный реальный пробел в покрытии после этапа D (checksums/
/// name-match/extract-fields были протестированы изолированно, но сам
/// process() — решение SKIPPED/DONE/FAILED — не был покрыт вовсе).
/// Задача 032, п.1 — `fileUrl` документа теперь ключ объекта в приватном
/// бакете (байты читает `uploads.getDocumentBuffer`), не URL, который
/// раньше шёл прямиком в OCR (SSRF). Легаси-сид-документы с готовым
/// https-URL — отдельный путь (`fetch` напрямую), покрыт своим тестом.
function prismaMock(documentOverrides: Record<string, unknown>) {
  return {
    verificationDocument: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'doc1',
        type: 'DRIVER_LICENSE',
        fileUrl: 'a1b2c3d4-0000-4000-8000-000000000000.jpg',
        driver: { fullName: 'Ерлан Тохтаров' },
        company: null,
        ...documentOverrides,
      }),
    },
    documentRecognition: { upsert: jest.fn() },
  };
}

function uploadsMock(): any {
  return { getDocumentBuffer: jest.fn().mockResolvedValue({ buffer: Buffer.from('fake-image-bytes'), contentType: 'image/jpeg' }) };
}

describe('RecognitionService#process — п.18/28, п.1/8 (задача 032)', () => {
  beforeEach(() => jest.resetAllMocks());

  it('writes SKIPPED without calling the OCR client at all for a type with no text fields (SELFIE)', async () => {
    const prisma: any = prismaMock({ type: 'SELFIE' });
    const uploads: any = uploadsMock();
    const service = new RecognitionService(prisma, {} as any, uploads);

    await service.process('doc1');

    expect(mockedRecognizeDocument).not.toHaveBeenCalled();
    expect(uploads.getDocumentBuffer).not.toHaveBeenCalled();
    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { documentId: 'doc1' }, create: expect.objectContaining({ status: 'SKIPPED' }) }),
    );
  });

  it('reads bytes via uploads.getDocumentBuffer (object key, not URL) and passes them to the OCR client', async () => {
    mockedRecognizeDocument.mockResolvedValue(null);
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const uploads: any = uploadsMock();
    const service = new RecognitionService(prisma, {} as any, uploads);

    await service.process('doc1');

    expect(uploads.getDocumentBuffer).toHaveBeenCalledWith('a1b2c3d4-0000-4000-8000-000000000000.jpg');
    expect(mockedRecognizeDocument).toHaveBeenCalledWith(Buffer.from('fake-image-bytes'), 'image/jpeg', 'ru');
  });

  it('fetches legacy seed documents with a real https:// fileUrl directly, without going through uploads', async () => {
    mockedRecognizeDocument.mockResolvedValue(null);
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE', fileUrl: 'https://files.example/legacy.jpg' });
    const uploads: any = uploadsMock();
    const fakeBytes = new TextEncoder().encode('legacy-bytes').buffer;
    global.fetch = jest.fn().mockResolvedValue({ arrayBuffer: async () => fakeBytes, headers: { get: () => 'image/png' } }) as any;
    const service = new RecognitionService(prisma, {} as any, uploads);

    await service.process('doc1');

    expect(uploads.getDocumentBuffer).not.toHaveBeenCalled();
    expect(global.fetch).toHaveBeenCalledWith('https://files.example/legacy.jpg');
    expect(mockedRecognizeDocument).toHaveBeenCalledWith(Buffer.from('legacy-bytes'), 'image/png', 'ru');
  });

  it('writes SKIPPED when OCR_SERVICE_URL is unset or the service is unreachable (recognizeDocument resolves null) — manual review keeps working', async () => {
    mockedRecognizeDocument.mockResolvedValue(null);
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any, uploadsMock());

    await service.process('doc1');

    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: 'SKIPPED', fields: expect.anything() }) }),
    );
  });

  it('writes DONE with extracted fields when the OCR client returns text lines', async () => {
    mockedRecognizeDocument.mockResolvedValue({ lines: ['Ерлан Тохтаров', 'ИИН 850712345611'] });
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any, uploadsMock());

    await service.process('doc1');

    const call = prisma.documentRecognition.upsert.mock.calls[0][0];
    expect(call.create.status).toBe('DONE');
    // Задача 032, п.4 — ИИН не хранится открытым текстом: нет `value`,
    // только маска + шифр (расшифровывается тем же IDENTIFIER_KEY, что и
    // identifiers.valueEncrypted).
    expect(call.create.fields.iin.value).toBeUndefined();
    expect(call.create.fields.iin.valueMasked).toBe('8507••••5611');
    expect(typeof call.create.fields.iin.valueEncrypted).toBe('string');
  });

  it('calls both ru and ch for COMPANY_REGISTRATION — a company can be registered on either side', async () => {
    mockedRecognizeDocument.mockResolvedValue({ lines: ['ТОО Хоргос Транс'] });
    const prisma: any = prismaMock({ type: 'COMPANY_REGISTRATION', driver: null, company: { name: 'Хоргос Транс' } });
    const service = new RecognitionService(prisma, {} as any, uploadsMock());

    await service.process('doc1');

    expect(mockedRecognizeDocument).toHaveBeenCalledWith(expect.any(Buffer), expect.any(String), 'ru');
    expect(mockedRecognizeDocument).toHaveBeenCalledWith(expect.any(Buffer), expect.any(String), 'ch');
  });

  it('writes FAILED with the error message when the OCR call throws unexpectedly', async () => {
    mockedRecognizeDocument.mockRejectedValue(new Error('boom'));
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any, uploadsMock());

    await service.process('doc1');

    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: 'FAILED', errorMessage: 'boom' }) }),
    );
  });

  describe('задача 032, п.7 — retries via BullMQ attempts (no longer swallowed on every attempt)', () => {
    it('rethrows when the OCR service is unreachable on a non-final attempt, without writing any terminal status', async () => {
      mockedRecognizeDocument.mockResolvedValue(null);
      const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
      const service = new RecognitionService(prisma, {} as any, uploadsMock());

      await expect(service.process('doc1', { attemptsMade: 0, maxAttempts: 3 })).rejects.toThrow('OCR service unreachable');
      expect(prisma.documentRecognition.upsert).not.toHaveBeenCalled();
    });

    it('rethrows an unexpected OCR error on a non-final attempt too', async () => {
      mockedRecognizeDocument.mockRejectedValue(new Error('boom'));
      const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
      const service = new RecognitionService(prisma, {} as any, uploadsMock());

      await expect(service.process('doc1', { attemptsMade: 1, maxAttempts: 3 })).rejects.toThrow('boom');
      expect(prisma.documentRecognition.upsert).not.toHaveBeenCalled();
    });

    it('writes SKIPPED (not FAILED) only once the LAST attempt still finds the OCR service unreachable', async () => {
      mockedRecognizeDocument.mockResolvedValue(null);
      const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
      const service = new RecognitionService(prisma, {} as any, uploadsMock());

      await service.process('doc1', { attemptsMade: 2, maxAttempts: 3 });

      expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ create: expect.objectContaining({ status: 'SKIPPED' }) }),
      );
    });

    it('writes FAILED only once the LAST attempt still throws an unexpected error', async () => {
      mockedRecognizeDocument.mockRejectedValue(new Error('boom'));
      const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
      const service = new RecognitionService(prisma, {} as any, uploadsMock());

      await service.process('doc1', { attemptsMade: 2, maxAttempts: 3 });

      expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ create: expect.objectContaining({ status: 'FAILED', errorMessage: 'boom' }) }),
      );
    });

    it('a single-attempt call (default, no attempt info passed) behaves exactly as before — terminal status on the only attempt', async () => {
      mockedRecognizeDocument.mockResolvedValue(null);
      const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
      const service = new RecognitionService(prisma, {} as any, uploadsMock());

      await service.process('doc1');

      expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ create: expect.objectContaining({ status: 'SKIPPED' }) }),
      );
    });
  });

  it('does nothing when the document no longer exists (deleted between enqueue and processing)', async () => {
    const prisma: any = { verificationDocument: { findUnique: jest.fn().mockResolvedValue(null) }, documentRecognition: { upsert: jest.fn() } };
    const service = new RecognitionService(prisma, {} as any, uploadsMock());

    await service.process('doc1');

    expect(prisma.documentRecognition.upsert).not.toHaveBeenCalled();
  });
});

describe('RecognitionService#enqueue — п.18', () => {
  it('adds a job with retry/backoff, matching the pattern from notifications (задача 011)', async () => {
    const queue = { add: jest.fn() };
    const service = new RecognitionService({} as any, queue as any, {} as any);

    await service.enqueue('doc1');

    expect(queue.add).toHaveBeenCalledWith('recognize', { documentId: 'doc1' }, { attempts: 3, backoff: { type: 'exponential', delay: 5000 } });
  });
});

// 044 п.6: автопроверка машины после распознавания техпаспорта.
describe('RecognitionService.tryAutoVerifyVehicle', () => {
  const GOOD = { vin: { value: '1M8GDM9AXKP042788', confidence: 0.95, checksumOk: true, needsReview: false }, plateNumber: { value: '123ABC02', confidence: 0.9, checksumOk: true, needsReview: false } };
  function setup({ blocked = null as unknown, isVerified = false, duplicateOwner = null as unknown } = {}) {
    const prisma: any = {
      vehicle: { findUnique: jest.fn().mockResolvedValue({ id: 'v1', isVerified, plateNumber: null, vin: null }), update: jest.fn() },
      verificationDocument: { findUnique: jest.fn().mockResolvedValue({ status: 'PENDING' }), update: jest.fn() },
      auditLog: { create: jest.fn() },
    };
    prisma.$transaction = jest.fn((fn: (tx: unknown) => Promise<unknown>) => fn(prisma));
    const identifiers: any = { checkMatches: jest.fn().mockResolvedValue({ blocked, duplicateOwner }), confirmIdentifier: jest.fn() };
    return { prisma, identifiers, service: new RecognitionService(prisma, {} as any, {} as any, identifiers) };
  }

  it('корректный техпаспорт — документ одобрен, машина проверена AUTO, VIN и госномер записаны', async () => {
    const { prisma, identifiers, service } = setup();
    await expect(service.tryAutoVerifyVehicle('doc1', 'VEHICLE_PASSPORT', 'v1', GOOD)).resolves.toBe(true);
    expect(prisma.verificationDocument.update).toHaveBeenCalledWith({ where: { id: 'doc1' }, data: expect.objectContaining({ status: 'APPROVED' }) });
    expect(prisma.vehicle.update.mock.calls[0][0].data).toMatchObject({ isVerified: true, verifiedBy: 'AUTO', plateNumber: '123ABC02', vin: '1M8GDM9AXKP042788' });
    expect(identifiers.confirmIdentifier).toHaveBeenCalledTimes(2);
    expect(identifiers.confirmIdentifier.mock.calls[0][0]).toMatchObject({ ownerType: 'VEHICLE', confirmedByUserId: null });
    expect(prisma.auditLog.create.mock.calls[0][0].data).toMatchObject({ action: 'VEHICLE_AUTO_VERIFIED', entityId: 'v1' });
  });

  it('VIN в чёрном списке — ничего не меняется, документ ждёт админа', async () => {
    const { prisma, service } = setup({ blocked: { id: 'b1' } });
    await expect(service.tryAutoVerifyVehicle('doc1', 'VEHICLE_PASSPORT', 'v1', GOOD)).resolves.toBe(false);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('049 п.3: VIN уже подтверждён у машины другого водителя — не AUTO, в очередь админу с пометкой', async () => {
    const { prisma, service } = setup({ duplicateOwner: { ownerType: 'VEHICLE', ownerId: 'v-other' } });
    await expect(service.tryAutoVerifyVehicle('doc1', 'VEHICLE_PASSPORT', 'v1', GOOD)).resolves.toBe(false);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.vehicle.update).not.toHaveBeenCalled();
    expect(prisma.auditLog.create.mock.calls[0][0].data).toMatchObject({ action: 'VEHICLE_AUTO_VERIFY_SKIPPED', metadata: expect.objectContaining({ reason: 'DUPLICATE' }) });
  });

  it('плохой формат VIN — нет; уже проверенная машина — не трогаем', async () => {
    const bad = { ...GOOD, vin: { ...GOOD.vin, value: '1M8GDM9A1KP042788' } };
    expect(await setup().service.tryAutoVerifyVehicle('doc1', 'VEHICLE_PASSPORT', 'v1', bad)).toBe(false);
    expect(await setup({ isVerified: true }).service.tryAutoVerifyVehicle('doc1', 'VEHICLE_PASSPORT', 'v1', GOOD)).toBe(false);
  });
});
