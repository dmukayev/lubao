-- 045 п.5: кузов/тоннаж из регистрации — предпочтение водителя, а не машины-заглушки.
ALTER TABLE "drivers" ADD COLUMN "preferredBodyTypeId" TEXT, ADD COLUMN "preferredCapacityTons" DECIMAL(6,2);
ALTER TABLE "drivers" ADD CONSTRAINT "drivers_preferredBodyTypeId_fkey" FOREIGN KEY ("preferredBodyTypeId") REFERENCES "body_types"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Предпочтение всем водителям — из первого прицепа/грузовика гаража (заглушки тоже годятся).
UPDATE "drivers" d SET
  "preferredBodyTypeId" = v."bodyTypeId",
  "preferredCapacityTons" = v."capacityTons"
FROM (
  SELECT DISTINCT ON ("driverId") "driverId", "bodyTypeId", "capacityTons"
  FROM "vehicles"
  WHERE "kind" IN ('TRAILER', 'RIGID') AND "bodyTypeId" IS NOT NULL
  ORDER BY "driverId", "createdAt" ASC
) v
WHERE v."driverId" = d."id";

-- Заглушки регистрации: без госномера, без документов и ни в одной сделке.
CREATE TEMP TABLE stub_vehicles AS
SELECT v."id" FROM "vehicles" v
WHERE v."plateNumber" IS NULL
  AND NOT EXISTS (SELECT 1 FROM "verification_documents" vd WHERE vd."vehicleId" = v."id")
  AND NOT EXISTS (SELECT 1 FROM "deals" dl WHERE dl."tractorId" = v."id" OR dl."trailerId" = v."id");

UPDATE "arrivals" SET "tractorId" = NULL WHERE "tractorId" IN (SELECT "id" FROM stub_vehicles);
UPDATE "arrivals" SET "trailerId" = NULL WHERE "trailerId" IN (SELECT "id" FROM stub_vehicles);
DELETE FROM "identifiers" WHERE "ownerType" = 'VEHICLE' AND "ownerId" IN (SELECT "id" FROM stub_vehicles);
DELETE FROM "vehicles" WHERE "id" IN (SELECT "id" FROM stub_vehicles);
DROP TABLE stub_vehicles;
