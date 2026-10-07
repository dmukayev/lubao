-- 043 п.2: оферта для компании. Nullable — у компаний до 043 значения нет.
ALTER TABLE "companies" ADD COLUMN "offerAcceptedAt" TIMESTAMP(3), ADD COLUMN "offerVersion" TEXT;
