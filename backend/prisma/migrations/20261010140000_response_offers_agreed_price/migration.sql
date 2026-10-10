-- 058 п.5: своя цена водителя и один встречный ход логиста.
CREATE TYPE "CounterStatus" AS ENUM ('PENDING', 'ACCEPTED', 'DECLINED');
ALTER TABLE "responses" ADD COLUMN "proposedPrice" DECIMAL(12,2),
  ADD COLUMN "proposedComment" TEXT,
  ADD COLUMN "counterPrice" DECIMAL(12,2),
  ADD COLUMN "counterStatus" "CounterStatus";

-- Итоговая цена сделки; у существующих — цена груза (договорённость была по ней).
ALTER TABLE "deals" ADD COLUMN "agreedPrice" DECIMAL(12,2);
UPDATE "deals" d SET "agreedPrice" = c."price" FROM "cargos" c WHERE c."id" = d."cargoId";
