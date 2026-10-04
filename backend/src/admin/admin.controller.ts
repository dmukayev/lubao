import { Body, Controller, ForbiddenException, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { AdminService } from './admin.service';
import {
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  ModerateCityDto,
  ResolveComplaintDto,
  ReviewVerificationDocumentDto,
  SetActiveDto,
  SetVerifiedDto,
} from './dto/admin.dto';

function assertAdmin(ctx: RequestContext) {
  if (ctx.user.role !== 'ADMIN') throw new ForbiddenException('Admins only');
}

@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('stats')
  stats(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.stats();
  }

  @Get('verification-documents')
  verificationDocuments(@CurrentUser() ctx: RequestContext, @Query('status') status?: string) {
    assertAdmin(ctx);
    return this.admin.verificationDocuments(status);
  }

  @Patch('verification-documents/:id')
  reviewVerificationDocument(
    @CurrentUser() ctx: RequestContext,
    @Param('id') id: string,
    @Body() dto: ReviewVerificationDocumentDto,
  ) {
    assertAdmin(ctx);
    return this.admin.reviewVerificationDocument(id, ctx.user.id, dto);
  }

  @Get('complaints')
  complaints(@CurrentUser() ctx: RequestContext, @Query('status') status?: string) {
    assertAdmin(ctx);
    return this.admin.complaints(status);
  }

  @Patch('complaints/:id')
  resolveComplaint(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: ResolveComplaintDto) {
    assertAdmin(ctx);
    return this.admin.resolveComplaint(id, ctx.user.id, dto.status);
  }

  @Get('companies')
  companies(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.companies();
  }

  @Patch('companies/:id/verify')
  setCompanyVerified(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetVerifiedDto) {
    assertAdmin(ctx);
    return this.admin.setCompanyVerified(id, dto.isVerified);
  }

  @Get('drivers')
  drivers(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.drivers();
  }

  @Patch('drivers/:id/verify')
  setDriverVerified(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetVerifiedDto) {
    assertAdmin(ctx);
    return this.admin.setDriverVerified(id, dto.isVerified);
  }

  @Post('reference/body-types')
  createBodyType(@CurrentUser() ctx: RequestContext, @Body() dto: CreateBodyTypeDto) {
    assertAdmin(ctx);
    return this.admin.createBodyType(dto);
  }

  @Post('reference/permits')
  createPermit(@CurrentUser() ctx: RequestContext, @Body() dto: CreatePermitDto) {
    assertAdmin(ctx);
    return this.admin.createPermit(dto);
  }

  @Post('reference/points')
  createPoint(@CurrentUser() ctx: RequestContext, @Body() dto: CreatePointDto) {
    assertAdmin(ctx);
    return this.admin.createPoint(dto);
  }

  @Patch('reference/points/:id/active')
  setPointActive(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetActiveDto) {
    assertAdmin(ctx);
    return this.admin.setPointActive(id, dto.isActive);
  }

  @Get('cities/pending')
  pendingCities(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.pendingCities();
  }

  @Patch('cities/:id/moderate')
  moderateCity(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: ModerateCityDto) {
    assertAdmin(ctx);
    return this.admin.moderateCity(id, ctx.user.id, dto);
  }
}
