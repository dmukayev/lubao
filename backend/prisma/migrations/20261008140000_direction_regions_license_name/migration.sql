-- 045 п.7: области внутри страны направления (пусто — вся страна; у существующих — вся страна).
ALTER TABLE "driver_directions" ADD COLUMN "regionIds" TEXT[] DEFAULT ARRAY[]::TEXT[];
-- 045 п.10: ФИО из прав — предложить подставить в профиль.
ALTER TABLE "drivers" ADD COLUMN "licenseFullName" TEXT;
