import { PrismaService } from '../prisma/prisma.service';

/// 056 п.5: «новые» отклики — ждущие решения (PENDING), которые этот
/// сотрудник ещё не видел: отклик стал ожидающим позже, чем он последний раз
/// открывал отклики груза. У каждого сотрудника своё.
export async function newResponsesByCargo(
  prisma: Pick<PrismaService, 'cargoResponsesSeen' | 'response'>,
  userId: string,
  cargoIds: string[],
): Promise<Map<string, number>> {
  const result = new Map<string, number>();
  if (cargoIds.length === 0) return result;
  const [seen, pending] = await Promise.all([
    prisma.cargoResponsesSeen.findMany({ where: { userId, cargoId: { in: cargoIds } }, select: { cargoId: true, seenAt: true } }),
    prisma.response.findMany({ where: { cargoId: { in: cargoIds }, status: 'PENDING' }, select: { cargoId: true, updatedAt: true } }),
  ]);
  const seenAt = new Map(seen.map((s) => [s.cargoId, s.seenAt]));
  for (const r of pending) {
    const at = seenAt.get(r.cargoId);
    if (!at || r.updatedAt > at) result.set(r.cargoId, (result.get(r.cargoId) ?? 0) + 1);
  }
  return result;
}

/// Сотрудник открыл отклики груза — всё, что было до этого момента, уже не «новое».
export async function markResponsesSeen(prisma: Pick<PrismaService, 'cargoResponsesSeen'>, userId: string, cargoId: string, at = new Date()) {
  await prisma.cargoResponsesSeen.upsert({
    where: { userId_cargoId: { userId, cargoId } },
    create: { userId, cargoId, seenAt: at },
    update: { seenAt: at },
  });
}
