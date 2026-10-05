-- CreateEnum
CREATE TYPE "ComplaintResolution" AS ENUM ('DISMISSED', 'WARNED', 'CARGO_UNPUBLISHED', 'BLOCKED');

-- AlterTable
ALTER TABLE "complaints" ADD COLUMN     "assignedToUserId" TEXT,
ADD COLUMN     "resolution" "ComplaintResolution",
ADD COLUMN     "resolutionNote" TEXT,
ADD COLUMN     "takenAt" TIMESTAMP(3);

-- AddForeignKey
ALTER TABLE "complaints" ADD CONSTRAINT "complaints_assignedToUserId_fkey" FOREIGN KEY ("assignedToUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
