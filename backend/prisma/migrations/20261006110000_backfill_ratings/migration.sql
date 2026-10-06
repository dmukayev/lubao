-- Задача 041, п.4: рейтинг пересчитывается при каждом отзыве; здесь —
-- бэкфилл по уже существующим отзывам. Водителя оценивает компания
-- (authorRole COMPANY), компанию — водитель (authorRole DRIVER).
UPDATE drivers d
SET "ratingAvg" = sub.avg, "ratingCount" = sub.cnt
FROM (
  SELECT dl."driverId" AS id, ROUND(AVG(r.rating)::numeric, 2) AS avg, COUNT(*)::int AS cnt
  FROM reviews r JOIN deals dl ON dl.id = r."dealId"
  WHERE r."authorRole" = 'COMPANY'
  GROUP BY dl."driverId"
) sub
WHERE d.id = sub.id;

UPDATE companies c
SET "ratingAvg" = sub.avg, "ratingCount" = sub.cnt
FROM (
  SELECT dl."companyId" AS id, ROUND(AVG(r.rating)::numeric, 2) AS avg, COUNT(*)::int AS cnt
  FROM reviews r JOIN deals dl ON dl.id = r."dealId"
  WHERE r."authorRole" = 'DRIVER'
  GROUP BY dl."companyId"
) sub
WHERE c.id = sub.id;
