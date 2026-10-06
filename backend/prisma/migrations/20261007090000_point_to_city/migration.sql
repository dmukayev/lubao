-- Задача 040: точка → город. Свежесть анонса, вид точки, догруз.

CREATE TYPE "PointKind" AS ENUM ('CITY', 'TERMINAL');

ALTER TYPE "ArrivalStatus" ADD VALUE 'EXPIRED';
ALTER TYPE "NotificationEventGroup" ADD VALUE 'ARRIVAL_CHECK';

ALTER TABLE "points"
  ADD COLUMN "kind" "PointKind" NOT NULL DEFAULT 'CITY',
  ADD COLUMN "radiusM" INTEGER;

-- Все существующие точки были терминалами (Хоргос): сохраняем поведение.
UPDATE "points" SET "kind" = 'TERMINAL', "radiusM" = 3000;

ALTER TABLE "arrivals"
  ADD COLUMN "lastConfirmedAt" TIMESTAMP(3),
  ADD COLUMN "dayAskedAt" TIMESTAMP(3),
  ADD COLUMN "staleAskedAt" TIMESTAMP(3);

-- Уже сидящие на месте водители считаются подтвердившими в момент приезда.
UPDATE "arrivals" SET "lastConfirmedAt" = COALESCE("arrivedAt", "plannedAt") WHERE "status" = 'ON_SITE';

ALTER TABLE "cargos" ADD COLUMN "allowPartial" BOOLEAN NOT NULL DEFAULT false;
