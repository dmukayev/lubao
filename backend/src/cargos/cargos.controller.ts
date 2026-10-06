import { Body, Controller, ForbiddenException, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { IsString } from 'class-validator';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ResponsesService } from '../responses/responses.service';
import { CreateResponseDto } from '../responses/dto/update-response.dto';
import { CargosService } from './cargos.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { CloseCargoDto } from './dto/close-cargo.dto';

class InviteDriverDto {
  @IsString()
  driverId!: string;
}

@Controller('cargos')
export class CargosController {
  constructor(
    private readonly cargos: CargosService,
    private readonly responses: ResponsesService,
  ) {}

  @Get()
  feed(@CurrentUser() ctx: RequestContext) {
    return this.cargos.feed(ctx.driver?.id);
  }

  @Get('mine')
  mine(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.mine(ctx.companyMember.companyId);
  }

  /// Задача 033, п.10 — «подходит N водителям на точке» при публикации.
  @Get('fit-count')
  fitCount(
    @CurrentUser() ctx: RequestContext,
    @Query('weightKg') weightKg?: string,
    @Query('volumeM3') volumeM3?: string,
    @Query('palletCount') palletCount?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.fitCount({
      weightKg: weightKg ? Number(weightKg) : undefined,
      volumeM3: volumeM3 ? Number(volumeM3) : undefined,
      palletCount: palletCount ? Number(palletCount) : undefined,
    });
  }

  @Get(':id')
  byId(@Param('id') id: string) {
    return this.cargos.byId(id);
  }

  @Post()
  create(@CurrentUser() ctx: RequestContext, @Body() dto: CreateCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.create(ctx.companyMember.companyId, ctx.user.id, ctx.companyMember.company.isVerified, dto);
  }

  @Patch(':id')
  update(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: UpdateCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.update(ctx.companyMember.companyId, ctx.user.id, ctx.companyMember.role, id, dto);
  }

  @Get(':id/close-candidates')
  closeCandidates(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.closeCandidates(ctx.companyMember.companyId, id);
  }

  @Post(':id/close')
  async close(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CloseCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    await this.cargos.closeCargo(ctx.companyMember.companyId, ctx.user.id, ctx.companyMember.role, id, dto);
    return { success: true };
  }

  @Get(':id/responses')
  async responsesForCargo(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    await this.cargos.assertOwnedBy(id, ctx.companyMember.companyId);
    return this.responses.listForCargo(id);
  }

  @Post(':id/responses')
  respond(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CreateResponseDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    if (!ctx.driver.isVerified) throw new ForbiddenException('DRIVER_NOT_VERIFIED');
    return this.responses.createForCargo(id, ctx.driver.id, dto.message);
  }

  @Post(':id/invite')
  async invite(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: InviteDriverDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    await this.cargos.assertCanEdit(id, ctx.companyMember.companyId, ctx.user.id, ctx.companyMember.role);
    return this.responses.inviteDriver(id, dto.driverId, ctx.companyMember.companyId, ctx.user.id);
  }
}
