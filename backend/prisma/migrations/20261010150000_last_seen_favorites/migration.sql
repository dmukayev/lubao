-- 058 п.7: «в сети / был в сети».
ALTER TABLE "users" ADD COLUMN "lastSeenAt" TIMESTAMP(3);

-- 058 п.8: избранные грузы водителя.
CREATE TABLE "cargo_favorites" (
    "driverId" TEXT NOT NULL,
    "cargoId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "cargo_favorites_pkey" PRIMARY KEY ("driverId","cargoId")
);
CREATE INDEX "cargo_favorites_cargoId_idx" ON "cargo_favorites"("cargoId");
ALTER TABLE "cargo_favorites" ADD CONSTRAINT "cargo_favorites_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cargo_favorites" ADD CONSTRAINT "cargo_favorites_cargoId_fkey" FOREIGN KEY ("cargoId") REFERENCES "cargos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
