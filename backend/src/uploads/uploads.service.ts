import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import * as Minio from 'minio';

const DOCUMENT_PRESIGN_TTL_SECONDS = 10 * 60;

@Injectable()
export class UploadsService implements OnModuleInit {
  private readonly logger = new Logger(UploadsService.name);
  private readonly client: Minio.Client;
  private readonly bucket = process.env.MINIO_BUCKET || 'lubao-uploads';
  private readonly publicUrl = (process.env.MINIO_PUBLIC_URL || 'http://localhost:9000').replace(/\/$/, '');
  /// Отдельный **приватный** бакет для документов верификации (селфи,
  /// техпаспорта, права) — персональные данные, не должны открываться без
  /// авторизации (задача 026, п.6). Грузовые фото в `bucket` остаются
  /// публичными — их и так видно всем в ленте без авторизации.
  private readonly documentsBucket = process.env.MINIO_DOCUMENTS_BUCKET || 'lubao-documents';
  /// Клиент только для подписи presigned-ссылок (сетевых запросов не делает —
  /// это чистая HMAC-подпись) — настроен на ПУБЛИЧНЫЙ хост из MINIO_PUBLIC_URL,
  /// а не на внутренний docker-хост `minio`/`localhost`, который браузер
  /// админа или телефон водителя не смогут разрешить (та же причина, по
  /// которой `publicUrl` ниже не может быть внутренним адресом).
  private readonly presignClient: Minio.Client;

  constructor() {
    this.client = new Minio.Client({
      endPoint: process.env.MINIO_ENDPOINT || 'localhost',
      port: Number(process.env.MINIO_PORT || 9000),
      useSSL: process.env.MINIO_USE_SSL === 'true',
      accessKey: process.env.MINIO_ACCESS_KEY || 'lubao',
      secretKey: process.env.MINIO_SECRET_KEY || 'lubao_minio_password',
    });

    const publicUrlParsed = new URL(this.publicUrl);
    this.presignClient = new Minio.Client({
      endPoint: publicUrlParsed.hostname,
      port: Number(publicUrlParsed.port || (publicUrlParsed.protocol === 'https:' ? 443 : 80)),
      useSSL: publicUrlParsed.protocol === 'https:',
      accessKey: process.env.MINIO_ACCESS_KEY || 'lubao',
      secretKey: process.env.MINIO_SECRET_KEY || 'lubao_minio_password',
    });
  }

  /// Для /health/ready: хранилище отвечает и бакеты на месте.
  async ping(): Promise<void> {
    if (!(await this.client.bucketExists(this.bucket)) || !(await this.client.bucketExists(this.documentsBucket))) {
      throw new Error('bucket missing');
    }
  }

  async onModuleInit() {
    try {
      const exists = await this.client.bucketExists(this.bucket);
      if (!exists) {
        await this.client.makeBucket(this.bucket);
      }
      // Публичное чтение объектов: ссылки на фото должны открываться без авторизации.
      await this.client.setBucketPolicy(
        this.bucket,
        JSON.stringify({
          Version: '2012-10-17',
          Statement: [
            {
              Effect: 'Allow',
              Principal: { AWS: ['*'] },
              Action: ['s3:GetObject'],
              Resource: [`arn:aws:s3:::${this.bucket}/*`],
            },
          ],
        }),
      );

      const documentsExist = await this.client.bucketExists(this.documentsBucket);
      if (!documentsExist) {
        await this.client.makeBucket(this.documentsBucket);
      }
      // Намеренно без setBucketPolicy — приватный по умолчанию, доступ
      // только через presignedGetObject с ограниченным TTL.
    } catch (error) {
      this.logger.warn(`MinIO bucket setup failed (will retry on first upload): ${error}`);
    }
  }

  /// `ext` — расширение распознанного по байтам типа (image-type.ts), не имя от клиента.
  async uploadImage(buffer: Buffer, ext: string, mimetype: string): Promise<string> {
    const objectName = `${randomUUID()}.${ext}`;
    await this.client.putObject(this.bucket, objectName, buffer, buffer.length, {
      'Content-Type': mimetype,
    });
    return `${this.publicUrl}/${this.bucket}/${objectName}`;
  }

