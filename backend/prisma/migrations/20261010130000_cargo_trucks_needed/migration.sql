-- 058 п.2: груз на несколько машин; существующие грузы — на одну (по умолчанию).
ALTER TABLE "cargos" ADD COLUMN "trucksNeeded" INTEGER NOT NULL DEFAULT 1;
