import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Недавно выбранные города (задача 040, п.2) — для блока «Недавние» в
/// выборе города. Хранилище то же, что у токенов и очереди контакт-событий.
class RecentPointsStore {
  RecentPointsStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'lubao.recentPoints';
  static const maxItems = 5;

  Future<List<String>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  /// Выбранный город — в начало; повтор не дублируется, лишнее обрезается.
  Future<void> remember(String pointId) async {
    final current = await load();
    final next = [pointId, ...current.where((id) => id != pointId)].take(maxItems).toList();
    await _storage.write(key: _key, value: next.join(','));
  }
}
