-- 058 п.2: груз на несколько машин — у груза может быть несколько активных
-- сделок (место проверяется под замком груза). Защита от дубля остаётся:
-- одна активная сделка на пару груз + водитель.
DROP INDEX IF EXISTS "deals_one_active_per_cargo";
CREATE UNIQUE INDEX "deals_one_active_per_cargo_driver" ON "deals" ("cargoId", "driverId") WHERE status <> 'CANCELLED';
