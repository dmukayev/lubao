import { Body, Controller, ForbiddenException, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { AdminGoodsDto, AdminHsChapterDto, AdminHsNameDto } from './admin-goods.dto';
import { AdminGoodsService } from './admin-goods.service';

function assertAdmin(ctx: RequestContext) {
  if (ctx.user.role !== 'ADMIN') throw new ForbiddenException('Admins only');
}

/// 075 п.10–11: справочники товаров в админке.
@Controller('admin/reference')
export class AdminGoodsController {
  constructor(private readonly goods: AdminGoodsService) {}

  @Get('goods')
  listGoods(@CurrentUser() ctx: RequestContext, @Query('q') q?: string, @Query('noCode') noCode?: string) {
    assertAdmin(ctx);
    return this.goods.listGoods(q, noCode === 'true' || noCode === '1');
  }

  @Post('goods')
  createGoods(@CurrentUser() ctx: RequestContext, @Body() dto: AdminGoodsDto) {
    assertAdmin(ctx);
    return this.goods.createGoods(ctx.user.id, dto);
  }

  @Patch('goods/:id')
  updateGoods(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: AdminGoodsDto) {
    assertAdmin(ctx);
    return this.goods.updateGoods(ctx.user.id, id, dto);
  }

  @Get('hs-codes')
  listHs(@CurrentUser() ctx: RequestContext, @Query('q') q?: string, @Query('page') page?: string) {
    assertAdmin(ctx);
    return this.goods.listHs(q, Number(page) || 1);
  }

  @Patch('hs-codes/:code')
  updateHs(@CurrentUser() ctx: RequestContext, @Param('code') code: string, @Body() dto: AdminHsNameDto) {
    assertAdmin(ctx);
    return this.goods.updateHsName(ctx.user.id, code, dto);
  }

  @Get('hs-chapters')
  listChapters(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.goods.listChapters();
  }

  @Patch('hs-chapters/:chapter')
  updateChapter(@CurrentUser() ctx: RequestContext, @Param('chapter') chapter: string, @Body() dto: AdminHsChapterDto) {
    assertAdmin(ctx);
    return this.goods.updateChapter(ctx.user.id, chapter, dto);
  }

  @Get('goods-new-words')
  newWords(@CurrentUser() ctx: RequestContext) {
    assertAdmin(ctx);
    return this.goods.newWords();
  }
}
