import { Locale } from '@prisma/client';
import { I18nName, formatCargoWeight, formatMoney, groupThousands, paymentLine, pickLocaleText } from '../notifications/notification-events';
import { routeFlags } from '../common/flags';

/// 052 п.2: публичные страницы «Поделиться» — без входа, без Google и внешних
/// запросов (WeChat/Telegram открывают их во встроенном браузере). Телефона,
/// госномера и документов нет нигде. Язык — устройства открывшего.
export type PageLocale = 'ru' | 'kk' | 'zh' | 'en';

export function pageLocale(acceptLanguage?: string): PageLocale {
  for (const part of (acceptLanguage ?? '').toLowerCase().split(',')) {
    const tag = part.trim().slice(0, 2);
    if (tag === 'kk' || tag === 'ru' || tag === 'zh' || tag === 'en') return tag;
  }
  return 'ru';
}

const T: Record<PageLocale, Record<string, string>> = {
  ru: {
    cargo: 'Груз', km: 'км', loading: 'погрузка', perKm: '/км', respond: 'Откликнуться в приложении', android: 'Установить для Android', ios: 'Установить для iPhone',
    stale: 'Уже неактуально', staleCargo: 'Этот груз уже забрали или сняли.', staleDriver: 'Водитель уже не ищет груз.', similar: 'Похожие грузы',
    companyCargos: 'Грузы компании', noActive: 'Сейчас активных грузов нет', driver: 'Водитель', verified: 'Проверен', trips: 'рейсов в Lubao',
    lookingFrom: 'Ищет груз из', direction: 'Направление', anyCountry: 'любое', offer: 'Предложить груз в приложении', contactOnly: 'Связаться можно только в приложении Lubao — без телефона.',
    tagline: 'Lubao — биржа грузов', open: 'Открыть',
  },
  kk: {
    cargo: 'Жүк', km: 'км', loading: 'тиеу', perKm: '/км', respond: 'Қолданбада жауап беру', android: 'Android үшін орнату', ios: 'iPhone үшін орнату',
    stale: 'Енді өзекті емес', staleCargo: 'Бұл жүкті алып кетті немесе алып тастады.', staleDriver: 'Жүргізуші енді жүк іздемейді.', similar: 'Ұқсас жүктер',
    companyCargos: 'Компания жүктері', noActive: 'Қазір белсенді жүк жоқ', driver: 'Жүргізуші', verified: 'Тексерілген', trips: 'Lubao-дағы рейс',
    lookingFrom: 'Жүк іздейді:', direction: 'Бағыты', anyCountry: 'кез келген', offer: 'Қолданбада жүк ұсыну', contactOnly: 'Тек Lubao қолданбасында байланысуға болады — телефонсыз.',
    tagline: 'Lubao — жүк биржасы', open: 'Ашу',
  },
  zh: {
    cargo: '货物', km: '公里', loading: '装货', perKm: '/公里', respond: '在应用中响应', android: '安装 Android 版', ios: '安装 iPhone 版',
    stale: '已失效', staleCargo: '该货物已被承运或下架。', staleDriver: '该司机已不再找货。', similar: '相似货物',
    companyCargos: '公司货物', noActive: '目前没有进行中的货物', driver: '司机', verified: '已认证', trips: '次 Lubao 行程',
    lookingFrom: '找货地点：', direction: '方向', anyCountry: '任意', offer: '在应用中推荐货物', contactOnly: '只能在 Lubao 应用内联系 — 不显示电话。',
    tagline: 'Lubao — 货运平台', open: '打开',
  },
  en: {
    cargo: 'Cargo', km: 'km', loading: 'loading', perKm: '/km', respond: 'Respond in the app', android: 'Install for Android', ios: 'Install for iPhone',
    stale: 'No longer available', staleCargo: 'This cargo has been taken or withdrawn.', staleDriver: 'The driver is no longer looking for cargo.', similar: 'Similar cargo',
    companyCargos: 'Company cargo', noActive: 'No active cargo right now', driver: 'Driver', verified: 'Verified', trips: 'trips in Lubao',
    lookingFrom: 'Looking for cargo from', direction: 'Direction', anyCountry: 'any', offer: 'Offer cargo in the app', contactOnly: 'Contact only in the Lubao app — no phone numbers.',
    tagline: 'Lubao — freight exchange', open: 'Open',
  },
};

