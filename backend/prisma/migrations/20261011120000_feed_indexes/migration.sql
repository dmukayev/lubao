-- 059: индексы ленты водителя.
CREATE INDEX IF NOT EXISTS "cargos_status_readyDate_idx" ON "cargos"("status", "readyDate");
CREATE INDEX IF NOT EXISTS "cargos_status_publishedAt_idx" ON "cargos"("status", "publishedAt");
