-- 043 п.1: удаление аккаунта (обезличивание). Nullable — существующие строки не трогаем.
ALTER TABLE "users" ADD COLUMN "deletedAt" TIMESTAMP(3);
