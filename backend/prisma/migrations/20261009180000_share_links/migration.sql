-- 052: «Поделиться» — короткие ссылки и кто по ним пришёл (новые таблица и необязательная колонка).
CREATE TYPE "ShareType" AS ENUM ('CARGO', 'COMPANY', 'DRIVER');
CREATE TABLE "share_links" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "type" "ShareType" NOT NULL,
    "targetId" TEXT NOT NULL,
    "authorUserId" TEXT NOT NULL,
    "opens" INTEGER NOT NULL DEFAULT 0,
    "logins" INTEGER NOT NULL DEFAULT 0,
    "responses" INTEGER NOT NULL DEFAULT 0,
    "deals" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "share_links_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "share_links_code_key" ON "share_links"("code");
CREATE UNIQUE INDEX "share_links_authorUserId_type_targetId_key" ON "share_links"("authorUserId", "type", "targetId");
CREATE INDEX "share_links_type_targetId_idx" ON "share_links"("type", "targetId");
ALTER TABLE "share_links" ADD CONSTRAINT "share_links_authorUserId_fkey" FOREIGN KEY ("authorUserId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "users" ADD COLUMN "referredByShareId" TEXT;
ALTER TABLE "users" ADD CONSTRAINT "users_referredByShareId_fkey" FOREIGN KEY ("referredByShareId") REFERENCES "share_links"("id") ON DELETE SET NULL ON UPDATE CASCADE;
