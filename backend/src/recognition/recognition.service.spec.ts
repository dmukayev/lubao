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
    expect(call.create.fields.iin.value).toBe('850712345611');
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
