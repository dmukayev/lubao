-- 049 п.9: штраф за отмены копится, пока у стороны нет отзывов.
ALTER TABLE "drivers" ADD COLUMN "pendingPenalty" DECIMAL(6,2) NOT NULL DEFAULT 0;
ALTER TABLE "companies" ADD COLUMN "pendingPenalty" DECIMAL(6,2) NOT NULL DEFAULT 0;
-- Уже начисленное среднее без отзывов (было 1.00 при ratingCount = 0) — обнулить.
UPDATE "drivers" SET "ratingAvg" = 0 WHERE "ratingCount" = 0;
UPDATE "companies" SET "ratingAvg" = 0 WHERE "ratingCount" = 0;