  /// Для документов верификации возвращает не URL, а ключ объекта в
  /// приватном бакете (`fileUrl` в БД хранит именно его) — реальная ссылка
  /// выдаётся только админу через [presignDocumentUrl] на 10 минут.
  /// `uploaderUserId` записывается в метаданные объекта (задача 032, п.1) —
  /// единственный способ позже проверить, что ключ, который клиент
  /// присылает в `POST .../verification-documents`, действительно
  /// загружен этим же пользователем, а не угадан/скопирован у другого.
  async uploadDocument(buffer: Buffer, ext: string, mimetype: string, uploaderUserId: string): Promise<string> {
    const objectName = `${randomUUID()}.${ext}`;
    await this.client.putObject(this.documentsBucket, objectName, buffer, buffer.length, {
      'Content-Type': mimetype,
      'X-Amz-Meta-Uploader': uploaderUserId,
    });
    return objectName;
  }

  /// Задача 032, п.1 — `fileUrl` в `CreateVerificationDocumentDto` раньше
  /// принимался как произвольная строка и шёл прямиком в OCR как URL
  /// (`ocr-client.ts` делал `fetch(fileUrl)`) — SSRF во внутреннюю сеть
  /// докера. Теперь это строго ключ объекта из НАШЕГО `POST /uploads/document`:
  /// формат (UUID.расширение, никаких `://` и `..`), объект существует в
  /// приватном бакете и загружен именно этим пользователем.
  async verifyDocumentOwnership(fileKey: string, uploaderUserId: string): Promise<boolean> {
    if (!/^[0-9a-f-]{36}\.[A-Za-z0-9]{1,10}$/.test(fileKey)) return false;
    try {
      const stat = await this.client.statObject(this.documentsBucket, fileKey);
      return stat.metaData?.['uploader'] === uploaderUserId;
    } catch {
      return false;
    }
  }

  /// Задача 032, п.1/8 — байты документа для пересылки в OCR мультипартом
  /// (вместо того чтобы отдавать OCR-контейнеру URL и давать ему самому
  /// решать, что скачивать). Бэкенд — единственный, кто ходит в MinIO.
  async getDocumentBuffer(fileKey: string): Promise<{ buffer: Buffer; contentType: string }> {
    const stat = await this.client.statObject(this.documentsBucket, fileKey);
    const stream = await this.client.getObject(this.documentsBucket, fileKey);
    const chunks: Buffer[] = [];
    for await (const chunk of stream) chunks.push(chunk as Buffer);
    return { buffer: Buffer.concat(chunks), contentType: (stat.metaData?.['content-type'] as string) || 'application/octet-stream' };
  }

  /// `fileKey` может быть либо ключом объекта в приватном бакете (новые
  /// документы), либо уже готовым http(s)-URL (демо-сид/легаси-документы,
  /// загруженные через старый публичный путь до этой задачи) — во втором
  /// случае отдаём как есть, подписывать нечего.
  async presignDocumentUrl(fileKey: string): Promise<string> {
    if (/^https?:\/\//.test(fileKey)) return fileKey;
    return this.presignClient.presignedGetObject(this.documentsBucket, fileKey, DOCUMENT_PRESIGN_TTL_SECONDS);
  }

  /// Прокси вместо presigned-ссылки (задача 028, п.12) — браузер админки
  /// тянул бы фото напрямую с MinIO (другой origin, без CORS), и зум/превью
  /// молча не загружались. Бэкенд ходит в MinIO сам (server-to-server, не
  /// подчиняется CORS) и отдаёт байты через свой собственный ответ — у
  /// нашего API уже `app.enableCors()` в main.ts.
  async getDocumentStream(fileKey: string): Promise<{ stream: NodeJS.ReadableStream; contentType: string }> {
    const stat = await this.client.statObject(this.documentsBucket, fileKey);
    const stream = await this.client.getObject(this.documentsBucket, fileKey);
    return { stream, contentType: (stat.metaData?.['content-type'] as string) || 'application/octet-stream' };
  }
}
