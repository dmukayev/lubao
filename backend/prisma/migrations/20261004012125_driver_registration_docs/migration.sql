-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "VerificationDocType" ADD VALUE 'TRAILER_PASSPORT';
ALTER TYPE "VerificationDocType" ADD VALUE 'SELFIE';

-- AlterTable
ALTER TABLE "vehicles" ALTER COLUMN "plateNumber" DROP NOT NULL;

