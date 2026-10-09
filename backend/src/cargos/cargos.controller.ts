import { Body, Controller, ForbiddenException, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { IsString } from 'class-validator';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ResponsesService } from '../responses/responses.service';
import { CreateResponseDto } from '../responses/dto/update-response.dto';
import { CargosService, CompanyCargoTab } from './cargos.service';
import { CreateCargoDto } from './dto/create-cargo.dto';
import { UpdateCargoDto } from './dto/update-cargo.dto';
import { CloseCargoDto } from './dto/close-cargo.dto';
import { RevealContactDto } from '../contact-events/dto/reveal-contact.dto';

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
  feed(@CurrentUser() ctx: RequestContext, @Query('limit') limit?: string, @Query('offset') offset?: string) {
    return this.cargos.feed(ctx.driver?.id, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Get('mine')
  mine(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.mine(ctx.companyMember.companyId);
  }

  /// 056 п.2: «Грузы» логиста по вкладкам, страницами; в архиве — поиск по
  /// городу (погрузки или назначения) и периоду погрузки.
  @Get('company')
  companyTab(
    @CurrentUser() ctx: RequestContext,
    @Query('tab') tab?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('cityId') cityId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    const safeTab: CompanyCargoTab = tab === 'work' || tab === 'archive' ? tab : 'active';
    const isDate = (v?: string) => (v && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : undefined);
    return this.cargos.companyTab(ctx.companyMember.companyId, {
      tab: safeTab,
      limit: limit ? Number(limit) || undefined : undefined,
      offset: offset ? Number(offset) || undefined : undefined,
      cityId: cityId || undefined,
      from: isDate(from),
      to: isDate(to),
      userId: ctx.user.id,
    });
  }

  /// 056 п.5: числа на вкладках и новые отклики сотрудника — цифра на «Грузах».
  @Get('company/counts')
  companyCounts(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.cargos.companyTabCounts(ctx.companyMember.companyId, ctx.user.id);
  }

  /// Задача 033, п.10 — «подходит N водителям на точке» при публикации.
  /// 047 п.7: «По этому маршруту за месяц: медиана 690 ₸/км, 8 сделок».
  @Get('market-hint')
  marketHint(
    @CurrentUser() ctx: RequestContext,
    @Query('pointId') pointId: string,
    @Query('destinationCountryId') destinationCountryId: string,
    @Query('destinationCityId') destinationCityId?: string,
    @Query('weightKg') weightKg?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    if (!pointId || !destinationCountryId) return { market: null };
    const w = weightKg != null && weightKg !== '' ? Number(weightKg) : undefined;
    return this.cargos.marketHint(pointId, destinationCityId || undefined, destinationCountryId, Number.isFinite(w) ? w : undefined);
  }

  @Get('fit-count')
  fitCount(
    @CurrentUser() ctx: RequestContext,
    @Query('weightKg') weightKg?: string,
    @Query('volumeM3') volumeM3?: string,
    @Query('palletCount') palletCount?: string,
    @Query('pointId') pointId?: string,
    @Query('bodyTypeIds') bodyTypeIds?: string,
    @Query('specs') specs?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    let parsedSpecs: Record<string, unknown> | undefined;
    try {
      parsedSpecs = specs ? (JSON.parse(specs) as Record<string, unknown>) : undefined;
    } catch {
      parsedSpecs = undefined;
    }
    return this.cargos.fitCount({
      weightKg: weightKg ? Number(weightKg) : undefined,
      volumeM3: volumeM3 ? Number(volumeM3) : undefined,
      palletCount: palletCount ? Number(palletCount) : undefined,
      pointId,
      // 048 п.4: кузова груза (через запятую) и его параметры (JSON).
      bodyTypeIds: bodyTypeIds ? bodyTypeIds.split(',').filter(Boolean) : undefined,
      specs: parsedSpecs,
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
    // 056 п.5: открыл отклики — «новые» у этого сотрудника гаснут.
    return this.responses.listForCargo(id, ctx.user.id);
  }

  /// Мой отклик на груз (041): карточка водителя показывает «Откликнуться» /
  /// «Вас приглашают» / «Отклик отправлен» по реальному состоянию, а не по
  /// локальному флагу. Обёртка в объект — не голый null (задача 027).
  /// «Помещается к текущему: 8 т + 10 т из 20 т» (задача 040, п.6).
  @Get(':id/partial-hint')
  partialHint(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.cargos.partialHint(ctx.driver.id, id);
  }

  @Get(':id/my-response')
  async myResponse(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return { response: await this.responses.findMine(id, ctx.driver.id) };
  }

  @Post(':id/responses')
  respond(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CreateResponseDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    // Откликаться может любой водитель с профилем (041, п.1); гейт проверки —
    // только на «Подтверждаю перевозку» (deals.controller).
    return this.responses.createForCargo(id, ctx.driver.id, dto.message);
  }

  /// «Позвонить»/WhatsApp (043 п.11): номер логиста — по нажатию, с лимитом.
  @Post(':id/contact')
  @HttpCode(200)
  contact(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: RevealContactDto) {
    return this.cargos.revealContact(ctx, id, dto.type);
  }

  /// «Договорились?» → «Да» (push с кнопками, 042): отклик + сигнал логисту.
  @Post(':id/agreed')
  agreed(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.responses.driverAgreed(id, ctx.driver.id);
  }

  @Post(':id/invite')
  async invite(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: InviteDriverDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    await this.cargos.assertCanEdit(id, ctx.companyMember.companyId, ctx.user.id, ctx.companyMember.role);
    return this.responses.inviteDriver(id, dto.driverId, ctx.companyMember.companyId, ctx.user.id);
  }
}
