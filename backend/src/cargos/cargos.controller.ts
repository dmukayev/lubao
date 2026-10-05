import { Body, Controller, ForbiddenException, Get, Param, Patch, Post } from '@nestjs/common';
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
  feed() {
    return this.cargos.feed();
  }

  @Get('mine')
  mine(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.mine(ctx.companyMember.companyId);
  }

  @Get(':id')
  byId(@Param('id') id: string) {
    return this.cargos.byId(id);
  }

  @Post()
  create(@CurrentUser() ctx: RequestContext, @Body() dto: CreateCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.create(ctx.companyMember.companyId, ctx.user.id, dto);
  }

  @Patch(':id')
  update(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: UpdateCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.update(ctx.companyMember.companyId, id, dto);
  }

  @Get(':id/close-candidates')
  closeCandidates(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.closeCandidates(ctx.companyMember.companyId, id);
  }

  @Post(':id/close')
  async close(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CloseCargoDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    await this.cargos.closeCargo(ctx.companyMember.companyId, id, dto);
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
    await this.cargos.assertOwnedBy(id, ctx.companyMember.companyId);
    return this.responses.inviteDriver(id, dto.driverId, ctx.companyMember.companyId);
  }
}
