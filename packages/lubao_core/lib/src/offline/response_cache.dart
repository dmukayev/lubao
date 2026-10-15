import 'dart:convert';

/// 078 (decisions.md «Сначала показать, потом обновить»): хранилище ответов
/// сервера на телефоне. Реализация — в приложении (файлы на диске); в вебе и
/// тестах — память.
abstract class CacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
}

class MemoryCacheStore implements CacheStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}

/// Что и сколько хранить. Чужие телефоны и документы других людей — никогда:
/// их адреса сюда не входят, а поля с номером вырезаются перед записью.
class CachePolicy {
  const CachePolicy(this.maxAge, {this.keepLast});

  /// Старше — не показывать (лента: 6 ч; карточки: 24 ч).
  final Duration maxAge;

  /// Для списков сообщений — только последние N.
  final int? keepLast;

  static const _day = Duration(days: 1);
  static const _week = Duration(days: 7);

  /// Что НЕ сохраняем: выдача номера телефона (по нажатию, с учётом),
  /// документы людей и распознавание, вход/сессии, админка, разовые подсказки.
  static final _never = RegExp(
    r'(/contact|phone|driver-documents|/recognition|verification-documents/|^/auth/(?!me$)|^/admin|^/share/|^/app/|^/companies/invites/|latin-name|fit-count|market-hint|^/goods/search|/access-log)',
  );

  static CachePolicy? forPath(String path) {
    if (_never.hasMatch(path)) return null;
    // Лента: старше 6 ч не показываем (решение 078).
    if (path == '/cargos') return const CachePolicy(Duration(hours: 6));
    if (RegExp(r'^/chats/[^/]+/messages$').hasMatch(path)) return const CachePolicy(_week, keepLast: 50);
    if (RegExp(r'^/drivers/[^/]+/card$').hasMatch(path)) return const CachePolicy(_day);
    // Остальное (свой профиль и документы-список, сделки, рейсы, чаты, грузы,
    // «Кто свободен», справочники, отклики, отзывы…) — неделю; без связи — и старше.
    return const CachePolicy(_week);
  }

}

/// Сохранённый ответ: данные и когда получены.
class CachedResponse {
  const CachedResponse(this.data, this.savedAt);
  final Object? data;
  final DateTime savedAt;

  Duration get age => DateTime.now().difference(savedAt);

  String encode() => jsonEncode({'savedAt': savedAt.toIso8601String(), 'data': data});

  static CachedResponse? decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CachedResponse(map['data'], DateTime.parse(map['savedAt'] as String));
    } catch (_) {
      return null;
    }
  }
}

const _phoneKeys = {'phone', 'contactPhone', 'phoneNumber', 'driverPhone', 'companyPhone'};

/// Поля с номером телефона — вырезать (номер выдаётся по нажатию и учитывается).
Object? stripPhones(Object? value) {
  if (value is Map) {
    return {
      for (final e in value.entries)
        if (!_phoneKeys.contains(e.key)) e.key: stripPhones(e.value),
    };
  }
  if (value is List) return [for (final v in value) stripPhones(v)];
  return value;
}

/// Ключ записи: пользователь + адрес + параметры по алфавиту.
String cacheKey(String scope, String path, Map<String, dynamic>? query) {
  final q = query == null || query.isEmpty ? '' : '?${(query.keys.toList()..sort()).map((k) => '$k=${query[k]}').join('&')}';
  return '$scope|$path$q';
}
