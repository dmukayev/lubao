-- CreateEnum
CREATE TYPE "MessageKind" AS ENUM ('USER', 'SYSTEM');

-- AlterTable
ALTER TABLE "messages" ADD COLUMN     "kind" "MessageKind" NOT NULL DEFAULT 'USER',
ADD COLUMN     "systemCode" TEXT,
ADD COLUMN     "systemParams" JSONB;

