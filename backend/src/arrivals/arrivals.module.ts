import { Module } from '@nestjs/common';
import { ArrivalsController } from './arrivals.controller';
import { ArrivalsScheduler } from './arrivals.scheduler';
import { ArrivalsService } from './arrivals.service';

@Module({
  controllers: [ArrivalsController],
  providers: [ArrivalsService, ArrivalsScheduler],
})
export class ArrivalsModule {}
