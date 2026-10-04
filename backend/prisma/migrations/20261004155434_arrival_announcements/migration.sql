-- AlterEnum
BEGIN;
CREATE TYPE "ArrivalStatus_new" AS ENUM ('PLANNED', 'ON_SITE', 'COMPLETED', 'CANCELLED');
ALTER TABLE "arrivals" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "arrivals" ALTER COLUMN "status" TYPE "ArrivalStatus_new" USING ("status"::text::"ArrivalStatus_new");
ALTER TYPE "ArrivalStatus" RENAME TO "ArrivalStatus_old";
ALTER TYPE "ArrivalStatus_new" RENAME TO "ArrivalStatus";
DROP TYPE "ArrivalStatus_old";
ALTER TABLE "arrivals" ALTER COLUMN "status" SET DEFAULT 'PLANNED';
COMMIT;

-- AlterTable
ALTER TABLE "arrivals" DROP COLUMN "expectedDepartureAt",
ADD COLUMN     "anyCountry" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "plannedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "waitDays" INTEGER NOT NULL DEFAULT 2,
ALTER COLUMN "arrivedAt" DROP NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'PLANNED';

-- CreateTable
CREATE TABLE "arrival_directions" (
    "id" TEXT NOT NULL,
    "arrivalId" TEXT NOT NULL,
    "countryId" TEXT NOT NULL,

    CONSTRAINT "arrival_directions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "arrival_views" (
    "id" TEXT NOT NULL,
    "arrivalId" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "viewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "arrival_views_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "app_settings" (
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,

    CONSTRAINT "app_settings_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE UNIQUE INDEX "arrival_directions_arrivalId_countryId_key" ON "arrival_directions"("arrivalId", "countryId");

-- CreateIndex
CREATE UNIQUE INDEX "arrival_views_arrivalId_companyId_key" ON "arrival_views"("arrivalId", "companyId");

-- CreateIndex
CREATE INDEX "arrivals_status_plannedAt_idx" ON "arrivals"("status", "plannedAt");

-- AddForeignKey
ALTER TABLE "arrival_directions" ADD CONSTRAINT "arrival_directions_arrivalId_fkey" FOREIGN KEY ("arrivalId") REFERENCES "arrivals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arrival_directions" ADD CONSTRAINT "arrival_directions_countryId_fkey" FOREIGN KEY ("countryId") REFERENCES "countries"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arrival_views" ADD CONSTRAINT "arrival_views_arrivalId_fkey" FOREIGN KEY ("arrivalId") REFERENCES "arrivals"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "arrival_views" ADD CONSTRAINT "arrival_views_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
