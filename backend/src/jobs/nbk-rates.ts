/// Курсы Нацбанка РК (задача 042, п.4): RSS `get_rates.cfm?fdate=ДД.ММ.ГГГГ`.
/// Берём только валюты грузов, кроме ₸: USD, CNY и (058 п.4) RUB, UZS.
import { RATE_CURRENCIES, RateCurrency } from '../common/currencies';

export type NbkRate = { currency: RateCurrency; rateToKzt: number };

const WANTED = new Set<string>(RATE_CURRENCIES);

export function nbkRatesUrl(date: Date, base = process.env.NBK_RATES_URL || 'https://nationalbank.kz/rss/get_rates.cfm'): string {
  const dd = String(date.getUTCDate()).padStart(2, '0');
  const mm = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${base}?fdate=${dd}.${mm}.${date.getUTCFullYear()}`;
}

function tag(block: string, name: string): string | null {
  const match = block.match(new RegExp(`<${name}>\\s*([^<]*?)\\s*</${name}>`, 'i'));
  return match ? match[1] : null;
}

/// Курс за ОДНУ единицу валюты: `description` — курс за `quant` единиц
/// (у CNY, как у ряда других валют, quant может быть 1, 10, 100).
export function parseNbkRates(xml: string): NbkRate[] {
  const rates: NbkRate[] = [];
  for (const [, block] of xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)) {
    const code = tag(block, 'title')?.toUpperCase();
    if (!code || !WANTED.has(code)) continue;
    const value = Number((tag(block, 'description') ?? '').replace(',', '.'));
    const quant = Number(tag(block, 'quant') ?? '1') || 1;
    if (!Number.isFinite(value) || value <= 0) continue;
    rates.push({ currency: code as RateCurrency, rateToKzt: Math.round((value / quant) * 1e6) / 1e6 });
  }
  return rates;
}
