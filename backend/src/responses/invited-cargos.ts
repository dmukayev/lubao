import { PrismaClient } from '@prisma/client';

export type InvitedCargo = { cargoId: string; pointId: string; destinationCountryId: string; destinationCityId: string | null };

/// 071 п.4: на какие опубликованные грузы компании водитель уже приглашён и
/// ещё не ответил — «Приглашён: Хоргос → Алматы» в «Кто свободен» и «Мои
/// водители»; на тот же груз второй раз не пригласить.
export async function invitedCargosByDriver(db: Pick<PrismaClient, 'response'>, companyId: string, driverIds: string[]): Promise<Map<string, InvitedCargo[]>> {
  const out = new Map<string, InvitedCargo[]>();
  if (!driverIds.length) return out;
  const rows = await db.response.findMany({
    where: { driverId: { in: driverIds }, status: 'INVITED', cargo: { companyId, status: 'PUBLISHED' } },
    orderBy: { updatedAt: 'desc' },
    select: { driverId: true, cargo: { select: { id: true, pointId: true, destinationCountryId: true, destinationCityId: true } } },
  });
  for (const r of rows) {
    const list = out.get(r.driverId) ?? [];
    list.push({ cargoId: r.cargo.id, pointId: r.cargo.pointId, destinationCountryId: r.cargo.destinationCountryId, destinationCityId: r.cargo.destinationCityId });
    out.set(r.driverId, list);
  }
  return out;
}
