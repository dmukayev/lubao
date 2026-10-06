import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Согласия на использование геопозиции (041, п.11, решение «два уровня»).
/// Это ОТДЕЛЬНО от разового разрешения «📍 в чате»: здесь — то, что работает
/// без нажатия кнопки.
///  - рейс: «На время рейса приложение будет передавать ваше местоположение
///    логисту» (сделка «Загружен»/«В пути»), можно поставить на паузу;
///  - терминал: проверка, не уехал ли водитель из геозоны, чтобы закрыть анонс
///    (координаты логисту не показываются).
/// Без согласия соответствующая отправка координат не запускается.
class TrackingConsentStore {
  TrackingConsentStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _tripKey = 'lubao.consent.tripTracking';
  static const _pausedKey = 'lubao.consent.tripTrackingPaused';
  static const _terminalKey = 'lubao.consent.terminalWatch';

  Future<bool> _read(String key) async => (await _storage.read(key: key)) == '1';
  Future<void> _write(String key, bool value) =>
      value ? _storage.write(key: key, value: '1') : _storage.delete(key: key);

  Future<TrackingConsent> load() async => TrackingConsent(
        trip: await _read(_tripKey),
        tripPaused: await _read(_pausedKey),
        terminal: await _read(_terminalKey),
      );

  Future<void> setTrip(bool granted) => _write(_tripKey, granted);
  Future<void> setTripPaused(bool paused) => _write(_pausedKey, paused);
  Future<void> setTerminal(bool granted) => _write(_terminalKey, granted);

  /// При выходе из аккаунта согласия не переходят к следующему пользователю.
  Future<void> clear() async {
    await _storage.delete(key: _tripKey);
    await _storage.delete(key: _pausedKey);
    await _storage.delete(key: _terminalKey);
  }
}

class TrackingConsent {
  const TrackingConsent({this.trip = false, this.tripPaused = false, this.terminal = false});

  final bool trip;
  final bool tripPaused;
  final bool terminal;

  /// Координаты на время рейса можно слать: согласие есть и не на паузе.
  bool get tripSharingActive => trip && !tripPaused;

  TrackingConsent copyWith({bool? trip, bool? tripPaused, bool? terminal}) =>
      TrackingConsent(trip: trip ?? this.trip, tripPaused: tripPaused ?? this.tripPaused, terminal: terminal ?? this.terminal);
}
