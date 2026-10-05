import { maskNumerics, unmaskNumerics } from './masking';

describe('maskNumerics/unmaskNumerics (задача 010, п.3а)', () => {
  it('masks phone, license plate, amount-with-currency, and time in one message, round-trips perfectly', () => {
    const text = 'Позвони +7 701 234 56 78, госномер 777 ABP 05, оплата 2 600$, буду в 18:30';
    const { masked, values } = maskNumerics(text);

    expect(masked).toBe('Позвони ⟦1⟧, госномер ⟦2⟧, оплата ⟦3⟧, буду в ⟦4⟧');
    expect(values).toEqual(['+7 701 234 56 78', '777 ABP 05', '2 600$', '18:30']);
    expect(unmaskNumerics(masked, values)).toBe(text);
  });

  it('masks a date (D.M.YYYY)', () => {
    const { masked, values } = maskNumerics('Буду 05.10.2026 в порту');
    expect(masked).toBe('Буду ⟦1⟧ в порту');
    expect(values).toEqual(['05.10.2026']);
  });

  it('masks a currency-code amount (1500 KZT)', () => {
    const { masked, values } = maskNumerics('Оплата 1500 KZT наличными');
    expect(masked).toBe('Оплата ⟦1⟧ наличными');
    expect(values).toEqual(['1500 KZT']);
  });

  it('does not touch emails, links, or short plain numbers', () => {
    const text = 'Email test@example.com, перегруз 2 тонны, тариф 300';
    const { masked, values } = maskNumerics(text);
    expect(masked).toBe(text);
    expect(values).toEqual([]);
  });

  it('unmaskNumerics leaves an unknown label untouched (defensive — should not happen if the model behaves)', () => {
    expect(unmaskNumerics('нечто ⟦5⟧', ['a', 'b'])).toBe('нечто ⟦5⟧');
  });

  it('survives the model translating surrounding text while keeping labels intact', () => {
    const { values } = maskNumerics('Call +7 701 234 56 78 at 18:30');
    // имитация ответа модели — метки остаются, вокруг — перевод
    const modelOutput = 'Позвони ⟦1⟧ в ⟦2⟧';
    expect(unmaskNumerics(modelOutput, values)).toBe('Позвони +7 701 234 56 78 в 18:30');
  });
});
