-- 054: фото профиля водителя (необязательные колонки — существующим строкам заполнять нечего).
ALTER TABLE "drivers" ADD COLUMN "avatarFileKey" TEXT;
ALTER TABLE "drivers" ADD COLUMN "avatarUpdatedAt" TIMESTAMP(3);
ALTER TABLE "drivers" ADD COLUMN "avatarOfferDismissedAt" TIMESTAMP(3);
