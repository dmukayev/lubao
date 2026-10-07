import { UploadsService } from './uploads.service';

/// Подпись ссылки на документ — чистая HMAC без сети (ревью: в админке
/// «Одобрить» падало ECONNREFUSED — minio-js спрашивал регион у публичного
/// хоста, недоступного бэкенду).
describe('UploadsService.presignDocumentUrl', () => {
  const OLD = { ...process.env };
  afterEach(() => {
    process.env = { ...OLD };
  });

  it('подписывает ссылку на публичный хост, не обращаясь к нему', async () => {
    // Порт 1 на localhost закрыт: любой сетевой запрос упал бы.
    process.env.MINIO_PUBLIC_URL = 'http://127.0.0.1:1';
    const url = await new UploadsService().presignDocumentUrl('abc.jpg');
    expect(url.startsWith('http://127.0.0.1:1/')).toBe(true);
    expect(url).toContain('X-Amz-Signature=');
  });
});
