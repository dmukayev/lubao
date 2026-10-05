import { Injectable, Logger } from '@nestjs/common';
import { Queue } from 'bullmq';
import { Prisma, VerificationDocType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import { RECOGNIZED_FIELD_IDENTIFIER_TYPE, RecognizedFields, extractFields } from './extract-fields';
import { encryptIdentifier, isSensitiveIdentifierType, maskIdentifier } from '../identifiers/crypto';
import { normalizeIdentifier } from '../identifiers/normalize';
import { recognizeDocument } from './ocr-client';
import { RECOGNITION_QUEUE, RecognitionJob } from './recognition.queue';

const ENGINE_VERSION = 'rules-v1';
const RECOGNITION_ATTEMPTS = 3;

/// Задача 032, п.7 — отличить «OCR недоступен прямо сейчас» (повторить
/// стоит, помечаем SKIPPED только после последней попытки) от любой
/// другой ошибки (помечаем FAILED с текстом ошибки).
class OcrUnreachableError extends Error {
  constructor() {
    super('OCR service unreachable');
  }
}

/// Задача 032, п.4 — ИИН/номер прав не хранятся в document_recognitions
/// открытым текстом: значение уходит в БД только зашифрованным (тот же
/// IDENTIFIER_KEY, что и у подтверждённых identifiers) + маской для
/// отображения без расшифровки; `value` для этих полей не пишется вовсе.
/// Остальные поля (ФИО, госномер, VIN, БИН/统一社会信用代码...) не настолько
/// чувствительны — то же решение, что уже принято для identifiers
/// (`isSensitiveIdentifierType`), не отдельное правило здесь.
function maskSensitiveFields(fields: RecognizedFields): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, recognized] of Object.entries(fields)) {
    const type = RECOGNIZED_FIELD_IDENTIFIER_TYPE[key];
    if (type && isSensitiveIdentifierType(type)) {
      const normalized = normalizeIdentifier(type, recognized.value);
      result[key] = {
        valueMasked: maskIdentifier(type, normalized),
        valueEncrypted: encryptIdentifier(normalized),
        confidence: recognized.confidence,
        checksumOk: recognized.checksumOk,
        needsReview: recognized.needsReview,
      };
    } else {
      result[key] = recognized;
    }
  }
  return result;
}

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
  /// companies — загрузка документа), а также админской кнопкой
  /// «Распознать заново» (задача 032, п.7). Асинхронно, не блокирует ответ.
  async enqueue(documentId: string): Promise<void> {
    await this.queue.add(
      'recognize',
      { documentId },
      { attempts: RECOGNITION_ATTEMPTS, backoff: { type: 'exponential', delay: 5000 } },
    );
  }

  /// Фактическая обработка одного документа — вызывается воркером
  /// (recognition.processor.ts). Публичный метод, чтобы воркер оставался
  /// тонким и тестируемым через мок PrismaService/очереди, как у
  /// notifications.processor.ts/notifications.service.ts.
  /// Задача 032, п.7 — раньше ЛЮБАЯ ошибка (включая недоступный OCR-
  /// контейнер) писала терминальный статус и проглатывалась здесь же, то
  /// есть BullMQ считал job успешно обработанной и `attempts: 3` никогда
  /// не срабатывали. Теперь ошибка на НЕпоследней попытке прокидывается
  /// наружу — BullMQ сам повторит job с экспоненциальной паузой; `SKIPPED`/
  /// `FAILED` пишутся только когда попыток больше не осталось.
  async process(documentId: string, attempt: { attemptsMade: number; maxAttempts: number } = { attemptsMade: 0, maxAttempts: 1 }): Promise<void> {
    const startedAt = Date.now();
    const isLastAttempt = attempt.attemptsMade + 1 >= attempt.maxAttempts;
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
        // OCR_SERVICE_URL не задан или сервис временно недоступен — не
        // сдаёмся сразу, даём BullMQ дожать до последней попытки (контейнер
        // может быть просто в процессе рестарта/деплоя).
        throw new OcrUnreachableError();
      }

      const lines = [...new Set(reachable.flatMap((r) => r.lines))];
      const fields = extractFields(document.type, lines, { profileFullName: document.driver?.fullName });
      await this.writeResult(documentId, {
        status: 'DONE',
        fields: maskSensitiveFields(fields),
        durationMs: Date.now() - startedAt,
      });
    } catch (err) {
      if (!isLastAttempt) {
        this.logger.warn(`Recognition attempt ${attempt.attemptsMade + 1}/${attempt.maxAttempts} failed for document ${documentId}, will retry: ${(err as Error).message}`);
        throw err;
      }
      const unreachable = err instanceof OcrUnreachableError;
      this.logger.error(`Recognition failed for document ${documentId} after the final attempt: ${(err as Error).message}`);
      await this.writeResult(documentId, {
        status: unreachable ? 'SKIPPED' : 'FAILED',
        fields: null,
        durationMs: Date.now() - startedAt,
        errorMessage: unreachable ? undefined : (err as Error).message,
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
