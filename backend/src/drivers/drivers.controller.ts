import { Body, Controller, ForbiddenException, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CreateVehicleDto, SetVehicleSizeDto } from './dto/create-vehicle.dto';
import { CreateVerificationDocumentDto } from './dto/create-verification-document.dto';
import { UpdateDriverDto } from './dto/update-driver.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { DriversService } from './drivers.service';

@Controller('drivers')
export class DriversController {
  constructor(private readonly drivers: DriversService) {}

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
