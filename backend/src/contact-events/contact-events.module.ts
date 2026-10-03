import { Module } from '@nestjs/common';
import { ContactEventsController } from './contact-events.controller';

@Module({
  controllers: [ContactEventsController],
})
export class ContactEventsModule {}
