import { Body, Controller, ForbiddenException, Get, HttpCode, NotFoundException, Param, Patch, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { UploadsService } from '../uploads/uploads.service';
import { ContactPolicyService } from '../contact-events/contact-policy.service';
import { RevealContactDto } from '../contact-events/dto/reveal-contact.dto';
import { PrismaService } from '../prisma/prisma.service';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CreateVehicleDto, SetVehicleSizeDto } from './dto/create-vehicle.dto';
import { CreateVerificationDocumentDto } from './dto/create-verification-document.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { DriversService } from './drivers.service';

@Controller('drivers')
export class DriversController {
  constructor(
    private readonly drivers: DriversService,
    private readonly prisma: PrismaService,
    private readonly contactPolicy: ContactPolicyService,
    private readonly uploads: UploadsService,
  ) {}

  /// Фото машин водителя для логиста (044 п.7): «Кто свободен», отклик. Пусто —
  /// у логиста «Фото нет». Только машины в работе (не архив).
  @Get(':id/vehicle-photos')
  async vehiclePhotos(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.companyMember) throw new ForbiddenException('Only company accounts');
    const photos = await this.prisma.verificationDocument.findMany({
      where: { driverId: id, type: { in: ['VEHICLE_PHOTO_FRONT', 'VEHICLE_PHOTO_SIDE'] }, vehicle: { isArchived: false } },
      orderBy: { createdAt: 'desc' },
      select: { id: true, type: true, vehicle: { select: { id: true, kind: true, plateNumber: true } } },
    });
    return photos.map((p) => ({ documentId: p.id, type: p.type, vehicleId: p.vehicle?.id ?? null, kind: p.vehicle?.kind ?? null, plateNumber: p.vehicle?.plateNumber ?? null }));
  }

  @Get(':id/vehicle-photos/:documentId')
  async vehiclePhotoFile(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Param('documentId') documentId: string, @Res() res: Response) {
    if (!ctx.companyMember) throw new ForbiddenException('Only company accounts');
    const doc = await this.prisma.verificationDocument.findFirst({
      where: { id: documentId, driverId: id, type: { in: ['VEHICLE_PHOTO_FRONT', 'VEHICLE_PHOTO_SIDE'] } },
      select: { fileUrl: true },
    });
    if (!doc) throw new NotFoundException('Photo not found');
    if (/^https?:\/\//.test(doc.fileUrl)) {
      res.redirect(doc.fileUrl);
      return;
    }
    const source = await this.uploads.getDocumentStream(doc.fileUrl);
    res.setHeader('Content-Type', source.contentType);
    res.setHeader('Cache-Control', 'private, max-age=300');
    source.stream.pipe(res);
  }

  /// «Позвонить»/WhatsApp логиста (043 п.11): номер водителя — по нажатию,
  /// только проверенной компании, с суточным лимитом; в списках номера нет.
  @Post(':id/contact')
  @HttpCode(200)
  async contact(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: RevealContactDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Only company accounts call drivers');
    this.contactPolicy.assertCompanyMayContactDriver(ctx.companyMember.company);
    const driver = await this.prisma.driver.findUnique({ where: { id }, select: { id: true, user: { select: { phone: true } } } });
    if (!driver) throw new NotFoundException('Driver not found');
    if (!driver.user.phone) throw new NotFoundException({ code: 'NO_PHONE', message: 'Driver has no phone' });
    await this.contactPolicy.consume(ctx.user.id, `driver:${id}`);
    // Груз — только свой, иначе в contact_events не пишем (чужой id — не ошибка звонка).
    const cargo = dto.cargoId
      ? await this.prisma.cargo.findFirst({ where: { id: dto.cargoId, companyId: ctx.companyMember.companyId }, select: { id: true } })
      : null;
    await this.contactPolicy.record({ actorUserId: ctx.user.id, driverId: id, companyId: ctx.companyMember.companyId, cargoId: cargo?.id, type: dto.type });
    return { phone: driver.user.phone };
  }

  @Get('me')
  me(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.getByUserId(ctx.user.id);
  }

  @Patch('me')
  updateMe(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateDriverDto) {
    // Намеренно не требуем ctx.driver: этот же эндпоинт завершает быструю
    // регистрацию (анкеты ещё нет) и редактирует профиль (анкета уже есть).
    if (ctx.user.role !== 'DRIVER') throw new ForbiddenException('Not a driver account');
    return this.drivers.updateProfile(ctx.user.id, dto);
  }

  @Patch('me/location')
  updateLocation(@CurrentUser() ctx: RequestContext, @Body() dto: UpdateLocationDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.updateLocation(ctx.user.id, dto.lat, dto.lng);
  }

  /// 045 п.10: подставить ФИО из одобренных прав.
  @Post('me/accept-license-name')
  @HttpCode(200)
  acceptLicenseName(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.acceptLicenseName(ctx.user.id);
  }

  @Get('me/verification-documents')
  verificationDocuments(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.listVerificationDocuments(ctx.driver.id);
  }

  @Post('me/verification-documents')
  submitVerificationDocument(@CurrentUser() ctx: RequestContext, @Body() dto: CreateVerificationDocumentDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.submitVerificationDocument(ctx.user.id, ctx.driver.id, dto);
  }

  @Get('me/verification-documents/:id/recognition')
  documentRecognition(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.documentRecognition(ctx.driver.id, id);
  }

  @Get('me/vehicles')
  vehicles(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.listVehicles(ctx.driver.id);
  }

  @Post('me/vehicles')
  addVehicle(@CurrentUser() ctx: RequestContext, @Body() dto: CreateVehicleDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.createVehicle(ctx.user.id, ctx.driver.id, dto);
  }

  @Post('me/vehicles/:id/archive')
  archiveVehicle(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.archiveVehicle(ctx.driver.id, id);
  }

  @Patch('me/vehicles/:id/size')
  setVehicleSize(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetVehicleSizeDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.drivers.setVehicleSize(ctx.driver.id, id, dto);
  }
}
