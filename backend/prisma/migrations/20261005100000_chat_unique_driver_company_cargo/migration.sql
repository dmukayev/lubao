-- Задача 029, п.13: уникальный индекс против двойного нажатия «Написать»
-- (гонка двух параллельных findOrCreate создавала два чата на одну и ту
-- же пару водитель+компания(+груз)). NULLS NOT DISTINCT (Postgres 15+) —
-- иначе Postgres по умолчанию считает NULL != NULL, и чат БЕЗ груза
-- (cargoId = NULL, общий чат логиста с водителем) остался бы без защиты.
--
-- Задача 029, п.1 (ревью): на базе с демо-данными/проде дубли (driverId,
-- companyId, cargoId) могли УЖЕ существовать (та самая гонка, против которой
-- этот индекс и ставится) — CREATE UNIQUE INDEX упал бы на них с ошибкой
-- уникальности. Правило CLAUDE.md про миграции: сначала объединить дубли, а
-- не предполагать чистую базу. Для каждой группы дублей — самый старый чат
-- (по createdAt) остаётся, его сообщения получают дубли-чаты, его dealId
-- заполняется, если был пуст, сами дубли-чаты удаляются.
DO $$
DECLARE
  dup RECORD;
  oldest_id TEXT;
BEGIN
  FOR dup IN
    SELECT "driverId", "companyId", "cargoId"
    FROM "chats"
    GROUP BY "driverId", "companyId", "cargoId"
    HAVING COUNT(*) > 1
  LOOP
    SELECT id INTO oldest_id FROM "chats"
      WHERE "driverId" = dup."driverId"
        AND "companyId" = dup."companyId"
        AND ("cargoId" = dup."cargoId" OR ("cargoId" IS NULL AND dup."cargoId" IS NULL))
      ORDER BY "createdAt" ASC, id ASC
      LIMIT 1;

    UPDATE "messages" SET "chatId" = oldest_id
      WHERE "chatId" IN (
        SELECT id FROM "chats"
          WHERE "driverId" = dup."driverId"
            AND "companyId" = dup."companyId"
            AND ("cargoId" = dup."cargoId" OR ("cargoId" IS NULL AND dup."cargoId" IS NULL))
            AND id <> oldest_id
      );

    UPDATE "chats" SET "dealId" = (
        SELECT "dealId" FROM "chats"
          WHERE "driverId" = dup."driverId"
            AND "companyId" = dup."companyId"
            AND ("cargoId" = dup."cargoId" OR ("cargoId" IS NULL AND dup."cargoId" IS NULL))
            AND "dealId" IS NOT NULL
          ORDER BY "createdAt" ASC
          LIMIT 1
      )
      WHERE id = oldest_id AND "dealId" IS NULL;

    DELETE FROM "chats"
      WHERE "driverId" = dup."driverId"
        AND "companyId" = dup."companyId"
        AND ("cargoId" = dup."cargoId" OR ("cargoId" IS NULL AND dup."cargoId" IS NULL))
        AND id <> oldest_id;
  END LOOP;
END $$;

CREATE UNIQUE INDEX "chats_driverId_companyId_cargoId_key"
  ON "chats" ("driverId", "companyId", "cargoId")
  NULLS NOT DISTINCT;
