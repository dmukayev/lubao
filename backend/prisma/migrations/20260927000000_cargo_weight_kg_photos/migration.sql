-- AlterTable
ALTER TABLE "cargos" DROP COLUMN "weightTons",
ADD COLUMN     "photoUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "weightKg" DECIMAL(10,2);

