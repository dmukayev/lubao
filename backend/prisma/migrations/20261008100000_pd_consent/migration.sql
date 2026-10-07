-- 043 п.2: согласие на обработку ПДн. Nullable — у существующих пользователей
-- согласие спросят при следующей загрузке документа.
ALTER TABLE "users" ADD COLUMN "pdConsentAt" TIMESTAMP(3), ADD COLUMN "pdConsentVersion" TEXT;
