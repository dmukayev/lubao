-- 058 п.6: «Мои водители» компании и «Создать водителя».
CREATE TYPE "CompanyDriverSource" AS ENUM ('SAVED', 'CREATED');
CREATE TYPE "CompanyDriverStatus" AS ENUM ('ACTIVE', 'PENDING', 'DECLINED', 'LEFT');

CREATE TABLE "company_drivers" (
    "id" TEXT NOT NULL,
    "companyId" TEXT NOT NULL,
    "driverId" TEXT,
    "phone" TEXT,
    "name" TEXT,
    "source" "CompanyDriverSource" NOT NULL,
    "status" "CompanyDriverStatus" NOT NULL,
    "createdByUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondedAt" TIMESTAMP(3),
    CONSTRAINT "company_drivers_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "company_drivers_companyId_driverId_key" ON "company_drivers"("companyId", "driverId");
CREATE UNIQUE INDEX "company_drivers_companyId_phone_key" ON "company_drivers"("companyId", "phone");
CREATE INDEX "company_drivers_phone_idx" ON "company_drivers"("phone");
ALTER TABLE "company_drivers" ADD CONSTRAINT "company_drivers_companyId_fkey" FOREIGN KEY ("companyId") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "company_drivers" ADD CONSTRAINT "company_drivers_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
