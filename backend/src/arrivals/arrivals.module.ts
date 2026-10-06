import { Module } from '@nestjs/common';
import { JobsModule } from '../jobs/jobs.module';
import { ArrivalsController } from './arrivals.controller';
import { ArrivalsScheduler } from './arrivals.scheduler';
import { ArrivalsService } from './arrivals.service';

@Module({
  imports: [JobsModule],
  controllers: [ArrivalsController],
  providers: [ArrivalsService, ArrivalsScheduler],
})
export class ArrivalsModule {}
