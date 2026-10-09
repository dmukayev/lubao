-- 056 п.5: «новые» отклики у каждого сотрудника свои — отметка «открывал отклики груза».
CREATE TABLE "cargo_responses_seen" (
    "userId" TEXT NOT NULL,
    "cargoId" TEXT NOT NULL,
    "seenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "cargo_responses_seen_pkey" PRIMARY KEY ("userId","cargoId")
);
CREATE INDEX "cargo_responses_seen_cargoId_idx" ON "cargo_responses_seen"("cargoId");
ALTER TABLE "cargo_responses_seen" ADD CONSTRAINT "cargo_responses_seen_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "cargo_responses_seen" ADD CONSTRAINT "cargo_responses_seen_cargoId_fkey" FOREIGN KEY ("cargoId") REFERENCES "cargos"("id") ON DELETE CASCADE ON UPDATE CASCADE;
-- Существующим откликам «новыми» не становиться: всё, что было до миграции, считаем просмотренным.
INSERT INTO "cargo_responses_seen" ("userId", "cargoId", "seenAt")
SELECT m."userId", c."id", CURRENT_TIMESTAMP
FROM "cargos" c JOIN "company_members" m ON m."companyId" = c."companyId"
ON CONFLICT DO NOTHING;
