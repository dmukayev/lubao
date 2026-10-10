/// Эмодзи-флаг по коду страны ISO 3166-1 alpha-2 («KZ» → 🇰🇿); не код — пусто.
export function flagEmoji(code: string | null | undefined): string {
  if (!code || !/^[A-Za-z]{2}$/.test(code)) return '';
  return String.fromCodePoint(...[...code.toUpperCase()].map((ch) => 0x1f1e6 + ch.charCodeAt(0) - 65));
}

/// 058 п.3: флаги у городов маршрута — только если страны разные.
export function routeFlags(fromCode: string | null | undefined, toCode: string | null | undefined): [string, string] {
  if (!fromCode || !toCode || fromCode.toUpperCase() === toCode.toUpperCase()) return ['', ''];
  return [flagEmoji(fromCode), flagEmoji(toCode)];
}
