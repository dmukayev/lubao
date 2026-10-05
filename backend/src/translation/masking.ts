/// Защита чисел от искажения моделью (задача 010, п.3а, решение
/// 2026-10-05 «разумная середина») — перед переводом заменяем метками
/// `⟦1⟧, ⟦2⟧…` только то, где ошибка стоит денег: телефоны, госномера,
/// суммы с валютой, время, даты. Email/ссылки/имена — НЕ маскируем (не в
/// списке, и так не искажаются моделью так, как числа).
///
/// Один общий regex, не отдельный проход на каждый тип: структурные
/// требования каждой альтернативы (двоеточие у времени, точка/слэш у
/// даты, буквы у госномера, $/¥/₸ у суммы, 7+ цифр подряд у телефона) не
/// пересекаются, поэтому порядок альтернатив в этой реализации не важен —
/// левый-самый-длинный матч regex всё равно не даёт короткой сумме типа
/// «2 600» (4 цифры) по ошибке сработать как телефон (нужно 7+).
const MASK_PATTERN = new RegExp(
  [
    // телефон: + и/или 7-15 цифр, допускаются пробелы/дефисы между группами
    String.raw`\+?\d(?:[\s-]?\d){6,14}`,
    // госномер KZ: 777 ABP 05
    String.raw`\b\d{3}\s?[A-ZА-ЯЁ]{2,3}\s?\d{2}\b`,
    // сумма с валютой до или после числа
    String.raw`[\$¥₸₽]\s?\d[\d\s.,]*\d`,
    String.raw`\d[\d\s.,]*\d\s?(?:\$|USD|CNY|KZT|RUB|₸|¥|₽|сом|тенге|юаней|юань)`,
    // время HH:MM
    String.raw`\b\d{1,2}:\d{2}\b`,
    // дата D.M или D.M.YYYY (точка или слэш)
    String.raw`\b\d{1,2}[./]\d{1,2}(?:[./]\d{2,4})?\b`,
  ].join('|'),
  'giu',
);

export interface MaskedText {
  masked: string;
  values: string[];
}

export function maskNumerics(text: string): MaskedText {
  const values: string[] = [];
  const masked = text.replace(MASK_PATTERN, (match) => {
    values.push(match);
    return `⟦${values.length}⟧`;
  });
  return { masked, values };
}

export function unmaskNumerics(text: string, values: string[]): string {
  return text.replace(/⟦(\d+)⟧/g, (full, indexStr) => {
    const index = Number(indexStr) - 1;
    return index >= 0 && index < values.length ? values[index] : full;
  });
}
