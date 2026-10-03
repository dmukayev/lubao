import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ChatsService } from './chats.service';
import { SendMessageDto } from './dto/send-message.dto';

@Controller('chats')
export class ChatsController {
  constructor(private readonly chats: ChatsService) {}

  @Get(':dealId')
  thread(@CurrentUser() ctx: RequestContext, @Param('dealId') dealId: string) {
    return this.chats.threadForDeal(dealId, ctx);
  }

  @Get(':dealId/messages')
  messages(@CurrentUser() ctx: RequestContext, @Param('dealId') dealId: string) {
    return this.chats.messages(dealId, ctx);
  }

  @Post(':dealId/messages')
  send(@CurrentUser() ctx: RequestContext, @Param('dealId') dealId: string, @Body() dto: SendMessageDto) {
    return this.chats.send(dealId, ctx, dto.text);
  }
}
