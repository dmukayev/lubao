import { Body, Controller, ForbiddenException, Get, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { UpdateResponseDto } from './dto/update-response.dto';
import { ResponsesService } from './responses.service';

@Controller('responses')
export class ResponsesController {
  constructor(private readonly responses: ResponsesService) {}

  /// Мои отклики (041, п.9) — объявлен ДО `:id`, чтобы не перехватывался.
  @Get('mine')
  mine(@CurrentUser() ctx: RequestContext) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.responses.listMine(ctx.driver.id);
  }

  @Patch(':id')
  update(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: UpdateResponseDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.responses.updateStatus(id, ctx.companyMember.companyId, dto.status, ctx.user.id);
  }

  /// Задача 035 — «Отозвать» в чате (и в списке откликов тоже доступно
  /// тем же вызовом, если понадобится).
  @Post(':id/withdraw')
  withdraw(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.responses.withdraw(id, ctx.driver.id);
  }
}
