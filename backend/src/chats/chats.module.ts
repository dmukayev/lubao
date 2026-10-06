import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { ChatSystemMessagesService } from './chat-system-messages.service';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';

@Module({
  imports: [AppSettingsModule],
  controllers: [ChatsController],
  providers: [ChatsService, ChatSystemMessagesService],
  exports: [ChatSystemMessagesService],
})
export class ChatsModule {}
