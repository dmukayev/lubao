-- Задача 029, п.13: уникальный индекс против двойного нажатия «Написать»
-- (гонка двух параллельных findOrCreate создавала два чата на одну и ту
-- же пару водитель+компания(+груз)). NULLS NOT DISTINCT (Postgres 15+) —
-- иначе Postgres по умолчанию считает NULL != NULL, и чат БЕЗ груза
-- (cargoId = NULL, общий чат логиста с водителем) остался бы без защиты.
CREATE UNIQUE INDEX "chats_driverId_companyId_cargoId_key"
  ON "chats" ("driverId", "companyId", "cargoId")
  NULLS NOT DISTINCT;
