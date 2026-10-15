import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import 'data_cache_store.dart';

/// 078: данные самого телефона (не копия ответов сервера): связи
/// «водитель/груз → чат», черновики форм, очередь неотправленных сообщений.
/// Стирается при выходе из аккаунта.
final localStoreProvider = Provider<CacheStore>((ref) => DataCacheStore(folder: 'lubao_local'));

/// Кто входил последним на этом телефоне — запуск без связи открывает его
/// сохранённое (ключ без привязки к пользователю; стирается при выходе).
const lastUserKey = 'lastUser';
final localDataProvider = Provider<LocalData>((ref) {
  final api = ref.watch(apiClientProvider);
  return LocalData(_ScopedStore(ref.watch(localStoreProvider), () => api.cacheScope));
});

/// Ключи — свои у каждого пользователя (на одном телефоне могут войти разные).
class _ScopedStore implements CacheStore {
  _ScopedStore(this._inner, this._scope);
  final CacheStore _inner;
  final String? Function() _scope;

  String _key(String key) => '${_scope() ?? '-'}|$key';

  @override
  Future<String?> read(String key) => _inner.read(_key(key));

  @override
  Future<void> write(String key, String value) => _inner.write(_key(key), value);

  @override
  Future<void> remove(String key) => _inner.remove(_key(key));

  @override
  Future<void> clear() => _inner.clear();
}

class LocalData {
  LocalData(this._store);
  final CacheStore _store;

  // Связь «водитель/груз → чат»: повторное «Написать» — без запроса.
  static String _chatKey({String? driverId, String? cargoId}) => 'chat|${driverId ?? ''}|${cargoId ?? ''}';

  Future<String?> chatFor({String? driverId, String? cargoId}) => _store.read(_chatKey(driverId: driverId, cargoId: cargoId));

  Future<void> rememberChat(String chatId, {String? driverId, String? cargoId}) =>
      _store.write(_chatKey(driverId: driverId, cargoId: cargoId), chatId);

  Future<void> forgetChat({String? driverId, String? cargoId}) => _store.remove(_chatKey(driverId: driverId, cargoId: cargoId));

  // Телефон логиста по текущей сделке — открыт по нажатию и нужен без связи
  // (decisions.md 2026-10-14). Только пока сделка идёт; стирается при выходе.
  Future<String?> dealPhone(String cargoId) => _store.read('dealPhone|$cargoId');

  Future<void> rememberDealPhone(String cargoId, String phone) => _store.write('dealPhone|$cargoId', phone);

  // Черновики форм («Продолжить черновик?»).
  Future<Map<String, dynamic>?> draft(String name) async {
    final raw = await _store.read('draft|$name');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraft(String name, Map<String, dynamic> data) => _store.write('draft|$name', jsonEncode(data));

  Future<void> clearDraft(String name) => _store.remove('draft|$name');

  // Неотправленные сообщения чата — уходят, когда появится связь.
  Future<List<OutgoingMessage>> outbox(String chatId) async {
    final raw = await _store.read('outbox|$chatId');
    if (raw == null) return const [];
    try {
      return [for (final m in jsonDecode(raw) as List<dynamic>) OutgoingMessage.fromJson(m as Map<String, dynamic>)];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveOutbox(String chatId, List<OutgoingMessage> messages) =>
      messages.isEmpty ? _store.remove('outbox|$chatId') : _store.write('outbox|$chatId', jsonEncode([for (final m in messages) m.toJson()]));
}

/// Сообщение, которое ещё не дошло до сервера («ожидает отправки»).
class OutgoingMessage {
  const OutgoingMessage({required this.localId, required this.text, required this.createdAt});

  final String localId;
  final String text;
  final DateTime createdAt;

  factory OutgoingMessage.fromJson(Map<String, dynamic> json) => OutgoingMessage(
        localId: json['localId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {'localId': localId, 'text': text, 'createdAt': createdAt.toIso8601String()};
}
