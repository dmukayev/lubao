import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { randomUUID } from 'crypto';
import * as Minio from 'minio';

@Injectable()
export class UploadsService implements OnModuleInit {
  private readonly logger = new Logger(UploadsService.name);
  private readonly client: Minio.Client;
  private readonly bucket = process.env.MINIO_BUCKET || 'lubao-uploads';
  private readonly publicUrl = (process.env.MINIO_PUBLIC_URL || 'http://localhost:9000').replace(/\/$/, '');

  constructor() {
    this.client = new Minio.Client({
      endPoint: process.env.MINIO_ENDPOINT || 'localhost',
      port: Number(process.env.MINIO_PORT || 9000),
      useSSL: process.env.MINIO_USE_SSL === 'true',
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
}
