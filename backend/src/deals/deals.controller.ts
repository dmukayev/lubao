import { Body, Controller, ForbiddenException, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CancelDealDto, UpdateDealStatusDto } from './dto/deal-status.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { DealsService } from './deals.service';
import { ReviewsService } from './reviews.service';

function partyContext(ctx: RequestContext) {
  return { driverId: ctx.driver?.id, companyId: ctx.companyMember?.companyId };
}

@Controller('deals')
export class DealsController {
  constructor(
    private readonly deals: DealsService,
    private readonly reviews: ReviewsService,
  ) {}

  @Get('mine')
  mine(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver && !ctx.companyMember) throw new ForbiddenException('No profile');
    return this.deals.mine(partyContext(ctx));
  }

  @Get(':id')
  byId(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    return this.deals.byId(id, partyContext(ctx));
  }

  @Patch(':id/status')
  advance(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: UpdateDealStatusDto) {
    if (!ctx.driver) throw new ForbiddenException('Only the driver can advance the deal status');
    if (dto.status === 'CONFIRMED_BY_DRIVER' && !ctx.driver.isVerified) {
      throw new ForbiddenException('DRIVER_NOT_VERIFIED');
    }
    return this.deals.advanceStatus(id, ctx.driver.id, dto.status);
  }

  @Patch(':id/cancel')
  cancel(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CancelDealDto) {
    return this.deals.cancel(id, partyContext(ctx), dto.reason);
  }

  @Get(':id/reviews')
  reviewsForDeal(@Param('id') id: string) {
    return this.reviews.forDeal(id);
  }

  @Post(':id/reviews')
  submitReview(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: CreateReviewDto) {
    const authorRole = ctx.driver ? 'DRIVER' : ctx.companyMember ? 'COMPANY' : null;
    if (!authorRole) throw new ForbiddenException('No profile');
    return this.reviews.submit(id, ctx.user.id, authorRole, dto.rating, dto.comment);
  }
}
