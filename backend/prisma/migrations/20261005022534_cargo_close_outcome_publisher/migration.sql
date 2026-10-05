-- CreateEnum
CREATE TYPE "CargoCloseOutcome" AS ENUM ('FOUND_IN_APP', 'FOUND_OUTSIDE', 'CARGO_CANCELLED');

-- AlterTable
ALTER TABLE "cargos" ADD COLUMN     "closeOutcome" "CargoCloseOutcome",
ADD COLUMN     "closedAt" TIMESTAMP(3),
ADD COLUMN     "publishedByUserId" TEXT;

-- AddForeignKey
ALTER TABLE "cargos" ADD CONSTRAINT "cargos_publishedByUserId_fkey" FOREIGN KEY ("publishedByUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
