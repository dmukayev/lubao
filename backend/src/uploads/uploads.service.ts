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

  async uploadImage(buffer: Buffer, originalName: string, mimetype: string): Promise<string> {
    const ext = originalName.includes('.') ? originalName.split('.').pop() : 'jpg';
    const objectName = `${randomUUID()}.${ext}`;
    await this.client.putObject(this.bucket, objectName, buffer, buffer.length, {
      'Content-Type': mimetype,
    });
    return `${this.publicUrl}/${this.bucket}/${objectName}`;
  }

  /// Для документов верификации возвращает не URL, а ключ объекта в
  /// приватном бакете (`fileUrl` в БД хранит именно его) — реальная ссылка
  /// выдаётся только админу через [presignDocumentUrl] на 10 минут.
  async uploadDocument(buffer: Buffer, originalName: string, mimetype: string): Promise<string> {
    const ext = originalName.includes('.') ? originalName.split('.').pop() : 'jpg';
    const objectName = `${randomUUID()}.${ext}`;
    await this.client.putObject(this.documentsBucket, objectName, buffer, buffer.length, {
      'Content-Type': mimetype,
    });
    return objectName;
  }

  /// `fileKey` может быть либо ключом объекта в приватном бакете (новые
  /// документы), либо уже готовым http(s)-URL (демо-сид/легаси-документы,
  /// загруженные через старый публичный путь до этой задачи) — во втором
  /// случае отдаём как есть, подписывать нечего.
  async presignDocumentUrl(fileKey: string): Promise<string> {
    if (/^https?:\/\//.test(fileKey)) return fileKey;
    return this.presignClient.presignedGetObject(this.documentsBucket, fileKey, DOCUMENT_PRESIGN_TTL_SECONDS);
  }
}
