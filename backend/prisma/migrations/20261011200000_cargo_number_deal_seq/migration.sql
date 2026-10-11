-- 062: короткий номер груза (6 цифр, не по порядку) и номер машины в сделке.

-- Свободный случайный номер 100000–999999. Совпадение при параллельной
-- вставке ловит уникальный индекс (приложение повторяет вставку).
CREATE OR REPLACE FUNCTION lubao_cargo_number() RETURNS integer AS $$
DECLARE
  candidate integer;
BEGIN
  LOOP
    candidate := 100000 + floor(random() * 900000)::integer;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM cargos WHERE "number" = candidate);
  END LOOP;
  RETURN candidate;
END;
$$ LANGUAGE plpgsql VOLATILE;

ALTER TABLE "cargos" ADD COLUMN "number" INTEGER;

-- Существующие грузы: разные случайные номера из перемешанного пула.
WITH pool AS (
  SELECT n, row_number() OVER (ORDER BY random()) AS rn FROM generate_series(100000, 999999) AS n
), c AS (
  SELECT id, row_number() OVER (ORDER BY "createdAt", id) AS rn FROM "cargos"
)
UPDATE "cargos" SET "number" = pool.n FROM c JOIN pool ON pool.rn = c.rn WHERE "cargos".id = c.id;

ALTER TABLE "cargos" ALTER COLUMN "number" SET NOT NULL;
ALTER TABLE "cargos" ALTER COLUMN "number" SET DEFAULT lubao_cargo_number();
CREATE UNIQUE INDEX "cargos_number_key" ON "cargos"("number");

-- Номер машины по грузу: 1, 2, … (отменённая сделка номер не освобождает).
ALTER TABLE "deals" ADD COLUMN "seq" INTEGER;
WITH d AS (
  SELECT id, row_number() OVER (PARTITION BY "cargoId" ORDER BY "createdAt", id) AS rn FROM "deals"
)
UPDATE "deals" SET "seq" = d.rn FROM d WHERE "deals".id = d.id;
ALTER TABLE "deals" ALTER COLUMN "seq" SET NOT NULL;
ALTER TABLE "deals" ALTER COLUMN "seq" SET DEFAULT 0;
CREATE UNIQUE INDEX "deals_cargoId_seq_key" ON "deals"("cargoId", "seq");

-- Новая сделка получает следующий номер по грузу. Сделки создаются под
-- замком груза (responses.service claimPlace) — гонки нет; уникальный индекс
-- — страховка.
CREATE OR REPLACE FUNCTION lubao_deal_seq() RETURNS trigger AS $$
BEGIN
  IF NEW."seq" IS NULL OR NEW."seq" = 0 THEN
    SELECT COALESCE(MAX("seq"), 0) + 1 INTO NEW."seq" FROM "deals" WHERE "cargoId" = NEW."cargoId";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER deals_seq_before_insert BEFORE INSERT ON "deals" FOR EACH ROW EXECUTE FUNCTION lubao_deal_seq();
