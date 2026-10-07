import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { ChatSystemMessagesService } from './chat-system-messages.service';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';
import { ContactEventsModule } from '../contact-events/contact-events.module';

@Module({
  imports: [AppSettingsModule, ContactEventsModule],
  controllers: [ChatsController],
  providers: [ChatsService, ChatSystemMessagesService],
  exports: [ChatSystemMessagesService],
})
export class ChatsModule {}
