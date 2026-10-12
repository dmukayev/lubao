/// Эмодзи-флаг по коду страны ISO 3166-1 alpha-2 («KZ» → 🇰🇿); не код — пусто.
export function flagEmoji(code: string | null | undefined): string {
  if (!code || !/^[A-Za-z]{2}$/.test(code)) return '';
  return String.fromCodePoint(...[...code.toUpperCase()].map((ch) => 0x1f1e6 + ch.charCodeAt(0) - 65));
}

/// Флаги у городов маршрута — всегда, и внутри одной страны (decisions.md
/// 2026-10-13; раньше — только при разных странах, 058 п.3).
export function routeFlags(fromCode: string | null | undefined, toCode: string | null | undefined): [string, string] {
  return [flagEmoji(fromCode), flagEmoji(toCode)];
}
