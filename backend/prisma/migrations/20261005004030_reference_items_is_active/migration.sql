-- AlterTable
ALTER TABLE "body_types" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "permits" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;
