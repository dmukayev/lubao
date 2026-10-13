-- 068: паллеты скрыты по умолчанию у всех типов кузова; колонки паллет у машин и грузов не трогаем.
ALTER TABLE "body_types" ADD COLUMN "showPallets" BOOLEAN NOT NULL DEFAULT false;
