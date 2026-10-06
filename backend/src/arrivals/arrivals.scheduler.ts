import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { JobLockService } from '../jobs/job-lock.service';
import { ArrivalsService } from './arrivals.service';

/// Фоновый ход правил свежести анонса (задача 040, п.4): напоминания
/// «Доехали?» / «Ещё ищете груз?» и гашение — раз в 5 минут, под замком в
/// Redis (042, п.4): на нескольких экземплярах — один проход.
@Injectable()
export class ArrivalsScheduler {
  private readonly logger = new Logger(ArrivalsScheduler.name);

  constructor(
    private readonly arrivals: ArrivalsService,
    private readonly lock: JobLockService,
  ) {}

  @Cron('*/5 * * * *')
  async tick() {
    if (process.env.JOBS_DISABLED === 'true') return;
    try {
      await this.lock.runExclusive('arrivals-sweep', 240, () => this.arrivals.sweep({ notify: true }));
    } catch (e) {
      this.logger.error(`arrivals sweep failed: ${(e as Error).message}`);
    }
  }
}
