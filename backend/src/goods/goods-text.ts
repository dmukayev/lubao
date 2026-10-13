/// 075: строка поиска — все названия и синонимы в нижнем регистре через « | ».
export function goodsSearchText(name: Record<string, unknown> | null | undefined, synonyms?: Record<string, unknown> | null): string {
  const parts: string[] = [];
  for (const v of Object.values(name ?? {})) if (typeof v === 'string') parts.push(v);
  for (const list of Object.values(synonyms ?? {})) if (Array.isArray(list)) for (const v of list) if (typeof v === 'string') parts.push(v);
  return parts.map((p) => p.trim().toLowerCase()).filter(Boolean).join(' | ');
}
