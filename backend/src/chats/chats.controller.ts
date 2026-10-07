import { Body, Controller, Get, HttpCode, Param, Patch, Post } from '@nestjs/common';
import { RevealContactDto } from '../contact-events/dto/reveal-contact.dto';
import { CurrentUser } from '../common/current-user.decorator';
import { RequestContext } from '../common/request-context';
import { ChatsService } from './chats.service';
import { AttachCargoDto } from './dto/attach-cargo.dto';
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

  /// «Позвонить» из чата (043 п.11): номер собеседника — по нажатию, с лимитом.
  @Post(':chatId/contact')
  @HttpCode(200)
  contact(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string, @Body() dto: RevealContactDto) {
    return this.chats.revealContact(chatId, ctx, dto.type);
  }

  @Patch(':chatId/cargo')
  attachCargo(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string, @Body() dto: AttachCargoDto) {
    return this.chats.attachCargo(chatId, ctx, dto.cargoId);
  }

  @Get(':chatId/messages')
  messages(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string) {
    return this.chats.messages(chatId, ctx);
  }

  @Post(':chatId/messages')
  send(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string, @Body() dto: SendMessageDto) {
    return this.chats.send(chatId, ctx, dto.text);
  }

  @Post(':chatId/read')
  markRead(@CurrentUser() ctx: RequestContext, @Param('chatId') chatId: string) {
    return this.chats.markRead(chatId, ctx);
  }

  @Post(':chatId/messages/:messageId/retry-translation')
  retryTranslation(
    @CurrentUser() ctx: RequestContext,
    @Param('chatId') chatId: string,
    @Param('messageId') messageId: string,
  ) {
    return this.chats.retryTranslation(chatId, messageId, ctx);
  }
}
