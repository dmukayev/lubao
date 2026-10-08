import { PricingModule } from '../pricing/pricing.module';
import { DealsModule } from '../deals/deals.module';
import { Module } from '@nestjs/common';
import { ChatsModule } from '../chats/chats.module';
import { EmailModule } from '../email/email.module';
import { JobLockService } from './job-lock.service';
import { JobsScheduler } from './jobs.scheduler';
import { JobsService } from './jobs.service';

@Module({
  imports: [ChatsModule, EmailModule, DealsModule, PricingModule],
  providers: [JobLockService, JobsService, JobsScheduler],
  exports: [JobLockService, JobsService],
})
export class JobsModule {}
