import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { JobLockService } from './job-lock.service';
import { JobsService } from './jobs.service';

const TIME_ZONE = process.env.APP_TIMEZONE || 'Asia/Almaty';

/// Расписание фоновых задач (задача 042, п.4). Каждый запуск — под замком в
/// Redis: на нескольких экземплярах бэкенда задача идёт один раз. Сбой одной
/// задачи не роняет остальные и сам процесс.
@Injectable()
export class JobsScheduler implements OnApplicationBootstrap {
  private readonly logger = new Logger(JobsScheduler.name);

  constructor(
    private readonly jobs: JobsService,
    private readonly lock: JobLockService,
  ) {}

  private async run(name: string, ttlSeconds: number, task: () => Promise<unknown>) {
    try {
      const res = await this.lock.runExclusive(name, ttlSeconds, task);
      if (res.ran) this.logger.log(`${name}: ${JSON.stringify(res.result)}`);
    } catch (e) {
      this.logger.error(`${name} failed: ${(e as Error).message}`);
    }
  }

  /// Курса на сегодня ещё нет (первый старт, сервер лежал в 10:00) — берём сразу.
  onApplicationBootstrap() {
    if (process.env.JOBS_DISABLED === 'true') return;
    void this.run('rates-bootstrap', 120, () => this.jobs.ensureTodayRates());
  }

  @Cron('0 10 * * *', { timeZone: TIME_ZONE })
  rates() {
    return this.guarded('rates', 300, () => this.jobs.refreshExchangeRates());
  }

  @Cron('*/5 * * * *')
  agreedChecks() {
    return this.guarded('agreed-checks', 240, () => this.jobs.sendAgreedChecks());
  }

  @Cron('0 9 * * *', { timeZone: TIME_ZONE })
  agreedDigests() {
    return this.guarded('agreed-digests', 600, () => this.jobs.sendAgreedDigests());
  }

  @Cron('15 * * * *')
  archive() {
    return this.guarded('archive-cargos', 600, () => this.jobs.archiveCargos());
  }

  @Cron('30 * * * *')
  invitations() {
    return this.guarded('expire-invitations', 600, () => this.jobs.expireInvitations());
  }

  @Cron('0 3 * * *', { timeZone: TIME_ZONE })
  locations() {
    return this.guarded('cleanup-locations', 600, () => this.jobs.cleanupLocations());
  }

  @Cron('30 3 * * *', { timeZone: TIME_ZONE })
  sessions() {
    return this.guarded('cleanup-sessions', 600, () => this.jobs.cleanupSessions());
  }

  private guarded(name: string, ttlSeconds: number, task: () => Promise<unknown>) {
    if (process.env.JOBS_DISABLED === 'true') return;
    return this.run(name, ttlSeconds, task);
  }
}
