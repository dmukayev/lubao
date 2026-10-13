import '../api/api_client.dart';

/// 078: сначала — сохранённое (мгновенно), потом — свежее с сервера. Нет
/// связи и есть сохранённое — ошибку не показываем, остаётся сохранённое.
Stream<T> cacheFirst<T>(
  ApiClient api,
  String path, {
  Map<String, dynamic>? query,
  required T Function(Object? data) parse,
  required Future<T> Function() fetch,
}) async* {
  T? shown;
  try {
    final cached = await api.peek(path, query: query);
    if (cached != null) {
      shown = parse(cached.data);
      yield shown as T;
    }
  } catch (_) {
    // Сохранённое не разобралось (сменился формат) — просто идём в сеть.
  }
  try {
    yield await fetch();
  } catch (_) {
    if (shown == null) rethrow;
  }
}
