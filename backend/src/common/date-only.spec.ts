import { addDaysDateOnly, parseDateOnly, toDateOnly } from './date-only';

describe('date-only (задача 041, п.5)', () => {
  it('parseDateOnly даёт UTC-полночь календарного дня, toDateOnly возвращает ту же строку', () => {
    const d = parseDateOnly('2026-10-06');
    expect(d.toISOString()).toBe('2026-10-06T00:00:00.000Z');
    expect(toDateOnly(d)).toBe('2026-10-06');
  });

  it('полный ISO — берётся календарная часть (старые клиенты)', () => {
    expect(toDateOnly(parseDateOnly('2026-10-06T21:30:00.000Z'))).toBe('2026-10-06');
  });

  it('addDaysDateOnly — без часовых поясов, через границу месяца и года', () => {
    expect(addDaysDateOnly('2026-10-31', 1)).toBe('2026-11-01');
    expect(addDaysDateOnly('2026-12-31', 1)).toBe('2027-01-01');
  });
});
