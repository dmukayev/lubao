-- 046: отмена сделки — категории, сторона вины, запрос отмены и спор после «В пути».
ALTER TYPE "DealStatus" ADD VALUE IF NOT EXISTS 'CANCEL_REQUESTED';
ALTER TYPE "DealStatus" ADD VALUE IF NOT EXISTS 'DISPUTED';
CREATE TYPE "CancelStage" AS ENUM ('BEFORE_CONFIRM', 'AFTER_CONFIRM', 'AFTER_LOAD', 'IN_TRANSIT');
CREATE TYPE "FaultSide" AS ENUM ('SELF', 'OTHER_PARTY', 'NEUTRAL');
ALTER TABLE "deals"
  ADD COLUMN "cancelStage" "CancelStage",
  ADD COLUMN "faultSide" "FaultSide",
  ADD COLUMN "cancelRequestedAt" TIMESTAMP(3),
  ADD COLUMN "cancelRequestedByRole" "ReviewAuthorRole",
  ADD COLUMN "cancelRequestReasonCode" TEXT,
  ADD COLUMN "cancelRequestReason" TEXT,
  ADD COLUMN "disputeReason" TEXT,
  ADD COLUMN "disputedAt" TIMESTAMP(3);

-- Старые отмены: текстовая причина без кода → «Другое» с текстом; «взял другой груз» — как было.
UPDATE "deals" SET "cancelReasonCode" = 'OTHER' WHERE "status" = 'CANCELLED' AND "cancelReasonCode" IS NULL;
-- Этап старых отмен неизвестен (статус до отмены не хранился) — без веса в рейтинге.
UPDATE "deals" SET "faultSide" = CASE WHEN "cancelReasonCode" = 'TOOK_OTHER_CARGO' THEN 'SELF'::"FaultSide" ELSE 'NEUTRAL'::"FaultSide" END WHERE "status" = 'CANCELLED';
