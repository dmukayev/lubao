import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { bootstrapAdminFromEnv } from './create-admin';

/// ADMIN_BOOTSTRAP_EMAIL / ADMIN_BOOTSTRAP_PASSWORD_HASH при первом старте,
/// если админов ещё нет (задача 043, п.5).
@Injectable()
export class AdminBootstrapService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AdminBootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onApplicationBootstrap() {
    try {
      if (await bootstrapAdminFromEnv(this.prisma, process.env)) this.logger.log('Создан первый администратор из ADMIN_BOOTSTRAP_*');
    } catch (e) {
      this.logger.error(`Первый администратор не создан: ${(e as Error).message}`);
    }
  }
}
