-- AlterTable
ALTER TABLE "cargos" ADD COLUMN     "palletCount" INTEGER;

-- AlterTable
ALTER TABLE "vehicles" ADD COLUMN     "innerHeightM" DECIMAL(4,2),
ADD COLUMN     "innerLengthM" DECIMAL(5,2),
ADD COLUMN     "innerWidthM" DECIMAL(4,2),
ADD COLUMN     "palletsEuro" INTEGER,
ADD COLUMN     "sizePresetId" TEXT,
ADD COLUMN     "volumeM3" DECIMAL(6,1);

-- CreateTable
CREATE TABLE "body_size_presets" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" JSONB NOT NULL,
    "bodyTypeIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "innerLengthM" DECIMAL(5,2),
    "innerWidthM" DECIMAL(4,2),
    "innerHeightM" DECIMAL(4,2),
    "volumeM3" DECIMAL(6,1),
    "palletsEuro" INTEGER,
    "palletsStandard" INTEGER,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "body_size_presets_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "body_size_presets_code_key" ON "body_size_presets"("code");

-- AddForeignKey
ALTER TABLE "vehicles" ADD CONSTRAINT "vehicles_sizePresetId_fkey" FOREIGN KEY ("sizePresetId") REFERENCES "body_size_presets"("id") ON DELETE SET NULL ON UPDATE CASCADE;

