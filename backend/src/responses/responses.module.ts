import { Module } from '@nestjs/common';
import { ChatsModule } from '../chats/chats.module';
import { IdentifiersModule } from '../identifiers/identifiers.module';
import { ResponsesController } from './responses.controller';
import { ResponsesService } from './responses.service';

@Module({
  imports: [ChatsModule, IdentifiersModule],
  controllers: [ResponsesController],
  providers: [ResponsesService],
  exports: [ResponsesService],
})
export class ResponsesModule {}
