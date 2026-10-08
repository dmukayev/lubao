-- 047: категория груза, расстояние и ₸/км, статистика цен по маршрутам.
CREATE TABLE "cargo_categories" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" JSONB NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "cargo_categories_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "cargo_categories_code_key" ON "cargo_categories"("code");

-- Справочник сразу в миграции: существующим грузам нужна категория «другое».
INSERT INTO "cargo_categories" ("id", "code", "name", "sortOrder", "updatedAt") VALUES
  (gen_random_uuid()::text, 'CONSTRUCTION', '{"kk":"Құрылыс материалдары","ru":"Стройматериалы","zh":"建材","en":"Construction materials"}', 10, now()),
  (gen_random_uuid()::text, 'FOOD', '{"kk":"Азық-түлік","ru":"Продукты","zh":"食品","en":"Food"}', 20, now()),
  (gen_random_uuid()::text, 'EQUIPMENT', '{"kk":"Жабдық","ru":"Оборудование","zh":"设备","en":"Equipment"}', 30, now()),
  (gen_random_uuid()::text, 'CONSUMER_GOODS', '{"kk":"ХТТ / тоқыма","ru":"ТНП / текстиль","zh":"日用品/纺织品","en":"Consumer goods / textiles"}', 40, now()),
  (gen_random_uuid()::text, 'METAL', '{"kk":"Металл","ru":"Металл","zh":"金属","en":"Metal"}', 50, now()),
  (gen_random_uuid()::text, 'OVERSIZE', '{"kk":"Габаритсіз","ru":"Негабарит","zh":"超限货物","en":"Oversize"}', 60, now()),
  (gen_random_uuid()::text, 'DANGEROUS', '{"kk":"Қауіпті (ADR)","ru":"Опасный (ADR)","zh":"危险品 (ADR)","en":"Dangerous (ADR)"}', 70, now()),
  (gen_random_uuid()::text, 'OTHER', '{"kk":"Басқа","ru":"Другое","zh":"其他","en":"Other"}', 1000, now());

ALTER TABLE "cargos" ADD COLUMN "categoryId" TEXT;
UPDATE "cargos" SET "categoryId" = (SELECT "id" FROM "cargo_categories" WHERE "code" = 'OTHER');
ALTER TABLE "cargos" ALTER COLUMN "categoryId" SET NOT NULL;
ALTER TABLE "cargos" ADD CONSTRAINT "cargos_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "cargo_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "cargos" ADD COLUMN "distanceKm" INTEGER, ADD COLUMN "pricePerKm" DECIMAL(12,2);

CREATE TABLE "city_distances" (
    "fromCityId" TEXT NOT NULL,
    "toCityId" TEXT NOT NULL,
    "km" INTEGER NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'osrm',
    "computedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "city_distances_pkey" PRIMARY KEY ("fromCityId","toCityId")
);

CREATE TYPE "PricePointKind" AS ENUM ('LISTED', 'DEAL');
CREATE TABLE "price_points" (
    "id" TEXT NOT NULL,
    "kind" "PricePointKind" NOT NULL,
    "cargoId" TEXT NOT NULL,
    "dealId" TEXT,
    "driverId" TEXT,
    "companyId" TEXT NOT NULL,
    "fromCityId" TEXT NOT NULL,
    "toCityId" TEXT NOT NULL,
    "bucket" TEXT NOT NULL,
    "tonnageClass" INTEGER NOT NULL,
    "pricePerKmKzt" DECIMAL(12,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "price_points_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "price_points_fromCityId_toCityId_bucket_tonnageClass_create_idx" ON "price_points"("fromCityId", "toCityId", "bucket", "tonnageClass", "createdAt");

CREATE TABLE "route_price_stats" (
    "fromCityId" TEXT NOT NULL,
    "toCityId" TEXT NOT NULL,
    "bucket" TEXT NOT NULL,
    "tonnageClass" INTEGER NOT NULL,
    "median" DECIMAL(12,2) NOT NULL,
    "p25" DECIMAL(12,2) NOT NULL,
    "p75" DECIMAL(12,2) NOT NULL,
    "points" INTEGER NOT NULL,
    "dealPoints" INTEGER NOT NULL,
    "computedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "route_price_stats_pkey" PRIMARY KEY ("fromCityId","toCityId","bucket","tonnageClass")
);
