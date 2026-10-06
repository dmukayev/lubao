import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { UploadsService } from '../uploads/uploads.service';
import { Public } from '../common/public.decorator';
import { withTimeout } from '../common/with-timeout';

const CHECK_TIMEOUT_MS = 3000;

@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly uploads: UploadsService,
  ) {}

  @Public()
  @Get()
  check() {
    return { status: 'ok' };
  }

  @Public()
  @Get('db')
  async checkDb() {
    await this.prisma.$queryRaw`SELECT 1`;
    return { status: 'ok' };
  }

  /// Готовность (задача 043, п.6): Postgres, Redis и MinIO отвечают. Для
  /// проверки балансировщика/мониторинга; без деталей ошибок наружу — только
  /// какая из зависимостей не отвечает.
  @Public()
  @Get('ready')
  async ready() {
    const run = async (check: () => Promise<unknown>): Promise<'ok' | 'down'> => {
      try {
        await withTimeout(check(), CHECK_TIMEOUT_MS, 'health check timed out');
        return 'ok';
      } catch {
        return 'down';
      }
    };
    const [postgres, redis, minio] = await Promise.all([
      run(() => this.prisma.$queryRaw`SELECT 1`),
      run(() => this.redis.client.ping()),
      run(() => this.uploads.ping()),
    ]);
    const checks = { postgres, redis, minio };
    if (Object.values(checks).includes('down')) {
      throw new ServiceUnavailableException({ status: 'degraded', checks });
    }
    return { status: 'ok', checks };
  }
}
