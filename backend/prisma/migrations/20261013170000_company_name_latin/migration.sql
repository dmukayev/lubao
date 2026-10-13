-- 069: латинское название китайской компании (nullable — старые компании не затрагиваются).
ALTER TABLE "companies" ADD COLUMN "nameLatin" TEXT;
