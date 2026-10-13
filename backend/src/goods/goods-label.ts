import { Prisma } from '@prisma/client';

type I18n = { ru?: string; kk?: string; zh?: string; en?: string };

/// 075: что везут — простым названием на языке читателя: товар из справочника
/// или свой текст логиста (перевод, а где его нет — оригинал). Null — показать
/// категорию, как у старых грузов.
export function goodsLabel(c: { goods?: { name: Prisma.JsonValue } | null; goodsText?: string | null; goodsTextLocale?: string | null; goodsTextTranslations?: Prisma.JsonValue | null }): I18n | null {
  if (c.goods?.name && typeof c.goods.name === 'object') return c.goods.name as I18n;
  const text = c.goodsText?.trim();
  if (!text) return null;
  const translations = (c.goodsTextTranslations && typeof c.goodsTextTranslations === 'object' ? c.goodsTextTranslations : {}) as I18n;
  return { ru: text, kk: text, zh: text, en: text, ...translations, ...(c.goodsTextLocale ? { [c.goodsTextLocale]: text } : {}) };
}
