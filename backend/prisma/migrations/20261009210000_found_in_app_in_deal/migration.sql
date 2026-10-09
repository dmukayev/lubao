-- 057 п.16: «Нашёл в Lubao» клало груз с идущей сделкой в «Архив» (CANCELLED).
-- Идущая сделка → груз «В работе» (IN_DEAL); доставленная → ARCHIVED, как при обычной доставке.
UPDATE "cargos" c SET "status" = 'IN_DEAL'
WHERE c."status" = 'CANCELLED' AND c."closeOutcome" = 'FOUND_IN_APP'
  AND EXISTS (SELECT 1 FROM "deals" d WHERE d."cargoId" = c."id" AND d."status" NOT IN ('CANCELLED', 'DELIVERED'));
UPDATE "cargos" c SET "status" = 'ARCHIVED', "archivedAt" = COALESCE(c."archivedAt", c."closedAt")
WHERE c."status" = 'CANCELLED' AND c."closeOutcome" = 'FOUND_IN_APP'
  AND EXISTS (SELECT 1 FROM "deals" d WHERE d."cargoId" = c."id" AND d."status" = 'DELIVERED');
