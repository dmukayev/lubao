-- Задача 041: груз «в сделке» и отклик «приглашён» — только новые значения enum,
-- старые данные не меняются (миграция безопасна на базе с демо-данными).
ALTER TYPE "CargoStatus" ADD VALUE IF NOT EXISTS 'IN_DEAL';
ALTER TYPE "ResponseStatus" ADD VALUE IF NOT EXISTS 'INVITED';
