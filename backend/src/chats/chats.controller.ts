import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ChatsService } from './chats.service';
import { FindOrCreateChatDto } from './dto/find-or-create-chat.dto';
import { SendMessageDto } from './dto/send-message.dto';

@Controller('chats')
export class ChatsController {
  constructor(private readonly chats: ChatsService) {}

  @Get()
  myChats(@CurrentUser() ctx: RequestContext) {
    return this.chats.myChats(ctx);
  }

  @Post()
  findOrCreate(@CurrentUser() ctx: RequestContext, @Body() dto: FindOrCreateChatDto) {
    return this.chats.findOrCreate(ctx, dto);
  }

  @Get(':chatId')
  thread(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string) {
    return this.chats.thread(chatId, ctx);
  }

  @Get(':chatId/messages')
  messages(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string) {
    return this.chats.messages(chatId, ctx);
  }

  @Post(':chatId/messages')
  send(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string, @Body() dto: SendMessageDto) {
    return this.chats.send(chatId, ctx, dto.text);
  }
}
