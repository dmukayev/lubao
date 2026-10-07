import { Body, Controller, ForbiddenException, Get, Param, Patch, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { CancelDealDto, UpdateDealStatusDto } from './dto/deal-status.dto';
import { CreateReviewDto } from './dto/create-review.dto';
import { DealsService } from './deals.service';
import { ReviewsService } from './reviews.service';
import { DriverDocumentsService } from './driver-documents.service';

function partyContext(ctx: RequestContext) {
  return { driverId: ctx.driver?.id, companyId: ctx.companyMember?.companyId };
}

@Controller('deals')
export class DealsController {
  constructor(
    private readonly deals: DealsService,
    private readonly reviews: ReviewsService,
    private readonly driverDocs: DriverDocumentsService,
  ) {}

  /// Пакет документов водителя логисту (044 п.1): только по обоюдной сделке.
  @Get(':id/driver-documents')
  driverDocuments(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    return this.driverDocs.package(id, ctx);
  }

  /// Тот же пакет одним PDF (044 п.1).
  @Get(':id/driver-documents.pdf')
  async driverDocumentsPdf(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Res() res: Response) {
    const { buffer, filename } = await this.driverDocs.pdf(id, ctx);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Cache-Control', 'private, no-store');
    res.send(buffer);
  }

  @Get(':id/driver-documents/files/:documentId')
  async driverDocumentFile(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Param('documentId') documentId: string, @Res() res: Response) {
    const source = await this.driverDocs.file(id, documentId, ctx);
    if ('redirectUrl' in source) {
      res.redirect(source.redirectUrl);
      return;
    }
    res.setHeader('Content-Type', source.contentType);
    res.setHeader('Cache-Control', 'private, no-store');
    source.stream.pipe(res);
  }

  /// Водителю: «Логист открыл документы <когда>» (044 п.4).
  @Get(':id/driver-documents/access-log')
  driverDocumentsAccessLog(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    return this.driverDocs.accessLog(id, ctx);
  }

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
    return this.deals.cancel(id, partyContext(ctx), dto.reason, dto.reasonCode);
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
