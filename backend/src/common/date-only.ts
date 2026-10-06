/// Календарные даты без часового пояса (задача 041, п.5): день «вторник»,
/// выбранный в Урумчи и в Алматы, — один и тот же вторник. На проводе — строка
/// `YYYY-MM-DD`, в БД — `DATE`, на сервере — Date в UTC-полночь; никакой
/// арифметики с местным временем.

/// «2026-10-07» (или полный ISO — берём календарную часть) → Date в UTC-полночь.
export function parseDateOnly(value: string): Date {
  return new Date(`${value.slice(0, 10)}T00:00:00.000Z`);
}

/// Date (UTC-полночь из колонки DATE) → «YYYY-MM-DD».
export function toDateOnly(date: Date): string {
  return date.toISOString().slice(0, 10);
}

export function addDaysDateOnly(value: string, days: number): string {
  const d = parseDateOnly(value);
  d.setUTCDate(d.getUTCDate() + days);
  return toDateOnly(d);
}

/// «Сегодня» как календарная дата в часовом поясе приложения (по умолчанию
/// Казахстан, UTC+5) — для правил свежести анонса, которые срабатывают без
/// клиента.
export function localDateOnly(now: Date, timeZone = process.env.APP_TIMEZONE || 'Asia/Almaty'): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
}

/// Час (0–23) в часовом поясе приложения.
export function localHour(now: Date, timeZone = process.env.APP_TIMEZONE || 'Asia/Almaty'): number {
  return Number(new Intl.DateTimeFormat('en-GB', { timeZone, hour: '2-digit', hour12: false }).format(now)) % 24;
}