export function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

const MONTHS: Record<PageLocale, string[]> = {
  ru: ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'],
  kk: ['қаң', 'ақп', 'нау', 'сәу', 'мам', 'мау', 'шіл', 'там', 'қыр', 'қаз', 'қар', 'жел'],
  zh: [],
  en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
};
function shortDate(d: Date, l: PageLocale): string {
  const m = d.getUTCMonth();
  const day = d.getUTCDate();
  if (l === 'zh') return `${m + 1}月${day}日`;
  if (l === 'en') return `${MONTHS.en[m]} ${day}`;
  return `${day} ${MONTHS[l][m]}`;
}
/// Цена — как в приложении (058 п.4: «1 250 000 ₽», «95 000 000 сум»).
export function money(amount: number, currency: string, l: PageLocale = 'ru'): string {
  return formatMoney(amount, currency, l);
}

export interface PageCargo {
  id: string;
  origin: I18nName | null;
  destination: I18nName | null;
  category: I18nName | null;
  bodyType: I18nName | null;
  weightKg: number | null;
  /// 058 п.3: «21 т · 35 м³»; флаги стран маршрута (если страны разные).
  volumeM3?: number | null;
  originCountryCode?: string | null;
  destinationCountryCode?: string | null;
  /// 058 п.1: условия оплаты.
  advanceAmount?: number | null;
  paymentForm?: string | null;
  paymentDelayDays?: number | null;
  distanceKm: number | null;
  price: number;
  pricePerKm: number | null;
  currency: string;
  readyDate: Date;
  companyName: string;
  companyRatingAvg: number;
  companyRatingCount: number;
}

export interface PageDriver {
  fullName: string;
  isVerified: boolean;
  ratingAvg: number;
  ratingCount: number;
  trips: number;
  bodyType: I18nName | null;
  capacityTons: number | null;
  volumeM3: number | null;
  city: I18nName | null;
  countries: I18nName[];
  anyCountry: boolean;
  active: boolean;
}

export interface PageLinks {
  /// Открыть в приложении (универсальная ссылка / веб-приложение).
  appUrl: string;
  androidUrl: string;
  iosUrl: string;
  /// Код для отложенной ссылки: кладём в буфер перед переходом в магазин.
  code: string;
  canonicalUrl: string;
}

/// 057 п.23: «м³» — только ru/kk; en/zh — «m³».
const m3 = (l: PageLocale) => (l === 'ru' || l === 'kk' ? 'м³' : 'm³');
const txt = (n: I18nName | null, l: PageLocale) => (n ? pickLocaleText(n, l as Locale) : '');
const route = (c: PageCargo, l: PageLocale) => {
  const [fromFlag, toFlag] = routeFlags(c.originCountryCode, c.destinationCountryCode);
  return [[fromFlag, txt(c.origin, l)].filter(Boolean).join(' '), [toFlag, txt(c.destination, l)].filter(Boolean).join(' ')].filter((p) => p.length > 0).join(' → ');
};
const terms = (c: PageCargo, l: PageLocale) => paymentLine(c, l);

function cargoFacts(c: PageCargo, l: PageLocale): string {
  const size = [c.weightKg != null ? formatCargoWeight(c.weightKg, l) : '', c.volumeM3 ? `${groupThousands(c.volumeM3)} ${m3(l)}` : ''].filter(Boolean).join(' · ');
  return [txt(c.category, l), size, txt(c.bodyType, l).toLocaleLowerCase(l)].filter(Boolean).join(' · ');
}

function cargoRow(c: PageCargo, l: PageLocale, href: string): string {
  return `<a class="row" href="${escapeHtml(href)}"><div><b>${escapeHtml(route(c, l))}</b><div class="muted">${escapeHtml(cargoFacts(c, l))} · ${escapeHtml(shortDate(c.readyDate, l))}</div></div><div class="price">${escapeHtml(money(c.price, c.currency, l))}</div></a>`;
}

