import { BadRequestException, ForbiddenException, HttpException } from '@nestjs/common';
import { PD_CONSENT_VERSION } from '../auth/legal-consent';
import { detectImageType } from './image-type';
import { DAILY_UPLOAD_LIMIT, consumeUploadQuota } from './upload-quota';
import { UploadsController } from './uploads.controller';

const JPEG = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(20)]);
const PNG = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), Buffer.alloc(20)]);
const GIF = Buffer.from('GIF89a' + '\0'.repeat(10), 'latin1');
const WEBP = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBP'), Buffer.alloc(8)]);
const HEIC = Buffer.concat([Buffer.alloc(4), Buffer.from('ftypheic'), Buffer.alloc(8)]);

describe('загрузки: тип по байтам (задача 043, п.4)', () => {
  it.each([
    ['JPEG', JPEG, 'image/jpeg', 'jpg'],
    ['PNG', PNG, 'image/png', 'png'],
    ['GIF', GIF, 'image/gif', 'gif'],
    ['WebP', WEBP, 'image/webp', 'webp'],
    ['HEIC', HEIC, 'image/heic', 'heic'],
  ])('%s распознаётся', (_n, buf, mime, ext) => {
    expect(detectImageType(buf)).toEqual({ mime, ext });
  });

  it.each([
    ['исполняемый файл под видом картинки', Buffer.from('MZ\x90\x00\x03', 'latin1')],
    ['HTML', Buffer.from('<html><script>alert(1)</script>')],
    ['PDF', Buffer.from('%PDF-1.7')],
    ['SVG (скрипты внутри)', Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script/></svg>')],
    ['пусто', Buffer.alloc(0)],
    ['обрезанный PNG', Buffer.from([0x89, 0x50, 0x4e])],
    ['RIFF, но не WebP (WAV)', Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WAVE'), Buffer.alloc(8)])],
    ['ISO-контейнер, но не HEIC (mp4)', Buffer.concat([Buffer.alloc(4), Buffer.from('ftypisom'), Buffer.alloc(8)])],
  ])('%s — не картинка', (_n, buf) => {
    expect(detectImageType(buf)).toBeNull();
  });
});

describe('квота загрузок (задача 043, п.4)', () => {
  function fakeRedis() {
    const counts = new Map<string, number>();
    return {
      expire: jest.fn(),
      client: {
        incr: jest.fn(async (key: string) => {
          counts.set(key, (counts.get(key) ?? 0) + 1);
          return counts.get(key)!;
        }),
        expire: jest.fn().mockResolvedValue(1),
      },
    };
  }

  it(`${DAILY_UPLOAD_LIMIT}-й файл проходит, 51-й — 429; окно сутки от первой загрузки`, async () => {
    const redis = fakeRedis();
    for (let i = 0; i < DAILY_UPLOAD_LIMIT; i++) await consumeUploadQuota(redis as any, 'u1');
    await expect(consumeUploadQuota(redis as any, 'u1')).rejects.toBeInstanceOf(HttpException);
    expect(redis.client.expire).toHaveBeenCalledTimes(1);
    expect(redis.client.expire).toHaveBeenCalledWith('uploads:count:u1', 24 * 3600);
  });

  it('квота личная: другой пользователь не упирается в чужой счётчик', async () => {
    const redis = fakeRedis();
    for (let i = 0; i < DAILY_UPLOAD_LIMIT; i++) await consumeUploadQuota(redis as any, 'u1');
    await expect(consumeUploadQuota(redis as any, 'u2')).resolves.toBeUndefined();
  });
});

describe('UploadsController (задача 043, п.4)', () => {
  const ctx = { user: { id: 'u1', pdConsentAt: new Date(), pdConsentVersion: PD_CONSENT_VERSION } } as any;
  function setup() {
    const uploads = { uploadImage: jest.fn().mockResolvedValue('http://x/f.png'), uploadDocument: jest.fn().mockResolvedValue('key.png') };
    const redis = { client: { incr: jest.fn().mockResolvedValue(1), expire: jest.fn() } };
    return { controller: new UploadsController(uploads as any, redis as any), uploads, redis };
  }
  const file = (buffer: Buffer, over: Record<string, unknown> = {}) => ({ buffer, mimetype: 'image/png', originalname: 'photo.png', ...over }) as Express.Multer.File;

  it('картинка загружается; расширение и Content-Type — из байтов, а не от клиента', async () => {
    const { controller, uploads } = setup();
    await controller.uploadImage(ctx, file(PNG, { mimetype: 'application/x-evil', originalname: 'shell.php' }));
    expect(uploads.uploadImage).toHaveBeenCalledWith(PNG, 'png', 'image/png');
  });

  it('файл не картинка при заявленном image/png — 400, в хранилище не идёт, квота не тратится', async () => {
    const { controller, uploads, redis } = setup();
    await expect(controller.uploadImage(ctx, file(Buffer.from('<html>'), { mimetype: 'image/png' }))).rejects.toBeInstanceOf(BadRequestException);
    await expect(controller.uploadDocument(ctx, file(Buffer.from('MZ'), { mimetype: 'image/jpeg' }))).rejects.toBeInstanceOf(BadRequestException);
    expect(uploads.uploadImage).not.toHaveBeenCalled();
    expect(uploads.uploadDocument).not.toHaveBeenCalled();
    expect(redis.client.incr).not.toHaveBeenCalled();
  });

  it('документ: ключ загрузившего пишется как раньше, расширение — из байтов', async () => {
    const { controller, uploads } = setup();
    expect(await controller.uploadDocument(ctx, file(JPEG, { originalname: 'doc.exe' }))).toEqual({ key: 'key.png' });
    expect(uploads.uploadDocument).toHaveBeenCalledWith(JPEG, 'jpg', 'image/jpeg', 'u1');
  });

  it('без файла — 400', async () => {
    const { controller } = setup();
    await expect(controller.uploadImage(ctx, undefined)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('51-я загрузка за сутки — 429', async () => {
    const { controller, redis } = setup();
    redis.client.incr.mockResolvedValue(DAILY_UPLOAD_LIMIT + 1);
    await expect(controller.uploadImage(ctx, file(PNG))).rejects.toBeInstanceOf(HttpException);
  });

  it('043 п.2: документ без согласия на ПДн (или со старой версией) — 403 PD_CONSENT_REQUIRED, в хранилище не идёт', async () => {
    const { controller, uploads } = setup();
    for (const user of [{ id: 'u1', pdConsentAt: null, pdConsentVersion: null }, { id: 'u1', pdConsentAt: new Date(), pdConsentVersion: '2000-01-01' }]) {
      await expect(controller.uploadDocument({ user } as any, file(JPEG))).rejects.toMatchObject({ response: { code: 'PD_CONSENT_REQUIRED' } });
    }
    await expect(controller.uploadDocument({ user: { id: 'u1' } } as any, file(JPEG))).rejects.toBeInstanceOf(ForbiddenException);
    expect(uploads.uploadDocument).not.toHaveBeenCalled();
  });
});
