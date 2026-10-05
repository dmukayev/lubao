import { RecognitionService } from './recognition.service';
import * as ocrClient from './ocr-client';

jest.mock('./ocr-client');
const mockedRecognizeDocument = ocrClient.recognizeDocument as jest.Mock;

/// Задача 031, этап F, п.28 — «OCR выключен → SKIPPED, всё работает»:
/// единственный реальный пробел в покрытии после этапа D (checksums/
/// name-match/extract-fields были протестированы изолированно, но сам
/// process() — решение SKIPPED/DONE/FAILED — не был покрыт вовсе).
function prismaMock(documentOverrides: Record<string, unknown>) {
  return {
    verificationDocument: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'doc1',
        type: 'DRIVER_LICENSE',
        fileUrl: 'https://files.example/doc1.jpg',
        driver: { fullName: 'Ерлан Тохтаров' },
        company: null,
        ...documentOverrides,
      }),
    },
    documentRecognition: { upsert: jest.fn() },
  };
}

describe('RecognitionService#process — п.18/28', () => {
  beforeEach(() => jest.resetAllMocks());

  it('writes SKIPPED without calling the OCR client at all for a type with no text fields (SELFIE)', async () => {
    const prisma: any = prismaMock({ type: 'SELFIE' });
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    expect(mockedRecognizeDocument).not.toHaveBeenCalled();
    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { documentId: 'doc1' }, create: expect.objectContaining({ status: 'SKIPPED' }) }),
    );
  });

  it('writes SKIPPED when OCR_SERVICE_URL is unset or the service is unreachable (recognizeDocument resolves null) — manual review keeps working', async () => {
    mockedRecognizeDocument.mockResolvedValue(null);
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    expect(mockedRecognizeDocument).toHaveBeenCalledWith('https://files.example/doc1.jpg', 'ru');
    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: 'SKIPPED', fields: expect.anything() }) }),
    );
  });

  it('writes DONE with extracted fields when the OCR client returns text lines', async () => {
    mockedRecognizeDocument.mockResolvedValue({ lines: ['Ерлан Тохтаров', 'ИИН 850712345611'] });
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    const call = prisma.documentRecognition.upsert.mock.calls[0][0];
    expect(call.create.status).toBe('DONE');
    expect(call.create.fields.iin.value).toBe('850712345611');
  });

  it('calls both ru and ch for COMPANY_REGISTRATION — a company can be registered on either side', async () => {
    mockedRecognizeDocument.mockResolvedValue({ lines: ['ТОО Хоргос Транс'] });
    const prisma: any = prismaMock({ type: 'COMPANY_REGISTRATION', driver: null, company: { name: 'Хоргос Транс' } });
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    expect(mockedRecognizeDocument).toHaveBeenCalledWith(expect.any(String), 'ru');
    expect(mockedRecognizeDocument).toHaveBeenCalledWith(expect.any(String), 'ch');
  });

  it('writes FAILED with the error message when the OCR call throws unexpectedly', async () => {
    mockedRecognizeDocument.mockRejectedValue(new Error('boom'));
    const prisma: any = prismaMock({ type: 'DRIVER_LICENSE' });
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    expect(prisma.documentRecognition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: 'FAILED', errorMessage: 'boom' }) }),
    );
  });

  it('does nothing when the document no longer exists (deleted between enqueue and processing)', async () => {
    const prisma: any = { verificationDocument: { findUnique: jest.fn().mockResolvedValue(null) }, documentRecognition: { upsert: jest.fn() } };
    const service = new RecognitionService(prisma, {} as any);

    await service.process('doc1');

    expect(prisma.documentRecognition.upsert).not.toHaveBeenCalled();
  });
});

describe('RecognitionService#enqueue — п.18', () => {
  it('adds a job with retry/backoff, matching the pattern from notifications (задача 011)', async () => {
    const queue = { add: jest.fn() };
    const service = new RecognitionService({} as any, queue as any);

    await service.enqueue('doc1');

    expect(queue.add).toHaveBeenCalledWith('recognize', { documentId: 'doc1' }, { attempts: 3, backoff: { type: 'exponential', delay: 5000 } });
  });
});
