-- Задача 041, п.5: дата без сдвига. readyDate груза и день анонса — календарные
-- даты (DATE), а не моменты времени: выбор «вт» в Урумчи (UTC+8) и в Алматы
-- (UTC+5) — один и тот же вторник.

-- readyDate: старые значения — моменты, записанные клиентом (локальная
-- полночь/время). +12 часов и обрезка до даты возвращает задуманный день
-- для поясов UTC+3…UTC+9 (демо-данные и пилот).
ALTER TABLE "cargos" ALTER COLUMN "readyDate" TYPE DATE USING (("readyDate" + interval '12 hours')::date);

-- plannedDay анонса: из plannedAt по времени Алматы (пилот — Казахстан).
ALTER TABLE "arrivals" ADD COLUMN "plannedDay" DATE;
UPDATE "arrivals" SET "plannedDay" = (("plannedAt" AT TIME ZONE 'UTC') AT TIME ZONE 'Asia/Almaty')::date;
ALTER TABLE "arrivals" ALTER COLUMN "plannedDay" SET NOT NULL;
