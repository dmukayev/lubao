-- 056 п.1: причина закрытия отклика.
CREATE TYPE "ResponseCloseReason" AS ENUM ('WITHDRAWN', 'INVITE_EXPIRED', 'CARGO_ARCHIVED', 'CARGO_CLOSED', 'TAKEN_BY_OTHER', 'REJECTED_BY_LOGIST', 'DEAL_CANCELLED', 'ACCOUNT_DELETED');
ALTER TABLE "responses" ADD COLUMN "closeReason" "ResponseCloseReason";

-- Зависшие отклики (водитель видел неправду): сделка отменена, а отклик
-- остался SELECTED → закрыт с причиной «сделка отменена».
UPDATE "responses" r SET "status" = 'CANCELLED', "closeReason" = 'DEAL_CANCELLED'
FROM "deals" d
WHERE d."responseId" = r."id" AND d."status" = 'CANCELLED' AND r."status" = 'SELECTED';

-- Груз снят / в архиве, а отклик всё ещё «Ожидает» → закрыт.
UPDATE "responses" r SET "status" = 'CANCELLED', "closeReason" = 'CARGO_CLOSED'
FROM "cargos" c
WHERE c."id" = r."cargoId" AND c."status" = 'CANCELLED' AND r."status" IN ('PENDING', 'INVITED');
UPDATE "responses" r SET "status" = 'CANCELLED', "closeReason" = 'CARGO_ARCHIVED'
FROM "cargos" c
WHERE c."id" = r."cargoId" AND c."status" IN ('ARCHIVED', 'EXPIRED') AND r."status" IN ('PENDING', 'INVITED');

-- Причина у уже закрытых — где её можно понять; иначе null.
UPDATE "responses" r SET "closeReason" = 'ACCOUNT_DELETED'
FROM "drivers" dr JOIN "users" u ON u."id" = dr."userId"
WHERE dr."id" = r."driverId" AND u."deletedAt" IS NOT NULL AND r."status" = 'CANCELLED' AND r."closeReason" IS NULL;
UPDATE "responses" r SET "closeReason" = 'DEAL_CANCELLED'
FROM "deals" d
WHERE d."responseId" = r."id" AND d."status" = 'CANCELLED' AND r."status" = 'CANCELLED' AND r."closeReason" IS NULL;
UPDATE "responses" r SET "closeReason" = 'CARGO_ARCHIVED'
FROM "cargos" c
WHERE c."id" = r."cargoId" AND c."status" IN ('ARCHIVED', 'EXPIRED') AND r."status" = 'CANCELLED' AND r."closeReason" IS NULL;
UPDATE "responses" r SET "closeReason" = 'CARGO_CLOSED'
FROM "cargos" c
WHERE c."id" = r."cargoId" AND c."status" = 'CANCELLED' AND r."status" = 'CANCELLED' AND r."closeReason" IS NULL;
-- REJECTED: у груза есть сделка с другим откликом → ушёл другому; иначе отказал логист.
UPDATE "responses" r SET "closeReason" = CASE
    WHEN EXISTS (SELECT 1 FROM "deals" d WHERE d."cargoId" = r."cargoId" AND d."responseId" <> r."id") THEN 'TAKEN_BY_OTHER'::"ResponseCloseReason"
    ELSE 'REJECTED_BY_LOGIST'::"ResponseCloseReason"
  END
WHERE r."status" = 'REJECTED' AND r."closeReason" IS NULL;
