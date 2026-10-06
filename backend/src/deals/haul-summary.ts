import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/// «Уже везёт…» для логиста (задача 037, п.7 / 038, п.8) — сводка активных
/// сделок водителя, считается по ТЕМ ЖЕ правилам, что жёсткая проверка
/// вместимости при подтверждении (deals.service.ts#assertVehicleNotFull):
/// по тягачу (одна машина — одна загрузка), груз без веса — отдельный флаг
/// «машина занята», а не молчаливый +0 к сумме.
export type HaulInfo = {
  committedWeightKg: number;
  activeDealsCount: number;
  /// true — среди активных грузов есть груз без веса: сумма ниже неполная,
  /// клиент показывает «машина занята», а не «везёт 0 т».
  committedHasUnknownWeight: boolean;
  /// Куда и когда едет первый активный груз — для строки
  /// «Уже везёт: 8 т из 20 т · Алматы · погрузка завтра».
  committedDestinationCountryId: string | null;
  committedDestinationCityId: string | null;
  committedReadyDate: Date | null;
};

const EMPTY: HaulInfo = {
  committedWeightKg: 0,
  activeDealsCount: 0,
  committedHasUnknownWeight: false,
  committedDestinationCountryId: null,
  committedDestinationCityId: null,
  committedReadyDate: null,
};

/// `drivers` — пары (driverId, tractorId связки, по которой смотрим):
/// tractorId задан — считаются только сделки этого тягача; null (старые
/// анонсы/сделки без снимка связки) — все активные сделки водителя,
/// консервативно.
export async function haulInfoByDriver(
  prisma: PrismaService | Prisma.TransactionClient,
  drivers: { driverId: string; tractorId: string | null }[],
): Promise<Map<string, HaulInfo>> {
  const result = new Map<string, HaulInfo>();
  if (drivers.length === 0) return result;

  const deals = await prisma.deal.findMany({
    where: {
      driverId: { in: [...new Set(drivers.map((d) => d.driverId))] },
      status: { in: ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT'] },
    },
    select: {
      driverId: true,
      tractorId: true,
      cargo: { select: { weightKg: true, readyDate: true, destinationCountryId: true, destinationCityId: true } },
    },
    orderBy: { createdAt: 'asc' },
  });

  for (const { driverId, tractorId } of drivers) {
    // Сделка без снимка тягача (до миграции 031) — консервативно считаем
    // её к любой связке: неизвестно, какой машиной везут.
    const relevant = deals.filter(
      (d) => d.driverId === driverId && (tractorId == null || d.tractorId == null || d.tractorId === tractorId),
    );
    if (relevant.length === 0) {
      result.set(driverId, EMPTY);
      continue;
    }
    const first = relevant[0];
    result.set(driverId, {
      committedWeightKg: relevant.reduce((sum, d) => sum + (d.cargo?.weightKg != null ? Number(d.cargo.weightKg) : 0), 0),
      activeDealsCount: relevant.length,
      committedHasUnknownWeight: relevant.some((d) => d.cargo?.weightKg == null),
      committedDestinationCountryId: first.cargo?.destinationCountryId ?? null,
      committedDestinationCityId: first.cargo?.destinationCityId ?? null,
      committedReadyDate: first.cargo?.readyDate ?? null,
    });
  }
  return result;
}
