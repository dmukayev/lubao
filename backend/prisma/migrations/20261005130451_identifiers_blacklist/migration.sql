-- Задача 031, этап C — таблицы новые (без переноса существующих данных);
-- бэкфилл не нужен, но на базе с демо-данными тоже проверено ниже.

-- CreateEnum
CREATE TYPE "IdentifierType" AS ENUM ('IIN', 'DRIVER_LICENSE_NO', 'VIN', 'PLATE', 'BIN', 'USCC', 'PHONE');

-- CreateEnum
CREATE TYPE "IdentifierOwnerType" AS ENUM ('DRIVER', 'COMPANY', 'VEHICLE');

-- CreateTable
CREATE TABLE "identifiers" (
    "id" TEXT NOT NULL,
    "type" "IdentifierType" NOT NULL,
    "valueHash" TEXT NOT NULL,
    "valueMasked" TEXT NOT NULL,
    "valueEncrypted" TEXT,
    "ownerType" "IdentifierOwnerType" NOT NULL,
    "ownerId" TEXT NOT NULL,
    "sourceDocumentId" TEXT,
    "confirmedByUserId" TEXT,
    "confirmedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "identifiers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "blocked_identifiers" (
    "id" TEXT NOT NULL,
    "type" "IdentifierType" NOT NULL,
    "valueHash" TEXT NOT NULL,
    "valueMasked" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "blockedByUserId" TEXT NOT NULL,
    "sourceOwnerType" "IdentifierOwnerType",
    "sourceOwnerId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "liftedAt" TIMESTAMP(3),
    "liftedByUserId" TEXT,
    "liftReason" TEXT,

    CONSTRAINT "blocked_identifiers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "identifiers_type_valueHash_idx" ON "identifiers"("type", "valueHash");

-- CreateIndex
CREATE UNIQUE INDEX "identifiers_ownerType_ownerId_type_key" ON "identifiers"("ownerType", "ownerId", "type");

-- CreateIndex
CREATE INDEX "blocked_identifiers_type_valueHash_idx" ON "blocked_identifiers"("type", "valueHash");

-- CreateIndex
CREATE INDEX "blocked_identifiers_sourceOwnerType_sourceOwnerId_idx" ON "blocked_identifiers"("sourceOwnerType", "sourceOwnerId");

-- AddForeignKey
ALTER TABLE "identifiers" ADD CONSTRAINT "identifiers_sourceDocumentId_fkey" FOREIGN KEY ("sourceDocumentId") REFERENCES "verification_documents"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "identifiers" ADD CONSTRAINT "identifiers_confirmedByUserId_fkey" FOREIGN KEY ("confirmedByUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "blocked_identifiers" ADD CONSTRAINT "blocked_identifiers_blockedByUserId_fkey" FOREIGN KEY ("blockedByUserId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "blocked_identifiers" ADD CONSTRAINT "blocked_identifiers_liftedByUserId_fkey" FOREIGN KEY ("liftedByUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

