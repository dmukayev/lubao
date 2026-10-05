/// Формат рег. номера компании по стране (задача 012, п. «Обязательные
/// поля»): 统一社会信用代码 в КНР — 18 букв/цифр; БИН в Казахстане —
/// 12 цифр. Для любой другой страны (пока не предусмотренный на пилоте
/// случай) — не ограничиваем формат, только непустую строку, чтобы не
/// блокировать компании из стран, для которых формат ещё не описан.
export function isValidRegistrationNumber(countryCode: string, value: string): boolean {
  const trimmed = value.trim();
  if (trimmed.length === 0) return false;
  switch (countryCode) {
    case 'CN':
      return /^[A-Z0-9]{18}$/.test(trimmed.toUpperCase());
    case 'KZ':
      return /^\d{12}$/.test(trimmed);
    default:
      return true;
  }
}
