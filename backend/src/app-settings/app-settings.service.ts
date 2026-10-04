import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/// Ключ-значение настроек приложения, редактируемых в админке (задача 015):
/// сейчас единственный ключ — `defaultPointCityId` (точка загрузки по
/// умолчанию везде, где выбирается точка). В коде нигде не упоминается
/// «Хоргос» текстом — только через этот сервис.
@Injectable()
export class AppSettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(key: string): Promise<string | null> {
    const row = await this.prisma.appSetting.findUnique({ where: { key } });
    return row?.value ?? null;
  }

  async set(key: string, value: string): Promise<void> {
    await this.prisma.appSetting.upsert({
      where: { key },
      create: { key, value },
      update: { value },
    });
  }

  async all(): Promise<Record<string, string>> {
    const rows = await this.prisma.appSetting.findMany();
    return Object.fromEntries(rows.map((r) => [r.key, r.value]));
  }
}
