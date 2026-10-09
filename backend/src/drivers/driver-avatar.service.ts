import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import Jimp from 'jimp';
import { PrismaService } from '../prisma/prisma.service';
import { UploadsService } from '../uploads/uploads.service';
import { MAX_AVATAR_PIXELS, readImageHeader } from './image-header';

/// Сторона миниатюры (054 п.4): список водителей не тянет большие файлы.
export const AVATAR_SIZE = 200;

/// 054: фото профиля водителя. Отдельный объект в приватном бакете — не селфи
/// проверки (его доступ, 044, не меняется). Ставится только с согласия водителя
/// (журнал), убирается им самим или админом.
@Injectable()
export class DriverAvatarService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: UploadsService,
  ) {}

  /// Квадрат 200×200 по центру, JPEG — из любого снимка (селфи, камера).
  async toThumbnail(source: Buffer): Promise<Buffer> {
    // 057 п.13: размеры — из заголовка до разбора; HEIC/WEBP — понятная ошибка.
    const header = readImageHeader(source);
    if (header.kind === 'heic' || header.kind === 'webp') {
      throw new BadRequestException({ code: 'UNSUPPORTED_IMAGE_FORMAT', message: 'HEIC/WEBP are not supported — use JPEG or PNG' });
    }
    if (header.kind !== 'png' && header.kind !== 'jpeg') throw new BadRequestException({ code: 'INVALID_IMAGE', message: 'Not an image' });
    if (header.width * header.height > MAX_AVATAR_PIXELS) {
      throw new BadRequestException({ code: 'IMAGE_TOO_LARGE', message: 'Image is too large' });
    }
    try {
      const image = await Jimp.read(source);
      image.cover(AVATAR_SIZE, AVATAR_SIZE).quality(82);
      return await image.getBufferAsync(Jimp.MIME_JPEG);
    } catch {
      throw new BadRequestException({ code: 'INVALID_IMAGE', message: 'Not an image' });
    }
  }

  /// Принятое селфи водителя — источник для «Да» на предложении.
  private async approvedSelfie(driverId: string) {
    return this.prisma.verificationDocument.findFirst({
      where: { driverId, type: 'SELFIE', status: 'APPROVED' },
      orderBy: { createdAt: 'desc' },
      select: { id: true, fileUrl: true },
    });
  }

  /// Предлагать «Поставить это фото в профиль?» один раз: селфи принято,
  /// фото ещё нет и водитель не отказался («Не сейчас»).
  async offerAvailable(driver: { id: string; avatarFileKey: string | null; avatarOfferDismissedAt: Date | null }): Promise<boolean> {
    if (driver.avatarFileKey || driver.avatarOfferDismissedAt) return false;
    return !!(await this.approvedSelfie(driver.id));
  }

  /// «Да»: копия принятого селфи (миниатюра) → фото профиля.
  async setFromSelfie(driverId: string, userId: string) {
    const selfie = await this.approvedSelfie(driverId);
    if (!selfie) throw new NotFoundException({ code: 'NO_APPROVED_SELFIE', message: 'No approved selfie' });
    if (/^https?:\/\//.test(selfie.fileUrl)) throw new BadRequestException({ code: 'NO_APPROVED_SELFIE', message: 'Legacy selfie cannot be copied' });
    const { buffer } = await this.uploads.getDocumentBuffer(selfie.fileUrl);
    let thumb: Buffer;
    try {
      thumb = await this.toThumbnail(buffer);
    } catch (e) {
      // Селфи в формате, который не разобрать, — карточку предложения убираем:
      // «Да» всё равно не сработает, остаётся «Сменить фото».
      await this.prisma.driver.update({ where: { id: driverId }, data: { avatarOfferDismissedAt: new Date() } });
      throw e;
    }
    return this.store(driverId, userId, thumb, 'SELFIE');
  }

  /// «Сделать другое» / «Сменить фото»: файл, загруженный водителем через
  /// `POST /uploads/document` (ключ проверяется на владельца).
  async setFromUpload(driverId: string, userId: string, fileKey: string) {
    if (!(await this.uploads.verifyDocumentOwnership(fileKey, userId))) {
      throw new BadRequestException({ code: 'INVALID_FILE', message: 'Unknown file' });
    }
    const { buffer } = await this.uploads.getDocumentBuffer(fileKey);
    const thumb = await this.toThumbnail(buffer);
    const result = await this.store(driverId, userId, thumb, 'CAMERA');
    await this.uploads.removeDocument(fileKey).catch(() => undefined);
    return result;
  }

  private async store(driverId: string, userId: string, thumb: Buffer, source: 'SELFIE' | 'CAMERA') {
    const key = await this.uploads.uploadDocument(thumb, 'jpg', 'image/jpeg', userId);
    const before = await this.prisma.driver.findUniqueOrThrow({ where: { id: driverId }, select: { avatarFileKey: true } });
    const now = new Date();
    await this.prisma.driver.update({ where: { id: driverId }, data: { avatarFileKey: key, avatarUpdatedAt: now } });
    // Согласие на новую цель (логисты видят лицо) — в журнал.
    await this.prisma.auditLog.create({
      data: { actorUserId: userId, action: 'DRIVER_AVATAR_SET', entityType: 'Driver', entityId: driverId, metadata: { source, consent: 'LOGISTS_SEE_PHOTO' } },
    });
    if (before.avatarFileKey) await this.uploads.removeDocument(before.avatarFileKey).catch(() => undefined);
    return { avatarVersion: now.toISOString() };
  }

  /// «Не сейчас» — больше не предлагаем.
  async dismissOffer(driverId: string) {
    await this.prisma.driver.update({ where: { id: driverId }, data: { avatarOfferDismissedAt: new Date() } });
  }

  /// «Убрать» — водитель сам или админ (жалоба на неподходящее фото).
  async remove(driverId: string, actorUserId: string, by: 'DRIVER' | 'ADMIN', reason?: string) {
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, select: { avatarFileKey: true } });
    if (!driver) throw new NotFoundException('Driver not found');
    if (!driver.avatarFileKey) return { avatarVersion: null };
    // 057 п.12: убрал фото — предложение «поставить селфи» больше не всплывает.
    await this.prisma.driver.update({ where: { id: driverId }, data: { avatarFileKey: null, avatarUpdatedAt: new Date(), avatarOfferDismissedAt: new Date() } });
    await this.prisma.auditLog.create({
      data: { actorUserId, action: by === 'ADMIN' ? 'DRIVER_AVATAR_REMOVED_BY_ADMIN' : 'DRIVER_AVATAR_REMOVED', entityType: 'Driver', entityId: driverId, metadata: reason ? { reason } : undefined },
    });
    await this.uploads.removeDocument(driver.avatarFileKey).catch(() => undefined);
    return { avatarVersion: null };
  }

  /// Ключ файла для отдачи; null — фото нет (404).
  async fileKey(driverId: string): Promise<string | null> {
    const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, select: { avatarFileKey: true } });
    return driver?.avatarFileKey ?? null;
  }
}
