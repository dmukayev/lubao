import { Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';
import { Prisma, VerificationDocType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import { extractFields } from './extract-fields';
import { recognizeDocument } from './ocr-client';
import { RECOGNITION_QUEUE, RecognitionJob } from './recognition.queue';

const ENGINE_VERSION = 'rules-v1';

/// Какими языковыми моделями гонять OCR для типа документа (задача 031,
/// п.17/20) — SELFIE/OTHER не содержат текста для распознавания вовсе.
function langsForDocType(type: VerificationDocType): Array<'ru' | 'ch'> {
  switch (type) {
    case 'DRIVER_LICENSE':
    case 'IDENTITY':
    case 'VEHICLE_PASSPORT':
    case 'TRAILER_PASSPORT':
      return ['ru'];
    case 'COMPANY_REGISTRATION':
      // Компания может быть зарегистрирована и в РК, и в Китае (CLAUDE.md:
      // «логисты в основном на китайской стороне») — пробуем обе модели.
      return ['ru', 'ch'];
    default:
      return [];
  }
}

@Injectable()
export class RecognitionService {
  private readonly logger = new Logger(RecognitionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queue: Queue<RecognitionJob>,
    private readonly uploads: UploadsService,
  ) {}

  /// Вызывается после создания VerificationDocument (drivers.service.ts/
  /// companies — загрузка документа). Асинхронно, не блокирует ответ клиенту.
  async enqueue(documentId: string): Promise<void> {
    await this.queue.add(
      'recognize',
      { documentId },
      { attempts: 3, backoff: { type: 'exponential', delay: 5000 } },
    );
  }

  /// Фактическая обработка одного документа — вызывается воркером
  /// (recognition.processor.ts). Публичный метод, чтобы воркер оставался
  /// тонким и тестируемым через мок PrismaService/очереди, как у
  /// notifications.processor.ts/notifications.service.ts.
  async process(documentId: string): Promise<void> {
    const startedAt = Date.now();
    const document = await this.prisma.verificationDocument.findUnique({
      where: { id: documentId },
      include: { driver: true, company: true },
    });
    if (!document) return;

    const langs = langsForDocType(document.type);
    if (langs.length === 0) {
      await this.writeResult(documentId, { status: 'SKIPPED', fields: null, durationMs: Date.now() - startedAt });
      return;
    }

    try {
      // Задача 032, п.1 — бэкенд сам читает байты (из приватного бакета по
      // ключу, или по уже готовому https-URL легаси/сид-документов — его
      // когда-то задал только наш же сид-скрипт, не клиент) и шлёт их в
      // OCR мультипартом; сам OCR-контейнер URL больше не видит и не ходит
      // за ним в сеть (устранение SSRF).
      const { buffer, contentType } = /^https?:\/\//.test(document.fileUrl)
        ? await fetch(document.fileUrl).then(async (r) => ({ buffer: Buffer.from(await r.arrayBuffer()), contentType: r.headers.get('content-type') || 'image/jpeg' }))
        : await this.uploads.getDocumentBuffer(document.fileUrl);

      const lineSets = await Promise.all(langs.map((lang) => recognizeDocument(buffer, contentType, lang)));
      const reachable = lineSets.filter((r): r is { lines: string[] } => r !== null);
      if (reachable.length === 0) {
        // OCR_SERVICE_URL не задан или сервис недоступен — честно
        // пропускаем распознавание, ручная проверка документа админом
        // остаётся рабочим путём (п.18: «деградация»).
        await this.writeResult(documentId, { status: 'SKIPPED', fields: null, durationMs: Date.now() - startedAt });
        return;
      }

      const lines = [...new Set(reachable.flatMap((r) => r.lines))];
      const fields = extractFields(document.type, lines, { profileFullName: document.driver?.fullName });
      await this.writeResult(documentId, {
        status: 'DONE',
        fields: fields as unknown as Record<string, unknown>,
        durationMs: Date.now() - startedAt,
      });
    } catch (err) {
      this.logger.error(`Recognition failed for document ${documentId}: ${(err as Error).message}`);
      await this.writeResult(documentId, {
        status: 'FAILED',
        fields: null,
        durationMs: Date.now() - startedAt,
        errorMessage: (err as Error).message,
      });
    }
  }

  private async writeResult(
    documentId: string,
    data: { status: 'DONE' | 'FAILED' | 'SKIPPED'; fields: Record<string, unknown> | null; durationMs: number; errorMessage?: string },
  ): Promise<void> {
    const fields = data.fields === null ? Prisma.JsonNull : (data.fields as Prisma.InputJsonValue);
    await this.prisma.documentRecognition.upsert({
      where: { documentId },
      create: { documentId, engineVersion: ENGINE_VERSION, ...data, fields },
      update: { engineVersion: ENGINE_VERSION, ...data, fields },
    });
  }
}

export { RECOGNITION_QUEUE };
