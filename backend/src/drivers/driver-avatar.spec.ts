import Jimp from 'jimp';
import { NotFoundException } from '@nestjs/common';
import { DriverAvatarService, AVATAR_SIZE } from './driver-avatar.service';
import { DriversController } from './drivers.controller';

/// 054: фото профиля водителя — миниатюра, согласие в журнал, доступ.
async function photo(width: number, height: number): Promise<Buffer> {
  const image = new Jimp(width, height, 0x3366ccff);
  return image.getBufferAsync(Jimp.MIME_JPEG);
}

function makeService(driver: Record<string, unknown> = { avatarFileKey: null }) {
  const prisma: any = {
    driver: {
      findUniqueOrThrow: jest.fn().mockResolvedValue(driver),
      findUnique: jest.fn().mockResolvedValue(driver),
      update: jest.fn(),
    },
    verificationDocument: { findFirst: jest.fn().mockResolvedValue({ id: 'selfie1', fileUrl: '11111111-1111-4111-8111-111111111111.jpg' }) },
    auditLog: { create: jest.fn() },
  };
  const uploads: any = {
    getDocumentBuffer: jest.fn(),
    uploadDocument: jest.fn().mockResolvedValue('22222222-2222-4222-8222-222222222222.jpg'),
    verifyDocumentOwnership: jest.fn().mockResolvedValue(true),
    removeDocument: jest.fn().mockResolvedValue(undefined),
  };
  return { prisma, uploads, service: new DriverAvatarService(prisma, uploads) };
}

describe('DriverAvatarService (054)', () => {
  it('миниатюра — квадрат 200×200 JPEG из большого снимка', async () => {
    const { service } = makeService();
    const thumb = await service.toThumbnail(await photo(1200, 1600));
    const image = await Jimp.read(thumb);
    expect(image.getWidth()).toBe(AVATAR_SIZE);
    expect(image.getHeight()).toBe(AVATAR_SIZE);
    expect(thumb.length).toBeLessThan(30_000);
    // Приложение шлёт снимки до 1600 px (photo_picker) — чистый JS успевает, но не мгновенно.
  }, 30_000);

  it('«Да»: копия принятого селфи → фото профиля, согласие в журнал; селфи не трогаем', async () => {
    const { service, prisma, uploads } = makeService();
    uploads.getDocumentBuffer.mockResolvedValue({ buffer: await photo(800, 800), contentType: 'image/jpeg' });

    const r = await service.setFromSelfie('d1', 'u1');

    expect(prisma.verificationDocument.findFirst).toHaveBeenCalledWith(expect.objectContaining({ where: { driverId: 'd1', type: 'SELFIE', status: 'APPROVED' } }));
    expect(uploads.uploadDocument).toHaveBeenCalledWith(expect.any(Buffer), 'jpg', 'image/jpeg', 'u1');
    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { avatarFileKey: '22222222-2222-4222-8222-222222222222.jpg', avatarUpdatedAt: expect.any(Date) } });
    expect(prisma.auditLog.create).toHaveBeenCalledWith({ data: expect.objectContaining({ action: 'DRIVER_AVATAR_SET', entityId: 'd1', metadata: { source: 'SELFIE', consent: 'LOGISTS_SEE_PHOTO' } }) });
    expect(uploads.removeDocument).not.toHaveBeenCalledWith('11111111-1111-4111-8111-111111111111.jpg');
    expect(r.avatarVersion).toEqual(expect.any(String));
  }, 30_000);

  it('без принятого селфи «Да» — 404', async () => {
    const { service, prisma } = makeService();
    prisma.verificationDocument.findFirst.mockResolvedValue(null);
    await expect(service.setFromSelfie('d1', 'u1')).rejects.toThrow(NotFoundException);
  });

  it('чужой файл не ставится', async () => {
    const { service, uploads } = makeService();
    uploads.verifyDocumentOwnership.mockResolvedValue(false);
    await expect(service.setFromUpload('d1', 'u1', '33333333-3333-4333-8333-333333333333.jpg')).rejects.toMatchObject({ response: { code: 'INVALID_FILE' } });
  });

  it('«Убрать» админом — файл удалён, ключ обнулён, в журнал с причиной', async () => {
    const { service, prisma, uploads } = makeService({ avatarFileKey: 'old.jpg' });
    await service.remove('d1', 'admin-1', 'ADMIN', 'Неподходящее фото');
    // 057 п.12: после «Убрать» предложение «поставить селфи» не всплывает снова.
    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { avatarFileKey: null, avatarUpdatedAt: expect.any(Date), avatarOfferDismissedAt: expect.any(Date) } });
    expect(prisma.auditLog.create).toHaveBeenCalledWith({ data: expect.objectContaining({ action: 'DRIVER_AVATAR_REMOVED_BY_ADMIN', metadata: { reason: 'Неподходящее фото' } }) });
    expect(uploads.removeDocument).toHaveBeenCalledWith('old.jpg');
  });
});

