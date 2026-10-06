/// Рейтинг для показа (041, п.13): без отзывов — «—», а не «0.0» (ноль
/// выглядит как плохая оценка у человека, которого просто ещё не оценили).
String formatRating(double average, int count) => count == 0 ? '—' : average.toStringAsFixed(1);
