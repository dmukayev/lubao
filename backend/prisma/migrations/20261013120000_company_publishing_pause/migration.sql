-- 066 п.5: пауза публикации после двух жалоб водителей (nullable — старые строки не затрагиваются).
ALTER TABLE "companies" ADD COLUMN "publishingPausedAt" TIMESTAMP(3);
ALTER TABLE "companies" ADD COLUMN "complaintsResetAt" TIMESTAMP(3);
