-- 057 п.3: отменённая сделка отпускает отклик — водителя можно выбрать снова
-- (раньше уникальный responseId старой отменённой сделки давал 409).
ALTER TABLE "deals" ALTER COLUMN "responseId" DROP NOT NULL;
UPDATE "deals" SET "responseId" = NULL WHERE "status" = 'CANCELLED';