function actions(l: PageLocale, links: PageLinks, primary: string): string {
  const t = T[l];
  // Отложенная ссылка без сторонних сервисов: перед магазином код — в буфер,
  // приложение при первом входе берёт его и открывает нужный экран.
  const copy = `navigator.clipboard&&navigator.clipboard.writeText('LUBAO-${links.code}').catch(function(){})`;
  return `<div class="actions">
<a class="btn primary" href="${escapeHtml(links.appUrl)}" data-testid="share-open">${escapeHtml(primary)}</a>
<a class="btn" href="${escapeHtml(links.androidUrl)}" onclick="${copy}" data-testid="share-android">${escapeHtml(t.android)}</a>
<a class="btn" href="${escapeHtml(links.iosUrl)}" onclick="${copy}" data-testid="share-ios">${escapeHtml(t.ios)}</a>
</div><p class="muted small">${escapeHtml(t.contactOnly)}</p>`;
}

function layout(l: PageLocale, title: string, description: string, body: string, links: PageLinks, noindex: boolean): string {
  const t = T[l];
  return `<!doctype html><html lang="${l}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(title)}</title>
<meta name="description" content="${escapeHtml(description)}">
<meta property="og:title" content="${escapeHtml(title)}"><meta property="og:description" content="${escapeHtml(description)}">
<meta property="og:type" content="website"><meta property="og:url" content="${escapeHtml(links.canonicalUrl)}"><meta property="og:site_name" content="Lubao">
${noindex ? '<meta name="robots" content="noindex,nofollow">' : ''}
<style>
:root{--bg:#F3F4F8;--card:#fff;--text:#0F172A;--muted:#64748B;--primary:#2B4EF5;--accent:#FFB020}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Noto Sans SC",sans-serif}
main{max-width:560px;margin:0 auto;padding:16px}.brand{color:#E86B1E;font-weight:800;font-size:20px;margin:8px 0 16px}
.card{background:var(--card);border-radius:20px;padding:20px;margin-bottom:12px}.hero{background:var(--primary);color:#fff}
.hero .muted{color:rgba(255,255,255,.8)}h1{font-size:22px;margin:0 0 4px}.big{font-size:28px;font-weight:800;margin:8px 0 0}
.muted{color:var(--muted)}.small{font-size:13px}.row{display:flex;justify-content:space-between;gap:12px;padding:12px 0;border-top:1px solid #E5E7EB;color:inherit;text-decoration:none}
.row:first-child{border-top:0}.price{font-weight:700;white-space:nowrap}.actions{display:flex;flex-direction:column;gap:8px;margin-top:8px}
.btn{display:block;text-align:center;padding:14px;border-radius:14px;border:1px solid #D7DCE5;background:#fff;color:var(--text);font-weight:700;text-decoration:none}
.btn.primary{background:var(--primary);border-color:var(--primary);color:#fff}.pill{display:inline-block;padding:2px 10px;border-radius:999px;background:#E7F7EE;color:#137A43;font-size:13px;font-weight:700}
.stale{background:#FFF4DE}
</style></head><body><main><div class="brand">Lubao</div>${body}<p class="muted small">${escapeHtml(t.tagline)}</p></main></body></html>`;
}

