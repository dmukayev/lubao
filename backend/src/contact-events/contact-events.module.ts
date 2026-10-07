import { Module } from '@nestjs/common';
import { ContactEventsController } from './contact-events.controller';
import { ContactPolicyService } from './contact-policy.service';

@Module({
  controllers: [ContactEventsController],
  providers: [ContactPolicyService],
  exports: [ContactPolicyService],
})
export class ContactEventsModule {}
