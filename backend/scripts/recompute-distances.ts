// 049 п.11: пересчитать км и ₸/км у грузов после замены карты OSRM.
// Кэш пар городов сбрасывается (значения со старой карты), затем каждый
// активный груз с городом назначения — через DistanceService (тот же путь,
// что при публикации). Запуск: npx ts-node scripts/recompute-distances.ts
import { PrismaClient } from '@prisma/client';
import { DistanceService } from '../src/pricing/distance.service';
import { pricePerKm } from '../src/pricing/route-price';

(async () => {
  const prisma = new PrismaClient();
  const distance = new DistanceService(prisma as never);
  const dropped = await prisma.cityDistance.deleteMany({ where: { source: 'osrm' } });
  const cargos = await prisma.cargo.findMany({
    where: { status: { in: ['PUBLISHED', 'IN_DEAL'] }, destinationCityId: { not: null } },
    select: { id: true, price: true, destinationCityId: true, point: { select: { cityId: true } } },
  });
  let ok = 0;
  let missing = 0;
  const started = Date.now();
  for (const c of cargos) {
    const km = await distance.roadKm(c.point.cityId, c.destinationCityId);
    if (km == null) {
      missing += 1;
      continue;
    }
    await prisma.cargo.update({ where: { id: c.id }, data: { distanceKm: km, pricePerKm: pricePerKm(Number(c.price), km) } });
    ok += 1;
  }
  console.log(`кэш сброшен: ${dropped.count}; грузов: ${cargos.length}, пересчитано ${ok}, без маршрута ${missing}; ${Date.now() - started} мс`);
  await prisma.$disconnect();
})();
