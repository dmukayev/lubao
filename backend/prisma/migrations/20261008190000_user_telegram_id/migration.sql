-- 050: вход через бот Telegram — привязка аккаунта Telegram к водителю.
ALTER TABLE "users" ADD COLUMN "telegramUserId" TEXT;
CREATE UNIQUE INDEX "users_telegramUserId_key" ON "users"("telegramUserId");
