-- Задача 042 п.0 (ревью 040): геозона терминала — 10 км (очередь фур стоит
-- дальше 3 км, решение 2026-10-07), и у Хоргоса на старых базах нет
-- координат без повторного сида — проставляем их здесь.

UPDATE "points" SET "radiusM" = 10000 WHERE "kind" = 'TERMINAL' AND ("radiusM" IS NULL OR "radiusM" = 3000);

UPDATE "cities" SET "lat" = 44.2167, "lng" = 80.4167
WHERE "code" = 'KZ-ZHETYSU-KHORGOS' AND ("lat" IS NULL OR "lng" IS NULL);

UPDATE "points" p SET "lat" = c."lat", "lng" = c."lng"
FROM "cities" c
WHERE p."cityId" = c."id" AND c."code" = 'KZ-ZHETYSU-KHORGOS' AND (p."lat" IS NULL OR p."lng" IS NULL);
