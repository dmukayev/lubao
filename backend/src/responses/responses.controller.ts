import { Body, Controller, ForbiddenException, Param, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { UpdateResponseDto } from './dto/update-response.dto';
import { ResponsesService } from './responses.service';

@Controller('responses')
export class ResponsesController {
  constructor(private readonly responses: ResponsesService) {}

  @Patch(':id')
  update(@CurrentUser() ctx: RequestContext, @Param('id') id: string, @Body() dto: UpdateResponseDto) {
    if (!ctx.companyMember) throw new ForbiddenException('Not a company account');
    return this.responses.updateStatus(id, ctx.companyMember.companyId, dto.status);
  }

  /// Задача 035 — «Отозвать» в чате (и в списке откликов тоже доступно
  /// тем же вызовом, если понадобится).
  @Post(':id/withdraw')
  withdraw(@CurrentUser() ctx: RequestContext, @Param('id') id: string) {
    if (!ctx.driver) throw new ForbiddenException('Not a driver account');
    return this.responses.withdraw(id, ctx.driver.id);
  }
}
