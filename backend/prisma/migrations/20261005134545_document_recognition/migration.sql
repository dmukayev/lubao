-- CreateEnum
CREATE TYPE "DocumentRecognitionStatus" AS ENUM ('PENDING', 'DONE', 'FAILED', 'SKIPPED');

-- CreateTable
CREATE TABLE "document_recognitions" (
    "id" TEXT NOT NULL,
    "documentId" TEXT NOT NULL,
    "status" "DocumentRecognitionStatus" NOT NULL DEFAULT 'PENDING',
    "fields" JSONB,
    "engineVersion" TEXT,
    "durationMs" INTEGER,
    "errorMessage" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "document_recognitions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "document_recognitions_documentId_key" ON "document_recognitions"("documentId");

-- AddForeignKey
ALTER TABLE "document_recognitions" ADD CONSTRAINT "document_recognitions_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "verification_documents"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

