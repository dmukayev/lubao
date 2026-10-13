-- 075: «Что везёте?» — коды HS-6, главы → категории, популярные товары; у груза — товар, свой текст, код.
-- Новые колонки груза nullable: старые грузы остаются только с категорией.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE "hs_codes" (
    "code" TEXT NOT NULL,
    "chapter" TEXT NOT NULL,
    "heading" TEXT NOT NULL,
    "name" JSONB NOT NULL,
    "searchText" TEXT NOT NULL DEFAULT '',
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "hs_codes_pkey" PRIMARY KEY ("code")
);
CREATE INDEX "hs_codes_chapter_idx" ON "hs_codes"("chapter");
CREATE INDEX "hs_codes_search_trgm" ON "hs_codes" USING GIN ("searchText" gin_trgm_ops);

CREATE TABLE "hs_chapters" (
    "chapter" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    CONSTRAINT "hs_chapters_pkey" PRIMARY KEY ("chapter")
);
ALTER TABLE "hs_chapters" ADD CONSTRAINT "hs_chapters_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "cargo_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "goods" (
    "id" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "name" JSONB NOT NULL,
    "synonyms" JSONB NOT NULL DEFAULT '{}',
    "hsCode" TEXT,
    "categoryId" TEXT NOT NULL,
    "suggestedBodyTypeId" TEXT,
    "isDangerous" BOOLEAN NOT NULL DEFAULT false,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "searchText" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "goods_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "goods_slug_key" ON "goods"("slug");
CREATE INDEX "goods_search_trgm" ON "goods" USING GIN ("searchText" gin_trgm_ops);
ALTER TABLE "goods" ADD CONSTRAINT "goods_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "cargo_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "cargos" ADD COLUMN "goodsId" TEXT;
ALTER TABLE "cargos" ADD COLUMN "goodsText" TEXT;
ALTER TABLE "cargos" ADD COLUMN "goodsTextLocale" "Locale";
ALTER TABLE "cargos" ADD COLUMN "goodsTextTranslations" JSONB;
ALTER TABLE "cargos" ADD COLUMN "hsCode" TEXT;
ALTER TABLE "cargos" ADD CONSTRAINT "cargos_goodsId_fkey" FOREIGN KEY ("goodsId") REFERENCES "goods"("id") ON DELETE SET NULL ON UPDATE CASCADE;
