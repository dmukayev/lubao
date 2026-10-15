import 'dart:convert';

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
  String? shownRaw;
  try {
    final cached = await api.peek(path, query: query);
    if (cached != null) {
      shown = parse(cached.data);
      shownRaw = jsonEncode(cached.data);
      yield shown as T;
    }
  } catch (_) {
    // Сохранённое не разобралось (сменился формат) — просто идём в сеть.
  }
  try {
    final fresh = await fetch();
    // Ничего не изменилось — не перерисовывать (список не прыгает под пальцем).
    if (shownRaw != null && api.sameAsShown(path, query, shownRaw)) return;
    yield fresh;
  } catch (_) {
    if (shown == null) rethrow;
  }
}
