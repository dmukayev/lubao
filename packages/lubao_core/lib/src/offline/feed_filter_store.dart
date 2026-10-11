import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/feed_filter.dart';

/// 059: фильтр ленты водителя на устройстве (как «Недавние города»).
class FeedFilterStore {
  FeedFilterStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'feed_filter_v1';
  final FlutterSecureStorage _storage;

  Future<FeedFilter> load() async {
    try {
      return FeedFilter.fromJsonString(await _storage.read(key: _key));
    } catch (_) {
      return FeedFilter.empty;
    }
  }

  Future<void> save(FeedFilter filter) async {
    try {
      await _storage.write(key: _key, value: filter.toJsonString());
    } catch (_) {
      // Не сохранилось — не критично.
    }
  }

  /// Сбросить сохранённый фильтр (выход, сквозные сценарии).
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
