-- 044 п.6–7: автопроверка машины и фото машины.
ALTER TYPE "VerificationDocType" ADD VALUE IF NOT EXISTS 'VEHICLE_PHOTO_FRONT';
ALTER TYPE "VerificationDocType" ADD VALUE IF NOT EXISTS 'VEHICLE_PHOTO_SIDE';

CREATE TYPE "VehicleVerifier" AS ENUM ('ADMIN', 'AUTO');
ALTER TABLE "vehicles" ADD COLUMN "verifiedBy" "VehicleVerifier", ADD COLUMN "verifiedAt" TIMESTAMP(3);

-- Уже проверенные машины проверял админ — так и записываем.
UPDATE "vehicles" SET "verifiedBy" = 'ADMIN', "verifiedAt" = "updatedAt" WHERE "isVerified" = true;
