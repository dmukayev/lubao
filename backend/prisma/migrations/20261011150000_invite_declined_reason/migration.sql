-- 057 п.22: отказ от приглашения — своя причина закрытия отклика.
-- Старые отказы (WITHDRAWN) не трогаем: из данных не отличить от отзыва.
ALTER TYPE "ResponseCloseReason" ADD VALUE IF NOT EXISTS 'INVITE_DECLINED';
