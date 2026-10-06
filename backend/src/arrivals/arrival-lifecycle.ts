import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { haversineKm } from '../common/geo';
import { localDateOnly, parseDateOnly } from '../common/date-only';

type Db = PrismaService | Prisma.TransactionClient;

/// Водитель подтвердил сделку в приложении → его анонс исполнил свою
/// работу и гаснет сам (задача 040, п.4): сначала тот, где он «на месте»;
/// если такого нет — ближайший запланированный на сегодня или раньше.
export async function completeArrivalForConfirmedDeal(db: Db, driverId: string, now = new Date()): Promise<void> {
  const onSite = await db.arrival.updateMany({
    where: { driverId, status: 'ON_SITE' },
    data: { status: 'COMPLETED' },
  });
  if (onSite.count > 0) return;

  const planned = await db.arrival.findFirst({
    where: { driverId, status: 'PLANNED', plannedDay: { lte: parseDateOnly(localDateOnly(now)) } },
    orderBy: { plannedDay: 'asc' },
  });
  if (planned) await db.arrival.update({ where: { id: planned.id }, data: { status: 'COMPLETED' } });
}

/// Геозона терминала (только kind=TERMINAL с координатами и радиусом):
/// водитель «на месте» вышел за радиус → автоматически «уехал».
export async function leaveTerminalIfOutside(db: Db, driverId: string, position: { lat: number; lng: number }): Promise<boolean> {
  const arrival = await db.arrival.findFirst({
    where: { driverId, status: 'ON_SITE', point: { kind: 'TERMINAL', lat: { not: null }, lng: { not: null }, radiusM: { not: null } } },
    include: { point: true },
  });
  if (!arrival?.point.lat || !arrival.point.lng || !arrival.point.radiusM) return false;
  const distanceM = haversineKm(position, { lat: Number(arrival.point.lat), lng: Number(arrival.point.lng) }) * 1000;
  if (distanceM <= arrival.point.radiusM) return false;
  await db.arrival.update({ where: { id: arrival.id }, data: { status: 'COMPLETED' } });
  return true;
}
