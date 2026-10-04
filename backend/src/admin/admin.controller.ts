import { Body, Controller, ForbiddenException, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { AdminService } from './admin.service';
import {
  BlockUserDto,
  CargoSearchQueryDto,
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  DealSearchQueryDto,
  ModerateCityDto,
  ResolveComplaintDto,
  ReviewVerificationDocumentDto,
  SearchQueryDto,
  SetActiveDto,
  SetAppSettingDto,
  SetVerifiedDto,
  StatsQueryDto,
} from './dto/admin.dto';

function assertAdmin(ctx: RequestContext) {
  if (ctx.user.role !== 'ADMIN') throw new ForbiddenException('Admins only');
}

@Controller('admin')
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly appSettings: AppSettingsService,
  ) {}

  @Get('settings')
  async settings(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.appSettings.all();
  }

  @Patch('settings/:key')
  async setSetting(@CurrentUser() ctx: RequestContext, @Param('key') key: string, @Body() dto: SetAppSettingDto) {
    assertAdmin(ctx);
    await this.appSettings.set(key, dto.value);
    return { success: true };
  }

  @Get('stats')
  stats(@CurrentUser() ctx: RequestContext, @Query() query: StatsQueryDto) {
    assertAdmin(ctx);
    return this.admin.stats(query.period);
  }

  @Get('attention')
  attention(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.attention();
  }

  @Get('events/recent')
  recentEvents(@CurrentUser() ctx: RequestContext, @Query('limit') limit?: string) {
    assertAdmin(ctx);
    return this.admin.recentEvents(limit ? Number(limit) : undefined);
  }

  @Get('audit')
  auditLog(
    @CurrentUser() ctx: RequestContext,
    @Query('actorUserId') actorUserId?: string,
    @Query('entityType') entityType?: string,
    @Query('since') since?: string,
    @Query('limit') limit?: string,
  ) {
    assertAdmin(ctx);
    return this.admin.auditLog({
      actorUserId,
      entityType,
      since: since ? new Date(since) : undefined,
      limit: limit ? Number(limit) : undefined,
    });
  }

  @Get('search')
  search(@CurrentUser() ctx: RequestContext, @Query('q') q: string) {
    assertAdmin(ctx);
    return this.admin.search(q ?? '');
  }

  @Get('cargos')
  searchCargos(@CurrentUser() ctx: RequestContext, @Query() query: CargoSearchQueryDto) {
    assertAdmin(ctx);
    return this.admin.searchCargos(query);
  }

  @Get('deals')
  searchDeals(@CurrentUser() ctx: RequestContext, @Query() query: DealSearchQueryDto) {
    assertAdmin(ctx);
    return this.admin.searchDeals(query);
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
  searchCompanies(@CurrentUser() ctx: RequestContext, @Query() query: SearchQueryDto) {
    assertAdmin(ctx);
    return this.admin.searchCompanies(query);
  }

  @Get('companies/:id')
  companyDetail(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.companyDetail(id);
  }

  @Patch('companies/:id/verify')
  setCompanyVerified(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetVerifiedDto) {
    assertAdmin(ctx);
    return this.admin.setCompanyVerified(id, ctx.user.id, dto);
  }

  @Post('companies/:id/reset-password')
  resetCompanyPassword(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.resetCompanyPassword(id, ctx.user.id);
  }

  @Post('companies/:id/block')
  blockCompany(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: BlockUserDto) {
    assertAdmin(ctx);
    return this.admin.blockCompany(id, ctx.user.id, dto);
  }

  @Post('companies/:id/unblock')
  unblockCompany(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: BlockUserDto) {
    assertAdmin(ctx);
    return this.admin.unblockCompany(id, ctx.user.id, dto);
  }

  @Get('drivers')
  searchDrivers(@CurrentUser() ctx: RequestContext, @Query() query: SearchQueryDto) {
    assertAdmin(ctx);
    return this.admin.searchDrivers(query);
  }

  @Get('drivers/:id')
  driverDetail(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.driverDetail(id);
  }

  @Patch('drivers/:id/verify')
  setDriverVerified(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: SetVerifiedDto) {
    assertAdmin(ctx);
    return this.admin.setDriverVerified(id, ctx.user.id, dto);
  }

  @Post('users/:userId/block')
  blockUser(@CurrentUser() ctx: RequestContext, @Param('userId') userId: string, @Body() dto: BlockUserDto) {
    assertAdmin(ctx);
    return this.admin.blockUser(userId, ctx.user.id, dto);
  }

  @Post('users/:userId/unblock')
  unblockUser(@CurrentUser() ctx: RequestContext, @Param('userId') userId: string, @Body() dto: BlockUserDto) {
    assertAdmin(ctx);
    return this.admin.unblockUser(userId, ctx.user.id, dto);
  }

  @Post('users/:userId/revoke-sessions')
  revokeSessions(@CurrentUser() ctx: RequestContext, @Param('userId') userId: string) {
    assertAdmin(ctx);
    return this.admin.revokeSessions(userId, ctx.user.id);
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
