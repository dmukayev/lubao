import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { RedisService } from '../redis/redis.service';
import { assertPdConsent } from '../auth/pd-consent';
import { detectImageType } from './image-type';
import { consumeUploadQuota } from './upload-quota';
import { UploadsService } from './uploads.service';

const MAX_SIZE_BYTES = 8 * 1024 * 1024;

@Controller('uploads')
export class UploadsController {
  constructor(
    private readonly uploads: UploadsService,
    private readonly redis: RedisService,
  ) {}

  /// Файл должен реально быть картинкой (по байтам, не по заявленному типу),
  /// расширение и Content-Type берутся из распознанного типа, а не от клиента;
  /// на пользователя — 50 загрузок в сутки (задача 043, п.4).
  private async checkedImage(ctx: RequestContext, file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');
    const detected = detectImageType(file.buffer);
    if (!detected) throw new BadRequestException('Only image files are allowed');
    await consumeUploadQuota(this.redis, ctx.user.id);
    return detected;
  }

  @Post('image')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_SIZE_BYTES } }))
  async uploadImage(@CurrentUser() ctx: RequestContext, @UploadedFile() file?: Express.Multer.File) {
    const detected = await this.checkedImage(ctx, file);
    const url = await this.uploads.uploadImage(file!.buffer, detected.ext, detected.mime);
    return { url };
  }

  /// Для документов верификации (селфи, техпаспорта, права) — персональные
  /// данные, бакет приватный (задача 026, п.6). Возвращает `key`, не
  /// публичный URL; его и кладут в `VerificationDocument.fileUrl`.
  @Post('document')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_SIZE_BYTES } }))
  async uploadDocument(@CurrentUser() ctx: RequestContext, @UploadedFile() file?: Express.Multer.File) {
    assertPdConsent(ctx.user);
    const detected = await this.checkedImage(ctx, file);
    const key = await this.uploads.uploadDocument(file!.buffer, detected.ext, detected.mime, ctx.user.id);
    return { key };
  }
}
