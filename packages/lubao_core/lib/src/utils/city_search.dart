import '../models/common.dart';
import '../models/reference_data.dart';

/// Поиск города не зависит от языка интерфейса (задача 021): ищем по kk/ru/zh/en
/// названиям сразу, с нормализацией регистра/казахских букв и простой
/// транслитерацией латиница→кириллица (Shymkent ≈ Шымкент).

const _kazakhToRussianFold = {
  'қ': 'к', 'ғ': 'г', 'ң': 'н', 'ө': 'о', 'ұ': 'у', 'ү': 'у', 'һ': 'х', 'і': 'и', 'ә': 'а',
};

String _foldKazakhLetters(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_kazakhToRussianFold[ch] ?? ch);
  }
  return buffer.toString();
}

/// lower-case, ё→е, казахские буквы → русские аналоги, без пробелов/дефисов.
String normalizeForSearch(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll('ё', 'е');
  s = _foldKazakhLetters(s);
  s = s.replaceAll(RegExp(r'[\s\-]+'), '');
  return s;
}

// Диграфы проверяются первыми (длиннее — приоритетнее), затем — посимвольно.
const _latinToCyrillicDigraphs = <List<String>>[
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

const _latinToCyrillicSingle = <String, String>{
  'a': 'а', 'b': 'б', 'c': 'к', 'd': 'д', 'e': 'е', 'f': 'ф', 'g': 'г', 'h': 'х',
  'i': 'и', 'j': 'й', 'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п',
  'q': 'к', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у', 'v': 'в', 'w': 'в', 'x': 'кс',
  'y': 'ы', 'z': 'з',
};

final _asciiLettersOnly = RegExp(r'^[a-z]+$');

/// Неоднозначная латиница↔кириллица транслитерация (sh/ш, y...) — поэтому не
/// строим единый канонический алфавит, а только даём ОДИН дополнительный
/// кандидат-кириллицу для чисто латинских строк; сравнение ниже проверяет
/// оба варианта запроса против обоих вариантов каждого названия.
String? _transliterateLatinToCyrillic(String normalized) {
  if (!_asciiLettersOnly.hasMatch(normalized)) return null;
  final buffer = StringBuffer();
  var i = 0;
  while (i < normalized.length) {
    String? matched;
    for (final pair in _latinToCyrillicDigraphs) {
      if (normalized.startsWith(pair[0], i)) {
        matched = pair[1];
        i += pair[0].length;
        break;
      }
    }
    if (matched != null) {
      buffer.write(matched);
      continue;
    }
    buffer.write(_latinToCyrillicSingle[normalized[i]] ?? normalized[i]);
    i++;
  }
  return buffer.toString();
}

/// 1-2 нормализованных кандидата для сравнения (кириллический фолдинг +,
/// если строка латинская, её кириллический эквивалент).
Set<String> _searchCandidates(String raw) {
  final normalized = normalizeForSearch(raw);
  if (normalized.isEmpty) return const {};
  final candidates = {normalized};
  final translit = _transliterateLatinToCyrillic(normalized);
  if (translit != null) candidates.add(translit);
  return candidates;
}

Set<String> _candidatesForI18n(I18nText name) =>
    name.allVariants.expand(_searchCandidates).toSet();

/// 0 — префиксное совпадение по названию города (высший приоритет),
/// 1 — вхождение по названию города, 2 — совпадение по названию страны.
int? _rank(Set<String> queryCandidates, Set<String> nameCandidates) {
  int? best;
  for (final q in queryCandidates) {
    if (q.isEmpty) continue;
    for (final n in nameCandidates) {
      if (n.isEmpty) continue;
      if (n.startsWith(q)) return 0;
      if (n.contains(q) && (best == null || best > 1)) best = 1;
    }
  }
  return best;
}

List<City> searchCities(List<City> cities, List<Country> countries, String query, {int limit = 20}) {
  final queryCandidates = _searchCandidates(query);
  if (queryCandidates.isEmpty) return const [];

  final countryNameCandidates = <String, Set<String>>{
    for (final country in countries) country.id: _candidatesForI18n(country.name),
  };

  final ranked = <(City, int)>[];
  for (final city in cities) {
    final nameCandidates = _candidatesForI18n(city.name);
    var rank = _rank(queryCandidates, nameCandidates);
    if (rank == null) {
      final countryRank = _rank(queryCandidates, countryNameCandidates[city.countryId] ?? const {});
      if (countryRank != null) rank = 2;
    }
    if (rank != null) ranked.add((city, rank));
  }

  ranked.sort((a, b) => a.$2.compareTo(b.$2));
  return ranked.take(limit).map((r) => r.$1).toList();
}

/// Поиск города погрузки (задача 040): те же правила, что у [searchCities] —
/// по названиям на всех четырёх языках, не зависит от языка интерфейса.
/// Пустой запрос — пустой результат (вызывающий покажет полный список).
List<LoadingPoint> searchPoints(List<LoadingPoint> points, String query, {int limit = 50}) {
  final queryCandidates = _searchCandidates(query);
  if (queryCandidates.isEmpty) return const [];

  final ranked = <(LoadingPoint, int)>[];
  for (final point in points) {
    final rank = _rank(queryCandidates, _candidatesForI18n(point.name));
    if (rank != null) ranked.add((point, rank));
  }
  ranked.sort((a, b) => a.$2.compareTo(b.$2));
  return ranked.take(limit).map((r) => r.$1).toList();
}
