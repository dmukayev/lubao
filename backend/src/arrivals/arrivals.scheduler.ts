import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { ArrivalsService } from './arrivals.service';

/// Фоновый ход правил свежести анонса (задача 040, п.4): напоминания
/// «Доехали?» / «Ещё ищете груз?» и гашение — раз в 5 минут.
@Injectable()
export class ArrivalsScheduler {
  private readonly logger = new Logger(ArrivalsScheduler.name);

  constructor(private readonly arrivals: ArrivalsService) {}

  @Cron('*/5 * * * *')
  async tick() {
    try {
      await this.arrivals.sweep({ notify: true });
    } catch (e) {
      this.logger.error(`arrivals sweep failed: ${(e as Error).message}`);
    }
  }
}
