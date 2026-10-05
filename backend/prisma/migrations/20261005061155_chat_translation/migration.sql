-- CreateEnum
CREATE TYPE "TranslationStatus" AS ENUM ('SKIPPED', 'DONE', 'FAILED');

-- AlterTable
ALTER TABLE "messages" ADD COLUMN     "translationStatus" "TranslationStatus" NOT NULL DEFAULT 'SKIPPED';

-- CreateTable
CREATE TABLE "translation_logs" (
    "id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "model" TEXT,
    "success" BOOLEAN NOT NULL,
    "tokensUsed" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "translation_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "translation_logs_createdAt_idx" ON "translation_logs"("createdAt");
