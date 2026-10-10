-- 058 п.4: валюты RUB и UZS (старые значения не меняются).
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'RUB';
ALTER TYPE "Currency" ADD VALUE IF NOT EXISTS 'UZS';

-- 058 п.1: условия оплаты груза (все необязательные — существующие грузы без них).
CREATE TYPE "PaymentForm" AS ENUM ('CASH', 'CARD', 'CASHLESS');
ALTER TABLE "cargos" ADD COLUMN "advanceAmount" DECIMAL(12,2),
  ADD COLUMN "paymentForm" "PaymentForm",
  ADD COLUMN "paymentDelayDays" INTEGER;

-- 058 п.8а: тип компании; существующие — экспедиторы (по умолчанию).
CREATE TYPE "CompanyKind" AS ENUM ('SHIPPER', 'FORWARDER', 'CARRIER');
ALTER TABLE "companies" ADD COLUMN "kind" "CompanyKind" NOT NULL DEFAULT 'FORWARDER';
