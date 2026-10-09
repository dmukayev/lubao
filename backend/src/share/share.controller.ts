import { Body, Controller, Get, NotFoundException, Param, Post, Req, Res } from '@nestjs/common';
import { ShareType } from '@prisma/client';
import { IsIn, IsString } from 'class-validator';
import type { Request, Response } from 'express';
import { CurrentUser } from '../common/current-user.decorator';
import { Public } from '../common/public.decorator';
import { RequestContext } from '../common/request-context';
import { pageLocale } from './share-page';
import { SharePagesService } from './share-pages.service';
import { ShareService } from './share.service';

export class CreateShareDto {
  @IsIn(['CARGO', 'COMPANY', 'DRIVER'])
  type!: ShareType;

  @IsString()
  targetId!: string;
}

/// 052: «Поделиться» из приложения — короткая ссылка, куда вести по ней, вход по ссылке.
@Controller('share')
export class ShareController {
  constructor(private readonly shares: ShareService) {}

  @Post()
  create(@CurrentUser() ctx: RequestContext, @Body() dto: CreateShareDto) {
    return this.shares.create(ctx, dto.type, dto.targetId);
  }

  @Get(':code')
  resolve(@Param('code') code: string) {
    return this.shares.resolve(code);
  }

  /// Первый вход после установки по ссылке (отложенная ссылка) — засчитать автору.
  @Post(':code/claim')
  claim(@CurrentUser() ctx: RequestContext, @Param('code') code: string) {
    return this.shares.claim(ctx.user.id, code);
  }
}

/// 052 п.2: публичные страницы `/c|co|d/<код>` (nginx → `/p/...`) — без входа.
@Controller('p')
export class SharePageController {
  constructor(private readonly pages: SharePagesService) {}

  @Public()
  @Get([':kind/:code'])
  async page(@Param('kind') kind: string, @Param('code') code: string, @Req() req: Request, @Res() res: Response) {
    if (kind !== 'c' && kind !== 'co' && kind !== 'd') throw new NotFoundException();
    const html = await this.pages.render(code, pageLocale(req.headers['accept-language']), req.headers['user-agent'] ?? '');
    if (!html) throw new NotFoundException('Link not found');
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'no-store');
    res.send(html);
  }
}
