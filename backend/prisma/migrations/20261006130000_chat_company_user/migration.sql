-- Задача 041, п.9: кто из логистов компании начал чат без груза (собеседник водителя).
ALTER TABLE "chats" ADD COLUMN "companyUserId" TEXT;
