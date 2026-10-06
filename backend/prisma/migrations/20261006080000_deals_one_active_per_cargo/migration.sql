-- Задача 038, п.22 — не более одной активной сделки на груз.
-- Сначала разбираем дубли, созданные ДО фикса (демо-данные и возможные
-- боевые): оставляем самую продвинутую по статусу (при равенстве — самую
-- свежую), остальные отменяем с понятной причиной.
WITH ranked AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY "cargoId"
           ORDER BY CASE status
                      WHEN 'DELIVERED' THEN 5
                      WHEN 'IN_TRANSIT' THEN 4
                      WHEN 'LOADED' THEN 3
                      WHEN 'CONFIRMED_BY_DRIVER' THEN 2
                      ELSE 1
                    END DESC,
                    "createdAt" DESC
         ) AS rn
  FROM deals
  WHERE status <> 'CANCELLED'
)
UPDATE deals
SET status = 'CANCELLED',
    "cancelReason" = 'Дубль сделки на груз (закрыт миграцией 038)',
    "cancelledByRole" = 'ADMIN',
    "updatedAt" = NOW()
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Частичный уникальный индекс: вторую активную сделку на груз не создать
-- даже в обход приложения.
CREATE UNIQUE INDEX "deals_one_active_per_cargo" ON "deals" ("cargoId") WHERE status <> 'CANCELLED';
