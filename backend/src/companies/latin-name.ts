import { pinyin } from 'pinyin-pro';

/// 069: латинское название китайской компании — водитель иероглифы не прочтёт.

/// Иероглифы (CJK) в названии — значит, нужно латинское название.
export function hasCjk(text: string): boolean {
  return /[㐀-鿿豈-﫿]/.test(text);
}

/// Латиница, цифры, пробел и `. , & - ( ) '`, длина 2–100.
export const LATIN_NAME_PATTERN = /^[A-Za-z0-9 .,&\-()']{2,100}$/;

export function isValidLatinName(text: string): boolean {
  return LATIN_NAME_PATTERN.test(text.trim());
}

/// Частые части названий — словом, а не слогами пиньиня (длинные — первыми).
const KNOWN_PARTS: Array<[string, string]> = [
  ['股份有限公司', 'Co., Ltd.'],
  ['有限责任公司', 'Co., Ltd.'],
  ['有限公司', 'Co., Ltd.'],
  ['进出口', 'Import & Export'],
  ['供应链', 'Supply Chain'],
  ['国际', 'International'],
  ['贸易', 'Trading'],
  ['商贸', 'Trading'],
  ['物流', 'Logistics'],
  ['运输', 'Transport'],
  ['货运', 'Freight'],
  ['科技', 'Technology'],
  ['实业', 'Industrial'],
  ['集团', 'Group'],
  ['公司', 'Co.'],
  ['霍尔果斯', 'Horgos'],
  ['乌鲁木齐', 'Urumqi'],
  ['阿拉山口', 'Alashankou'],
  ['新疆', 'Xinjiang'],
  ['伊犁', 'Ili'],
  ['喀什', 'Kashgar'],
];

/// Подсказка латинского названия: известные части — словом, остальное —
/// пиньинь слитно с заглавной («霍尔果斯瑞达贸易有限公司» → «Horgos Ruida
/// Trading Co., Ltd.»). Локальная библиотека, без облака; логист исправит.
export function suggestLatinName(name: string): string {
  const words: string[] = [];
  let run = '';
  const flushRun = () => {
    if (!run) return;
    const syllables = pinyin(run, { toneType: 'none', type: 'array', nonZh: 'consecutive' })
      .join('')
      .replace(/[^A-Za-z0-9]/g, '');
    if (syllables) words.push(syllables.charAt(0).toUpperCase() + syllables.slice(1).toLowerCase());
    run = '';
  };
  let i = 0;
  const text = name.trim();
  while (i < text.length) {
    const known = KNOWN_PARTS.find(([zh]) => text.startsWith(zh, i));
    if (known) {
      flushRun();
      words.push(known[1]);
      i += known[0].length;
      continue;
    }
    const ch = text[i];
    if (hasCjk(ch)) {
      run += ch;
    } else {
      flushRun();
      // Латиница и цифры в названии — как есть, прочее — пробелом.
      if (/[A-Za-z0-9]/.test(ch)) {
        const last = words.length ? words[words.length - 1] : '';
        if (i > 0 && /[A-Za-z0-9]/.test(text[i - 1]) && last) words[words.length - 1] = last + ch;
        else words.push(ch);
      }
    }
    i++;
  }
  flushRun();
  return words.join(' ').replace(/\s+/g, ' ').trim().slice(0, 100);
}

/// Что показать водителю вместо китайского названия: латиница; у старой
/// компании без неё — `nameRu`, если оно не иероглифами; иначе null (оригинал).
export function companyLatin(company: { name: string; nameRu?: string | null; nameLatin?: string | null } | null | undefined): string | null {
  if (!company || !hasCjk(company.name)) return null;
  if (company.nameLatin) return company.nameLatin;
  if (company.nameRu && !hasCjk(company.nameRu)) return company.nameRu;
  return null;
}
