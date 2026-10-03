import { Controller, ForbiddenException, Get, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ArrivalsService } from './arrivals.service';

@Controller('arrivals')
export class ArrivalsController {
  constructor(private readonly arrivals: ArrivalsService) {}

  @Get('me')
  me(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.getMine(ctx.user.id);
  }

  @Get()
  list(
    @CurrentUser() ctx: RequestContext,
    @Query('countryId') countryId?: string,
    @Query('bodyTypeId') bodyTypeId?: string,
    @Query('minCapacityTons') minCapacityTons?: string,
    @Query('verifiedOnly') verifiedOnly?: string,
  ) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.arrivals.listForCompany({
      countryId,
      bodyTypeId,
      minCapacityTons: minCapacityTons ? Number(minCapacityTons) : undefined,
      verifiedOnly: verifiedOnly === 'true',
    });
  }

  @Post('checkin')
  checkIn(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.arrivals.checkIn(ctx.user.id);
  }

  @Post('leave')
  async leave(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    await this.arrivals.leave(ctx.user.id);
    return { success: true };
  }
}
