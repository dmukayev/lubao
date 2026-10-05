import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pending_contact_event.dart';

/// Очередь контакт-событий, не отправленных из-за отсутствия сети (задача
/// 029, п.14): `CargoRepository.logContactEvent` раньше был «выстрелил и
/// забыл» (`unawaited`, без try/catch) — на границе, где связи часто нет,
/// звонок/WhatsApp просто терялся навсегда, хотя сам звонок состоялся.
/// Теперь неудачная попытка попадает сюда и досылается при следующем
/// восстановлении соединения (см. `RealtimeConnector`), а не пропадает.
///
/// Хранилище — тот же `flutter_secure_storage`, что у токенов
/// ([TokenStorage]): он уже есть как зависимость, переживает перезапуск
/// приложения, и конструктор принимает инстанс для подмены в тестах по
/// тому же паттерну.
class ContactEventQueue {
  ContactEventQueue({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'lubao.pendingContactEvents';

  Future<List<PendingContactEvent>> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PendingContactEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _save(List<PendingContactEvent> events) async {
    if (events.isEmpty) {
      await _storage.delete(key: _key);
      return;
    }
    await _storage.write(key: _key, value: jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  Future<void> enqueue(PendingContactEvent event) async {
    final events = await _load();
    events.add(event);
    await _save(events);
  }

  /// Пробует отправить каждое накопленное событие через [send]; те, что
  /// снова не прошли (всё ещё нет сети), остаются в очереди для
  /// следующей попытки. Порядок между событиями не важен — это
  /// независимые записи contact_event, не сообщения в чате.
  Future<void> flush(Future<void> Function(PendingContactEvent) send) async {
    final events = await _load();
    if (events.isEmpty) return;
    final remaining = <PendingContactEvent>[];
    for (final event in events) {
      try {
        await send(event);
      } catch (_) {
        remaining.add(event);
      }
    }
    await _save(remaining);
  }
}
