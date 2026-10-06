/// Календарная дата для API без времени и часового пояса (задача 041, п.5):
/// «вторник» из Урумчи и из Алматы — одна и та же строка `2026-10-06`.
String ymd(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
}