export function renderCargoPage(l: PageLocale, cargo: PageCargo | null, similar: PageCargo[], links: PageLinks, similarHref: (c: PageCargo) => string): string {
  const t = T[l];
  if (!cargo) {
    const body = `<div class="card stale" data-testid="share-stale"><h1>${escapeHtml(t.stale)}</h1><p class="muted">${escapeHtml(t.staleCargo)}</p></div>
${similar.length ? `<div class="card"><b>${escapeHtml(t.similar)}</b>${similar.map((c) => cargoRow(c, l, similarHref(c))).join('')}</div>` : ''}${actions(l, links, t.open)}`;
    return layout(l, t.stale, t.staleCargo, body, links, false);
  }
  const r = route(cargo, l);
  const perKm = cargo.pricePerKm != null ? ` (${money(cargo.pricePerKm, cargo.currency, l)}${t.perKm})` : '';
  const rating = cargo.companyRatingCount > 0 ? ` · ★ ${cargo.companyRatingAvg.toFixed(1)}` : '';
  const body = `<div class="card hero" data-testid="share-cargo"><h1>${escapeHtml(r)}</h1><div class="big">${escapeHtml(money(cargo.price, cargo.currency, l))}</div><div class="muted">${escapeHtml(perKm.trim())}</div>${terms(cargo, l) ? `<div data-testid="share-terms">${escapeHtml(terms(cargo, l))}</div>` : ''}</div>
<div class="card"><div>🚛 <b>${escapeHtml(r)}</b>${cargo.distanceKm ? ` · ${groupThousands(cargo.distanceKm)} ${escapeHtml(t.km)}` : ''}</div>
<div>${escapeHtml(cargoFacts(cargo, l))}</div><div>💰 ${escapeHtml(money(cargo.price, cargo.currency, l) + perKm)}</div>
<div>📅 ${escapeHtml(t.loading)} ${escapeHtml(shortDate(cargo.readyDate, l))}</div><div class="muted">${escapeHtml(cargo.companyName + rating)}</div></div>
${actions(l, links, t.respond)}`;
  const description = [cargoFacts(cargo, l), money(cargo.price, cargo.currency, l), terms(cargo, l), `${t.loading} ${shortDate(cargo.readyDate, l)}`].filter(Boolean).join(' · ');
  return layout(l, `${r} · ${money(cargo.price, cargo.currency, l)}`, description, body, links, false);
}

export function renderCompanyPage(l: PageLocale, companyName: string, cargos: PageCargo[], links: PageLinks, cargoHref: (c: PageCargo) => string): string {
  const t = T[l];
  const body = `<div class="card" data-testid="share-company"><h1>${escapeHtml(companyName)}</h1><div class="muted">${escapeHtml(t.companyCargos)}</div>
${cargos.length ? cargos.map((c) => cargoRow(c, l, cargoHref(c))).join('') : `<p class="muted">${escapeHtml(t.noActive)}</p>`}</div>${actions(l, links, t.respond)}`;
  return layout(l, `${companyName} — ${t.companyCargos}`, cargos.slice(0, 3).map((c) => route(c, l)).join('; ') || t.noActive, body, links, false);
}

export function renderDriverPage(l: PageLocale, d: PageDriver, links: PageLinks): string {
  const t = T[l];
  if (!d.active) {
    const body = `<div class="card stale" data-testid="share-stale"><h1>${escapeHtml(t.stale)}</h1><p class="muted">${escapeHtml(t.staleDriver)}</p></div>${actions(l, links, t.open)}`;
    return layout(l, t.stale, t.staleDriver, body, links, true);
  }
  const vehicle = [txt(d.bodyType, l), d.capacityTons != null ? `${d.capacityTons} ${l === 'zh' ? '吨' : l === 'en' ? 't' : 'т'}` : '', d.volumeM3 != null ? `${d.volumeM3} ${m3(l)}` : ''].filter(Boolean).join(', ');
  const countries = d.anyCountry ? t.anyCountry : d.countries.map((c) => txt(c, l)).join(', ');
  const rating = d.ratingCount > 0 ? `★ ${d.ratingAvg.toFixed(1)} · ` : '';
  const body = `<div class="card" data-testid="share-driver"><h1>🚚 ${escapeHtml(d.fullName)}</h1>${d.isVerified ? `<span class="pill">${escapeHtml(t.verified)}</span>` : ''}
<div style="margin-top:8px">${escapeHtml(vehicle)}</div>
${d.city ? `<div>📍 ${escapeHtml(t.lookingFrom)} ${escapeHtml(txt(d.city, l))}</div>` : ''}${countries ? `<div class="muted">${escapeHtml(t.direction)}: ${escapeHtml(countries)}</div>` : ''}
<div class="muted">${escapeHtml(rating)}${d.trips} ${escapeHtml(t.trips)}</div></div>${actions(l, links, t.offer)}`;
  return layout(l, `${d.fullName} · ${vehicle}`, [vehicle, d.city ? txt(d.city, l) : ''].filter(Boolean).join(' · '), body, links, true);
}
