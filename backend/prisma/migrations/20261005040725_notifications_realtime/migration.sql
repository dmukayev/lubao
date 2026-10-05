-- CreateEnum
CREATE TYPE "NotificationEventGroup" AS ENUM ('NEW_CARGO_MATCH', 'CARGO_INVITE', 'CHAT_MESSAGE', 'NEW_RESPONSE', 'NEW_DRIVER_DIGEST', 'DEAL_STATUS', 'VERIFICATION', 'AGREED_CHECK');

-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('FCM', 'APNS', 'JPUSH');

-- AlterTable
ALTER TABLE "companies" ADD COLUMN     "wecomWebhookUrl" TEXT;

-- CreateTable
CREATE TABLE "notification_event_settings" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "eventGroup" "NotificationEventGroup" NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "notification_event_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "device_tokens" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "notification_event_settings_userId_eventGroup_key" ON "notification_event_settings"("userId", "eventGroup");

-- CreateIndex
CREATE UNIQUE INDEX "device_tokens_token_key" ON "device_tokens"("token");

-- CreateIndex
CREATE INDEX "device_tokens_userId_idx" ON "device_tokens"("userId");

-- AddForeignKey
ALTER TABLE "notification_event_settings" ADD CONSTRAINT "notification_event_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