describe('GET /drivers/:id/avatar — кто видит (054 п.4)', () => {
  function controller(fileKey: string | null) {
    const avatars: any = { fileKey: jest.fn().mockResolvedValue(fileKey) };
    const uploads: any = { getDocumentStream: jest.fn().mockResolvedValue({ stream: { pipe: jest.fn() }, contentType: 'image/jpeg' }) };
    return { avatars, uploads, c: new DriversController({} as any, {} as any, {} as any, uploads, avatars) };
  }
  const res = () => ({ setHeader: jest.fn() }) as any;

  it('любая вошедшая компания (и непроверенная) — 200, Cache-Control private на сутки', async () => {
    const { c, uploads } = controller('k.jpg');
    const r = res();
    await c.avatar({ user: { id: 'l1', role: 'COMPANY' }, companyMember: { company: { isVerified: false } }, driver: null } as any, 'd1', r);
    expect(uploads.getDocumentStream).toHaveBeenCalledWith('k.jpg');
    expect(r.setHeader).toHaveBeenCalledWith('Cache-Control', 'private, max-age=86400');
  });

  it('другой водитель — 404; сам водитель и админ — видят', async () => {
    const { c } = controller('k.jpg');
    await expect(c.avatar({ user: { id: 'u2', role: 'DRIVER' }, companyMember: null, driver: { id: 'd2' } } as any, 'd1', res())).rejects.toThrow(NotFoundException);
    await expect(c.avatar({ user: { id: 'u1', role: 'DRIVER' }, companyMember: null, driver: { id: 'd1' } } as any, 'd1', res())).resolves.toBeUndefined();
    await expect(c.avatar({ user: { id: 'a', role: 'ADMIN' }, companyMember: null, driver: null } as any, 'd1', res())).resolves.toBeUndefined();
  });

  it('после «Убрать» (ключа нет) — 404', async () => {
    const { c } = controller(null);
    await expect(c.avatar({ user: { id: 'l1', role: 'COMPANY' }, companyMember: { company: {} }, driver: null } as any, 'd1', res())).rejects.toThrow(NotFoundException);
  });
});

