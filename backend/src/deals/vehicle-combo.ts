import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/// Связка водителя на рейс: из анонса (на месте, иначе ближайший по дате), без
/// анонса — первые тягач и прицеп из гаража (032 п.5).
export async function currentVehicleCombo(
  client: Prisma.TransactionClient | Pick<PrismaService, 'arrival' | 'vehicle'>,
  driverId: string,
): Promise<{ tractorId: string | null; trailerId: string | null }> {
  // Анонсов может быть несколько (040): берём тот, где водитель на месте,
  // иначе ближайший по дате приезда.
  const arrivals = await client.arrival.findMany({
    where: { driverId, status: { in: ['PLANNED', 'ON_SITE'] } },
    orderBy: [{ plannedDay: 'asc' }, { createdAt: 'desc' }],
    select: { status: true, tractorId: true, trailerId: true },
  });
  const arrival = arrivals.find((a) => a.status === 'ON_SITE') ?? arrivals[0];
  if (arrival?.tractorId) return { tractorId: arrival.tractorId, trailerId: arrival.trailerId };

  // Нет активного анонса (отклик без анонса — например, логист пригласил
  // напрямую водителя, который ещё не анонсировался) — фолбэк на гараж.
  const [tractor, trailer] = await Promise.all([
    client.vehicle.findFirst({ where: { driverId, kind: { in: ['TRACTOR', 'RIGID'] }, isArchived: false }, orderBy: { createdAt: 'asc' } }),
    client.vehicle.findFirst({ where: { driverId, kind: 'TRAILER', isArchived: false }, orderBy: { createdAt: 'asc' } }),
  ]);
  return { tractorId: tractor?.id ?? null, trailerId: trailer?.id ?? null };
}
