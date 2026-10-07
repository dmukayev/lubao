/// Сравнение версий `x.y.z` (043 п.8, «Обновите приложение»): `true`, если
/// [current] строго ниже [minimum]. Нечисловые/пустые части — 0; суффиксы
/// сборки (`+12`, `-beta`) не учитываются.
bool isVersionBelow(String current, String minimum) {
  List<int> parts(String v) => v.split(RegExp(r'[+-]')).first.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final a = parts(current);
  final b = parts(minimum);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}