describe('057 п.13: картинка-бомба и неподдерживаемые форматы', () => {
  const { readImageHeader } = require('./image-header');
  it('размеры PNG и JPEG — из заголовка', async () => {
    const png = await new Jimp(30, 20, 0xffffffff).getBufferAsync(Jimp.MIME_PNG);
    const jpg = await new Jimp(30, 20, 0xffffffff).getBufferAsync(Jimp.MIME_JPEG);
    expect(readImageHeader(png)).toEqual({ kind: 'png', width: 30, height: 20 });
    expect(readImageHeader(jpg)).toEqual({ kind: 'jpeg', width: 30, height: 20 });
  });
  it('PNG с заявленными 50 000×50 000 — отказ до разбора', async () => {
    const { service } = makeService();
    const bomb = await new Jimp(2, 2, 0xffffffff).getBufferAsync(Jimp.MIME_PNG);
    bomb.writeUInt32BE(50000, 16);
    bomb.writeUInt32BE(50000, 20);
    await expect(service.toThumbnail(bomb)).rejects.toMatchObject({ response: { code: 'IMAGE_TOO_LARGE' } });
  });
  it('HEIC — понятная ошибка, карточка предложения убирается', async () => {
    const { service, prisma, uploads } = makeService();
    const heic = Buffer.concat([Buffer.from([0, 0, 0, 24]), Buffer.from('ftypheic'), Buffer.alloc(16)]);
    uploads.getDocumentBuffer.mockResolvedValue({ buffer: heic, contentType: 'image/heic' });
    await expect(service.setFromSelfie('d1', 'u1')).rejects.toMatchObject({ response: { code: 'UNSUPPORTED_IMAGE_FORMAT' } });
    expect(prisma.driver.update).toHaveBeenCalledWith({ where: { id: 'd1' }, data: { avatarOfferDismissedAt: expect.any(Date) } });
  });
});

describe('ориентация и метаданные миниатюры (EXIF)', () => {
  /// EXIF APP1 c одной меткой Orientation (little-endian TIFF).
  function exifOrientation(value: number): Buffer {
    const tiff = Buffer.alloc(26);
    tiff.write('II', 0, 'ascii');
    tiff.writeUInt16LE(42, 2);
    tiff.writeUInt32LE(8, 4);
    tiff.writeUInt16LE(1, 8); // одна запись
    tiff.writeUInt16LE(0x0112, 10); // Orientation
    tiff.writeUInt16LE(3, 12); // SHORT
    tiff.writeUInt32LE(1, 14);
    tiff.writeUInt16LE(value, 18);
    tiff.writeUInt32LE(0, 22); // нет следующей IFD
    const body = Buffer.concat([Buffer.from('Exif\0\0', 'binary'), tiff]);
    const seg = Buffer.alloc(4);
    seg.writeUInt16BE(0xffe1, 0);
    seg.writeUInt16BE(body.length + 2, 2);
    return Buffer.concat([seg, body]);
  }

  it('снимок «лёжа» с Orientation=6 → миниатюра повёрнута один раз и без EXIF (ни пометки, ни координат)', async () => {
    // 40×20: левая половина красная, правая синяя; поворот на 90° по часовой
    // ставит красное наверх.
    const src = new Jimp(40, 20, 0x0000ffff);
    src.scan(0, 0, 20, 20, (_x, _y, idx) => {
      src.bitmap.data[idx] = 255;
      src.bitmap.data[idx + 2] = 0;
    });
    const plain = await src.getBufferAsync(Jimp.MIME_JPEG);
    const withExif = Buffer.concat([plain.subarray(0, 2), exifOrientation(6), plain.subarray(2)]);
    const { service } = makeService();
    const thumb = await service.toThumbnail(withExif);

    expect(thumb.includes(Buffer.from('Exif\0\0', 'binary'))).toBe(false);
    const out = await Jimp.read(thumb);
    const top = Jimp.intToRGBA(out.getPixelColor(100, 10));
    const bottom = Jimp.intToRGBA(out.getPixelColor(100, 190));
    expect(top.r).toBeGreaterThan(200);
    expect(top.b).toBeLessThan(60);
    expect(bottom.b).toBeGreaterThan(200);
    expect(bottom.r).toBeLessThan(60);
  }, 30_000);

  it('stripJpegMetadata убирает APP1 без перекодирования', async () => {
    const { stripJpegMetadata } = require('./image-header');
    const plain = await new Jimp(8, 8, 0xffffffff).getBufferAsync(Jimp.MIME_JPEG);
    const withExif = Buffer.concat([plain.subarray(0, 2), exifOrientation(6), plain.subarray(2)]);
    const stripped = stripJpegMetadata(withExif);
    expect(stripped.includes(Buffer.from('Exif\0\0', 'binary'))).toBe(false);
    expect(stripped.length).toBe(plain.length);
  });
});
