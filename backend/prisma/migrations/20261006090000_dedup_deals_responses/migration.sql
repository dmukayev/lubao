-- Задача 039, п.4 — отклики отменённых дублей (миграция 20261006080000
-- отменила сами сделки): отклик, остававшийся SELECTED без активной сделки,
-- закрываем, иначе у водителя «выбран», а сделки нет.
UPDATE responses r
SET status = 'REJECTED', "updatedAt" = NOW()
WHERE r.status = 'SELECTED'
  AND EXISTS (
    SELECT 1 FROM deals d
    WHERE d."responseId" = r.id
      AND d.status = 'CANCELLED'
      AND d."cancelReason" LIKE 'Дубль сделки на груз%'
  );
