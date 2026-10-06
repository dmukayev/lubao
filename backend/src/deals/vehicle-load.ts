import { Cargo, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { toDateOnly } from '../common/date-only';

export const ACTIVE_HAUL_STATUSES = ['CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT'] as const;

export type VehicleLoadVerdict = 'NONE' | 'OK' | 'NEXT_TRIP' | 'FULL';

export interface VehicleLoad {
  /// NONE — активных сделок нет (догруз не обсуждается); OK — помещается;
  /// NEXT_TRIP — другое окно дат (следующий рейс); FULL — не помещается.
  verdict: VehicleLoadVerdict;
  activeDealsCount: number;
  usedWeightKg: number;
  capacityKg: number | null;
  deals: {
    dealId: string;
    weightKg: number | null;
    readyDate: string | null;
    destinationCountryId: string | null;
    destinationCityId: string | null;
  }[];
}

/// Задача 037 — догруз разрешён, «бронь всего подряд» — нет: суммируются ВСЕ
/// активные сделки водителя на ту же связку машин (+ новый груз). Правила:
/// - вес: Σ ≤ capacityTons×1000; груз БЕЗ веса = полная загрузка;
/// - объём/паллеты: только когда известны и у машины, и у всех грузов;
/// - даты погрузки всех грузов в окне ±1 день от нового — иначе это не
///   догруз, а следующий рейс.
/// Единый расчёт: им пользуются и жёсткая проверка при «Подтверждаю
/// перевозку» (DealsService), и подсказка «Помещается к текущему» в ленте
/// (задача 040, п.6).
export async function evaluateVehicleLoad(
  db: Prisma.TransactionClient | PrismaService,
  params: {
    driverId: string;
    tractorId: string | null;
    trailerId: string | null;
    cargo: Pick<Cargo, 'weightKg' | 'volumeM3' | 'palletCount' | 'readyDate'>;
    excludeDealId?: string;
  },
): Promise<VehicleLoad> {
  const { driverId, tractorId, trailerId, cargo, excludeDealId } = params;

  // Задача 038, п.6 — активные сделки считаем по ТЯГАЧУ, без прицепа в
  // фильтре: одна машина везёт одну загрузку, и смена прицепа в анонсе —
  // не способ подтвердить вторую полную машину тем же тягачом. Прицеп
  // участвует только как источник вместимости (ниже).
  const activeDeals = await db.deal.findMany({
    where: {
      driverId,
      status: { in: [...ACTIVE_HAUL_STATUSES] },
      // п.26 (038): при tractorId == null консервативно считаем ВСЕ
      // активные сделки водителя (как haul-summary.ts), а не только
      // сделки с tractorId IS NULL; сделки без снимка тягача — к любой связке.
      ...(tractorId ? { OR: [{ tractorId }, { tractorId: null }] } : {}),
      ...(excludeDealId ? { id: { not: excludeDealId } } : {}),
    },
    include: { cargo: true },
  });
  if (activeDeals.length === 0) {
    return { verdict: 'NONE', activeDealsCount: 0, usedWeightKg: 0, capacityKg: null, deals: [] };
  }

  const bodyVehicleId = trailerId ?? tractorId;
  const vehicle = bodyVehicleId ? await db.vehicle.findUnique({ where: { id: bodyVehicleId } }) : null;
  const capacityKg = vehicle?.capacityTons != null ? Number(vehicle.capacityTons) * 1000 : null;

  const allCargos = [cargo, ...activeDeals.map((d) => d.cargo).filter((c): c is NonNullable<typeof c> => c != null)];
  const deals = activeDeals.map((d) => ({
    dealId: d.id,
    weightKg: d.cargo?.weightKg != null ? Number(d.cargo.weightKg) : null,
    readyDate: d.cargo?.readyDate ? toDateOnly(d.cargo.readyDate) : null,
    destinationCountryId: d.cargo?.destinationCountryId ?? null,
    destinationCityId: d.cargo?.destinationCityId ?? null,
  }));
  const usedWeightKg = activeDeals.reduce((sum, d) => sum + (d.cargo?.weightKg != null ? Number(d.cargo.weightKg) : 0), 0);
  const result = (verdict: VehicleLoadVerdict): VehicleLoad => ({ verdict, activeDealsCount: activeDeals.length, usedWeightKg, capacityKg, deals });

  const DAY_MS = 24 * 60 * 60 * 1000;
  const newReady = cargo.readyDate.getTime();
  const sameWindow = activeDeals.every((d) => d.cargo != null && Math.abs(d.cargo.readyDate.getTime() - newReady) <= DAY_MS);
  if (!sameWindow) return result('NEXT_TRIP');

  // Задача 038, п.6 — прицеп без тоннажа: вместимость неизвестна, догруз
  // не посчитать — разрешаем только ОДНУ активную сделку на тягач
  // (раньше вес вообще не проверялся, и лимита не было).
  if (capacityKg == null) return result('FULL');

  // Груз без веса занимает машину целиком — второй рядом не подтвердить.
  if (allCargos.some((c) => c.weightKg == null)) return result('FULL');
  const totalKg = allCargos.reduce((sum, c) => sum + Number(c.weightKg), 0);
  if (totalKg > capacityKg) return result('FULL');
  if (vehicle?.volumeM3 != null && allCargos.every((c) => c.volumeM3 != null)) {
    const totalM3 = allCargos.reduce((sum, c) => sum + Number(c.volumeM3), 0);
    if (totalM3 > Number(vehicle.volumeM3)) return result('FULL');
  }
  if (vehicle?.palletsEuro != null && allCargos.every((c) => c.palletCount != null)) {
    const totalPallets = allCargos.reduce((sum, c) => sum + (c.palletCount as number), 0);
    if (totalPallets > vehicle.palletsEuro) return result('FULL');
  }
  return result('OK');
}
