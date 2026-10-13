import { Controller, ForbiddenException, Get, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { GoodsService } from './goods.service';

/// 075: «Что везёте?» в форме груза.
@Controller('goods')
export class GoodsController {
  constructor(private readonly goods: GoodsService) {}

  @Get('search')
  search(@Query('q') q?: string) {
    return this.goods.search((q ?? '').slice(0, 100));
  }

  @Get('recent')
  recent(@CurrentUser() ctx: RequestContext) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.goods.recent(ctx.companyMember.companyId);
  }
}
