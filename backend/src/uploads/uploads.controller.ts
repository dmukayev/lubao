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
import { UploadsService } from './uploads.service';

const MAX_SIZE_BYTES = 8 * 1024 * 1024;

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @Post('image')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_SIZE_BYTES } }))
  async uploadImage(@UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('Only image files are allowed');
    }
    const url = await this.uploads.uploadImage(file.buffer, file.originalname, file.mimetype);
    return { url };
  }

  /// Для документов верификации (селфи, техпаспорта, права) — персональные
  /// данные, бакет приватный (задача 026, п.6). Возвращает `key`, не
  /// публичный URL; его и кладут в `VerificationDocument.fileUrl`.
  @Post('document')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: MAX_SIZE_BYTES } }))
  async uploadDocument(@CurrentUser() ctx: RequestContext, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('No file uploaded');
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('Only image files are allowed');
    }
    const key = await this.uploads.uploadDocument(file.buffer, file.originalname, file.mimetype, ctx.user.id);
    return { key };
  }
}
