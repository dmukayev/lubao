import { Body, Controller, Delete, ForbiddenException, Get, Param, Patch, Post, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { AppSettingsService } from '../app-settings/app-settings.service';
import { AdminService } from './admin.service';
import {
  AdminChangeMemberEmailDto,
  AdminDealStatusDto,
  AdminReasonDto,
  AdminSetMemberRoleDto,
  AdminUpdateCargoDto,
  AdminUpdateCityDto,
  AdminUpdateCompanyDto,
  AdminUpdateDriverDto,
  AdminUpdatePointDto,
  AdminUpdateReferenceItemDto,
  BlockUserDto,
  CargoSearchQueryDto,
  CreateBodyTypeDto,
  CreatePermitDto,
  CreatePointDto,
  DealSearchQueryDto,
  ModerateCityDto,
  ResolveComplaintDto,
  ReturnForReworkDto,
  ReviewVerificationDocumentDto,
  SearchQueryDto,
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
    await this.admin.setAppSetting(ctx.user.id, key, dto.value, dto.reason);
    return { success: true };
  }

  @Get('translation-stats')
  async translationStats(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.translationStats();
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

  @Get('cargos/:id')
  cargoDetail(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.cargoDetail(id);
  }

  @Patch('cargos/:id')
  updateCargo(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateCargoDto) {
    assertAdmin(ctx);
    return this.admin.updateCargo(id, ctx.user.id, dto);
  }

  @Post('cargos/:id/unpublish')
  unpublishCargo(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminReasonDto) {
    assertAdmin(ctx);
    return this.admin.unpublishCargo(id, ctx.user.id, dto.reason);
  }

  @Get('deals/:id')
  dealDetail(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.dealDetail(id);
  }

  @Get('deals/:id/chat')
  dealChat(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.dealChat(id, ctx.user.id);
  }

  @Patch('deals/:id/status')
  advanceDealStatus(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminDealStatusDto) {
    assertAdmin(ctx);
    return this.admin.advanceDealStatusByAdmin(id, ctx.user.id, dto);
  }

  @Post('deals/:id/cancel')
  cancelDeal(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminReasonDto) {
    assertAdmin(ctx);
    return this.admin.cancelDealByAdmin(id, ctx.user.id, dto.reason);
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

  @Get('verification-documents/:id/recognition')
  documentRecognition(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.documentRecognition(id);
  }

  @Post('identifiers/:id/reveal')
  revealIdentifier(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.revealIdentifier(id, ctx.user.id);
  }

  @Post('verification-documents/:id/recognition/:field/reveal')
  revealRecognizedField(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Param('field') field: string) {
    assertAdmin(ctx);
    return this.admin.revealRecognizedField(id, field, ctx.user.id);
  }

  @Get('documents/:id/file')
  async documentFile(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Res() res: Response) {
    assertAdmin(ctx);
    const source = await this.admin.documentFileSource(id);
    if ('redirectUrl' in source) {
      res.redirect(source.redirectUrl);
      return;
    }
    res.setHeader('Content-Type', source.contentType);
    source.stream.pipe(res);
  }

  @Get('verification/queue')
  verificationQueue(@CurrentUser() ctx: RequestContext, @Query('type') type?: string) {
    assertAdmin(ctx);
    return this.admin.verificationQueue(type === 'company' ? 'company' : 'driver');
  }

  @Get('verification/drivers/:id')
  verificationDriverProfile(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.verificationDriverProfile(id);
  }

  @Get('verification/companies/:id')
  verificationCompanyProfile(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.verificationCompanyProfile(id);
  }

  @Post('verification/drivers/:id/return')
  returnDriverForRework(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: ReturnForReworkDto) {
    assertAdmin(ctx);
    return this.admin.returnDriverForRework(id, ctx.user.id, dto);
  }

  @Post('verification/companies/:id/return')
  returnCompanyForRework(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: ReturnForReworkDto) {
    assertAdmin(ctx);
    return this.admin.returnCompanyForRework(id, ctx.user.id, dto);
  }

  @Get('complaints')
  complaints(@CurrentUser() ctx: RequestContext, @Query('tab') tab?: 'NEW' | 'IN_REVIEW' | 'CLOSED', @Query('mine') mine?: string) {
    assertAdmin(ctx);
    return this.admin.complaints({ tab, mine: mine === 'true' ? ctx.user.id : undefined });
  }

  @Get('complaints/counts')
  complaintCounts(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.admin.complaintCounts();
  }

  @Get('complaints/:id')
  complaintDetail(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.complaintDetail(id);
  }

  @Post('complaints/:id/assign')
  assignComplaint(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.assignComplaint(id, ctx.user.id);
  }

  @Post('complaints/:id/unassign')
  unassignComplaint(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    assertAdmin(ctx);
    return this.admin.unassignComplaint(id, ctx.user.id);
  }

  @Patch('complaints/:id')
  resolveComplaint(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: ResolveComplaintDto) {
    assertAdmin(ctx);
    return this.admin.resolveComplaint(id, ctx.user.id, dto);
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

  @Patch('companies/:id')
  updateCompany(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateCompanyDto) {
    assertAdmin(ctx);
    return this.admin.updateCompany(id, ctx.user.id, dto);
  }

  @Patch('companies/:companyId/members/:userId/role')
  setMemberRole(
    @CurrentUser() ctx: RequestContext,
    @Param('companyId') companyId: string,
    @Param('userId') userId: string,
    @Body() dto: AdminSetMemberRoleDto,
  ) {
    assertAdmin(ctx);
    return this.admin.setMemberRole(companyId, userId, ctx.user.id, dto);
  }

  @Delete('companies/:companyId/members/:userId')
  removeMember(
    @CurrentUser() ctx: RequestContext,
    @Param('companyId') companyId: string,
    @Param('userId') userId: string,
    @Body() dto: AdminReasonDto,
  ) {
    assertAdmin(ctx);
    return this.admin.removeMember(companyId, userId, ctx.user.id, dto.reason);
  }

  @Patch('companies/:companyId/members/:userId/email')
  changeMemberEmail(
    @CurrentUser() ctx: RequestContext,
    @Param('companyId') companyId: string,
    @Param('userId') userId: string,
    @Body() dto: AdminChangeMemberEmailDto,
  ) {
    assertAdmin(ctx);
    return this.admin.changeMemberEmail(companyId, userId, ctx.user.id, dto);
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

  @Patch('drivers/:id')
  updateDriver(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateDriverDto) {
    assertAdmin(ctx);
    return this.admin.updateDriver(id, ctx.user.id, dto);
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

  @Patch('reference/body-types/:id')
  updateBodyType(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateReferenceItemDto) {
    assertAdmin(ctx);
    return this.admin.updateBodyType(id, ctx.user.id, dto);
  }

  @Post('reference/permits')
  createPermit(@CurrentUser() ctx: RequestContext, @Body() dto: CreatePermitDto) {
    assertAdmin(ctx);
    return this.admin.createPermit(dto);
  }

  @Patch('reference/permits/:id')
  updatePermit(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateReferenceItemDto) {
    assertAdmin(ctx);
    return this.admin.updatePermit(id, ctx.user.id, dto);
  }

  @Post('reference/points')
  createPoint(@CurrentUser() ctx: RequestContext, @Body() dto: CreatePointDto) {
    assertAdmin(ctx);
    return this.admin.createPoint(dto);
  }

  @Patch('reference/points/:id')
  updatePoint(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdatePointDto) {
    assertAdmin(ctx);
    return this.admin.updatePoint(id, ctx.user.id, dto);
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

  @Patch('cities/:id')
  updateCity(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminUpdateCityDto) {
    assertAdmin(ctx);
    return this.admin.updateCity(id, ctx.user.id, dto);
  }
}
