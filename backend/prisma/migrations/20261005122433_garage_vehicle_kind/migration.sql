-- Задача 031, этап A — гараж: тягач и прицеп раздельно вместо одной Vehicle
-- на всю связку. Текущая Vehicle на самом деле хранит ОБЕ половины сразу
-- (госномер+марка тягача И кузов+тоннаж+длина прицепа в одной строке) — её
-- нельзя просто пометить kind='TRACTOR', иначе кузов/тоннаж потеряются.
-- Правило CLAUDE.md про миграции: база уже содержит демо-данные (водители с
-- машинами и одобренными техпаспортами) — ничего не чистим, каждую
-- существующую Vehicle разделяем на пару TRACTOR+TRAILER и переносим
-- VerificationDocument/флаги isVerified по новому правилу (решение
-- 2026-10-05 «Распознавание документов и чёрный список» /
-- «Несколько машин: гараж»).

-- CreateEnum
CREATE TYPE "VehicleKind" AS ENUM ('TRACTOR', 'TRAILER', 'RIGID');

-- AlterTable vehicles: новые колонки, kind пока nullable — заполним ниже.
ALTER TABLE "vehicles" DROP CONSTRAINT "vehicles_bodyTypeId_fkey";
ALTER TABLE "vehicles"
  ADD COLUMN     "kind" "VehicleKind",
  ADD COLUMN     "vin" TEXT,
  ADD COLUMN     "isOwner" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN     "isVerified" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN     "isArchived" BOOLEAN NOT NULL DEFAULT false,
  ALTER COLUMN "bodyTypeId" DROP NOT NULL;
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_bodyTypeId_fkey" FOREIGN KEY ("bodyTypeId") REFERENCES "body_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable arrivals/deals/verification_documents: новые nullable колонки.
ALTER TABLE "arrivals" ADD COLUMN     "tractorId" TEXT,
ADD COLUMN     "trailerId" TEXT;

ALTER TABLE "deals" ADD COLUMN     "tractorId" TEXT,
ADD COLUMN     "trailerId" TEXT;

ALTER TABLE "verification_documents" ADD COLUMN     "vehicleId" TEXT;

-- === Данные: разделение существующих Vehicle на TRACTOR + TRAILER ===

-- Для каждой текущей строки (kind ещё NULL — значит, она из версии до этой
-- миграции) создаём парную TRAILER-запись с кузовом/тоннажем/длиной,
-- сохраняя оригинальный id и driverId.
INSERT INTO "vehicles" (
  id, "driverId", kind, "bodyTypeId", "plateNumber", vin, brand,
  "capacityTons", "lengthM", "isOwner", "isVerified", "isActive", "isArchived",
  "createdAt", "updatedAt"
)
SELECT
  gen_random_uuid(), v."driverId", 'TRAILER', v."bodyTypeId", NULL, NULL, NULL,
  v."capacityTons", v."lengthM", v."isOwner", false, v."isActive", false,
  v."createdAt", now()
FROM "vehicles" v
WHERE v."kind" IS NULL;

-- Исходная строка становится TRACTOR — госномер и марка остаются, кузов и
-- тоннаж/длина (уже скопированные выше в TRAILER) обнуляются.
UPDATE "vehicles"
SET "kind" = 'TRACTOR', "bodyTypeId" = NULL, "capacityTons" = NULL, "lengthM" = NULL
WHERE "kind" IS NULL;

ALTER TABLE "vehicles" ALTER COLUMN "kind" SET NOT NULL;

-- VEHICLE_PASSPORT (техпаспорт тягача) -> новая TRACTOR-запись того же водителя.
UPDATE "verification_documents" vd
SET "vehicleId" = t.id
FROM "vehicles" t
WHERE vd."type" = 'VEHICLE_PASSPORT'
  AND vd."driverId" IS NOT NULL
  AND t."driverId" = vd."driverId"
  AND t."kind" = 'TRACTOR'
  AND vd."vehicleId" IS NULL;

-- TRAILER_PASSPORT -> новая TRAILER-запись того же водителя.
UPDATE "verification_documents" vd
SET "vehicleId" = tr.id
FROM "vehicles" tr
WHERE vd."type" = 'TRAILER_PASSPORT'
  AND vd."driverId" IS NOT NULL
  AND tr."driverId" = vd."driverId"
  AND tr."kind" = 'TRAILER'
  AND vd."vehicleId" IS NULL;

-- Машина «проверена», если её техпаспорт уже был одобрен до миграции.
UPDATE "vehicles" v
SET "isVerified" = true
WHERE EXISTS (
  SELECT 1 FROM "verification_documents" vd
  WHERE vd."vehicleId" = v.id AND vd."status" = 'APPROVED'
);

-- Задача 031, этап A, п.4 — правило верификации водителя сузилось до селфи+
-- прав (машины проверяются отдельно). Водитель, у которого ИМЕННО эти два
-- документа уже были одобрены (но старое правило из 4 документов ещё не
-- выполнялось целиком), теперь должен считаться проверенным.
UPDATE "drivers" d
SET "isVerified" = true
WHERE d."isVerified" = false
  AND EXISTS (SELECT 1 FROM "verification_documents" WHERE "driverId" = d.id AND "type" = 'SELFIE' AND "status" = 'APPROVED')
  AND EXISTS (SELECT 1 FROM "verification_documents" WHERE "driverId" = d.id AND "type" = 'DRIVER_LICENSE' AND "status" = 'APPROVED');

-- Связка по умолчанию для уже существующих заявок/сделок — тягач+прицеп
-- того же водителя (до этой миграции у водителя была ровно одна пара).
UPDATE "arrivals" a
SET "tractorId" = t.id, "trailerId" = tr.id
FROM "vehicles" t, "vehicles" tr
WHERE t."driverId" = a."driverId" AND t."kind" = 'TRACTOR'
  AND tr."driverId" = a."driverId" AND tr."kind" = 'TRAILER'
  AND a."tractorId" IS NULL;

UPDATE "deals" d
SET "tractorId" = t.id, "trailerId" = tr.id
FROM "vehicles" t, "vehicles" tr
WHERE t."driverId" = d."driverId" AND t."kind" = 'TRACTOR'
  AND tr."driverId" = d."driverId" AND tr."kind" = 'TRAILER'
  AND d."tractorId" IS NULL;

-- CreateIndex
CREATE INDEX "verification_documents_vehicleId_idx" ON "verification_documents"("vehicleId");

-- AddForeignKey
ALTER TABLE "arrivals" ADD CONSTRAINT "arrivals_tractorId_fkey" FOREIGN KEY ("tractorId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arrivals" ADD CONSTRAINT "arrivals_trailerId_fkey" FOREIGN KEY ("trailerId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_tractorId_fkey" FOREIGN KEY ("tractorId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "deals" ADD CONSTRAINT "deals_trailerId_fkey" FOREIGN KEY ("trailerId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "verification_documents" ADD CONSTRAINT "verification_documents_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "vehicles"("id") ON DELETE SET NULL ON UPDATE CASCADE;
