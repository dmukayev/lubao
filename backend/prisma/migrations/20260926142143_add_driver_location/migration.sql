-- AlterTable
ALTER TABLE "drivers" ADD COLUMN     "currentLat" DECIMAL(9,6),
ADD COLUMN     "currentLng" DECIMAL(9,6),
ADD COLUMN     "locationUpdatedAt" TIMESTAMP(3);
