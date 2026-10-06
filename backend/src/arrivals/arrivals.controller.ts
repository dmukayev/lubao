import { Body, Controller, ForbiddenException, Get, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ArrivalsService } from './arrivals.service';
import { AnnounceArrivalDto, ArrivalActionDto } from './dto/arrival.dto';

@Controller('arrivals')
export class ArrivalsController {
  constructor(private readonly arrivals: ArrivalsService) {}

  @Get('me')
  me(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.getMine(ctx.user.id);
  }

  @Get('last-template')
  lastTemplate(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.getLastTemplate(ctx.user.id);
  }

  @Get()
  list(
    @CurrentUser() ctx: RequestContext,
    @Query('date') date?: string,
    @Query('today') today?: string,
    @Query('pointId') pointId?: string,
    @Query('countryId') countryId?: string,
    @Query('bodyTypeId') bodyTypeId?: string,
    @Query('minCapacityTons') minCapacityTons?: string,
    @Query('verifiedOnly') verifiedOnly?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.arrivals.listForCompany(ctx.companyMember.companyId, {
      date: date ? date.slice(0, 10) : undefined,
      today: today ? today.slice(0, 10) : undefined,
      pointId,
      countryId,
      bodyTypeId,
      minCapacityTons: minCapacityTons ? Number(minCapacityTons) : undefined,
      verifiedOnly: verifiedOnly === 'true',
    });
  }

  @Get('summary')
  summary(@CurrentUser() ctx: RequestContext, @Query('days') days?: string, @Query('pointId') pointId?: string, @Query('from') from?: string) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.arrivals.summary(days ? Number(days) : 7, pointId, from ? from.slice(0, 10) : undefined);
  }

  @Post()
  announce(@CurrentUser() ctx: RequestContext, @Body() dto: AnnounceArrivalDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.announce(ctx.user.id, dto);
  }

  @Post('repeat')
  repeat(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.repeat(ctx.user.id);
  }

  @Post('checkin')
  checkIn(@CurrentUser() ctx: RequestContext, @Body() dto: ArrivalActionDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.checkIn(ctx.user.id, dto?.arrivalId, dto?.pointId);
  }

  /// «Да, ещё ищу» на вопрос «Ещё ищете груз?» (задача 040, п.4).
  @Post('still-looking')
  stillLooking(@CurrentUser() ctx: RequestContext, @Body() dto: ArrivalActionDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.confirmStillLooking(ctx.user.id, dto?.arrivalId);
  }

  @Post('cancel')
  async cancel(@CurrentUser() ctx: RequestContext, @Body() dto: ArrivalActionDto) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    await this.arrivals.cancel(ctx.user.id, dto?.arrivalId);
    return { success: true };
  }
}
