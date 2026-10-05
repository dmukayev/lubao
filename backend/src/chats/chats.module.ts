import { Module } from '@nestjs/common';
import { AppSettingsModule } from '../app-settings/app-settings.module';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';

@Module({
  imports: [AppSettingsModule],
  controllers: [ChatsController],
  providers: [ChatsService],
})
export class ChatsModule {}
