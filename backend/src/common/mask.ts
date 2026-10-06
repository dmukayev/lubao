/// Маски для логов и отчётов об ошибках (задача 043, п.6): телефоны, ИИН,
/// email и номера в сообщениях не должны попадать в логи целиком.

export function maskPhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 7) return '***';
  return `+${digits.slice(0, 4)}***${digits.slice(-2)}`;
}

export function maskEmail(email: string): string {
  const [name, domain] = email.split('@');
  if (!domain) return '***';
  return `${name.slice(0, 1)}***@${domain}`;
}

/// Вырезает из произвольной строки то, что похоже на телефон (7–15 цифр,
/// возможно с «+», пробелами и дефисами), ИИН (12 цифр) и email.
export function scrubText(text: string): string {
  // ISO-даты (2026-10-07) по длине похожи на телефон — прячем их на время замены.
  const dates: string[] = [];
  const scrubbed = text
    .replace(/\d{4}-\d{2}-\d{2}/g, (d) => `\u0000${dates.push(d) - 1}\u0000`)
    .replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, (m) => maskEmail(m))
    .replace(/\+?\d[\d\s-]{6,}\d/g, (m) => {
      const digits = m.replace(/\D/g, '');
      if (digits.length < 10) return m; // даты, суммы, id
      return digits.length === 12 && !m.startsWith('+') ? '[ИИН]' : maskPhone(m);
    });
  return scrubbed.replace(/\u0000(\d+)\u0000/g, (_m, i: string) => dates[Number(i)]);
}
