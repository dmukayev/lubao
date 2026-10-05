/// Задача 031, этап D, п.19 — сравнение распознанного ФИО с профилем:
/// латиница/кириллица, с допуском на опечатку OCR. Нормализация и
/// транслитерация — тот же алгоритм, что city_search.dart в lubao_core
/// (Flutter), портированный на TypeScript для бэкенда: два рантайма, один
/// и тот же набор правил, чтобы поведение не разъезжалось.

const KAZAKH_TO_RUSSIAN_FOLD: Record<string, string> = {
  қ: 'к', ғ: 'г', ң: 'н', ө: 'о', ұ: 'у', ү: 'у', һ: 'х', і: 'и', ә: 'а',
};

function foldKazakhLetters(s: string): string {
  return s
    .split('')
    .map((ch) => KAZAKH_TO_RUSSIAN_FOLD[ch] ?? ch)
    .join('');
}

export function normalizeForMatch(input: string): string {
  let s = input.trim().toLowerCase();
  s = s.replace(/ё/g, 'е');
  s = foldKazakhLetters(s);
  s = s.replace(/[\s-]+/g, '');
  return s;
}

const LATIN_TO_CYRILLIC_DIGRAPHS: Array<[string, string]> = [
  ['shch', 'щ'],
  ['sh', 'ш'],
  ['ch', 'ч'],
  ['zh', 'ж'],
  ['kh', 'х'],
  ['ts', 'ц'],
  ['yu', 'ю'],
  ['ya', 'я'],
  ['yo', 'ё'],
  ['ye', 'е'],
];

const LATIN_TO_CYRILLIC_SINGLE: Record<string, string> = {
  a: 'а', b: 'б', c: 'к', d: 'д', e: 'е', f: 'ф', g: 'г', h: 'х',
  i: 'и', j: 'й', k: 'к', l: 'л', m: 'м', n: 'н', o: 'о', p: 'п',
  q: 'к', r: 'р', s: 'с', t: 'т', u: 'у', v: 'в', w: 'в', x: 'кс',
  y: 'ы', z: 'з',
};

const ASCII_LETTERS_ONLY = /^[a-z]+$/;

function transliterateLatinToCyrillic(normalized: string): string | null {
  if (!ASCII_LETTERS_ONLY.test(normalized)) return null;
  let result = '';
  let i = 0;
  while (i < normalized.length) {
    const digraph = LATIN_TO_CYRILLIC_DIGRAPHS.find(([latin]) => normalized.startsWith(latin, i));
    if (digraph) {
      result += digraph[1];
      i += digraph[0].length;
      continue;
    }
    result += LATIN_TO_CYRILLIC_SINGLE[normalized[i]] ?? normalized[i];
    i += 1;
  }
  return result;
}

function matchCandidates(raw: string): Set<string> {
  const normalized = normalizeForMatch(raw);
  if (!normalized) return new Set();
  const candidates = new Set([normalized]);
  const translit = transliterateLatinToCyrillic(normalized);
  if (translit) candidates.add(translit);
  return candidates;
}

/// Расстояние Левенштейна — допуск на опечатку OCR (п.19: «ФИО...
/// сравнение с профилем с транслитерацией... и допуском на опечатку»).
export function levenshteinDistance(a: string, b: string): number {
  const rows = a.length + 1;
  const cols = b.length + 1;
  const dp: number[][] = Array.from({ length: rows }, (_, i) => [i, ...Array(cols - 1).fill(0)]);
  for (let j = 0; j < cols; j++) dp[0][j] = j;

  for (let i = 1; i < rows; i++) {
    for (let j = 1; j < cols; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      dp[i][j] = Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost);
    }
  }
  return dp[rows - 1][cols - 1];
}

/// true — распознанное ФИО и ФИО в профиле считаются одним и тем же
/// именем (после нормализации/транслитерации, с допуском на 1-2 опечатки
/// пропорционально длине). Не находит совпадения → поле помечается
/// needsReview в recognition.service.ts, не отклоняется само по себе.
export function namesLikelyMatch(recognized: string, profileName: string): boolean {
  const recognizedCandidates = matchCandidates(recognized);
  const profileCandidates = matchCandidates(profileName);
  if (recognizedCandidates.size === 0 || profileCandidates.size === 0) return false;

  for (const a of recognizedCandidates) {
    for (const b of profileCandidates) {
      const maxLen = Math.max(a.length, b.length);
      const tolerance = maxLen <= 4 ? 0 : Math.max(1, Math.round(maxLen * 0.2));
      if (levenshteinDistance(a, b) <= tolerance) return true;
    }
  }
  return false;
}
