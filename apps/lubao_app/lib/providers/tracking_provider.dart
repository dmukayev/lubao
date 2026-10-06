import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';

final trackingConsentStoreProvider = Provider((ref) => TrackingConsentStore());

/// Согласия на геопозицию (041, п.11): рейс, пауза рейса, проверка отъезда с
/// терминала. Хранятся на устройстве, при выходе из аккаунта сбрасываются.
class TrackingConsentController extends StateNotifier<TrackingConsent> {
  TrackingConsentController(this._store) : super(const TrackingConsent()) {
    _load();
  }

  final TrackingConsentStore _store;

  Future<void> _load() async {
    final loaded = await _store.load();
    if (mounted) state = loaded;
  }

  Future<void> grantTrip() async {
    await _store.setTrip(true);
    await _store.setTripPaused(false);
    state = state.copyWith(trip: true, tripPaused: false);
  }

  Future<void> setTripPaused(bool paused) async {
    await _store.setTripPaused(paused);
    state = state.copyWith(tripPaused: paused);
  }

  Future<void> grantTerminal() async {
    await _store.setTerminal(true);
    state = state.copyWith(terminal: true);
  }

  Future<void> reset() async {
    await _store.clear();
    if (mounted) state = const TrackingConsent();
  }
}

final trackingConsentProvider = StateNotifierProvider<TrackingConsentController, TrackingConsent>(
  (ref) => TrackingConsentController(ref.watch(trackingConsentStoreProvider)),
);

/// Можно ли сейчас слать координаты на сервер (решение «два уровня» + согласия):
///  - рейс: есть сделка «Загружен»/«В пути», дано согласие на рейс и оно не на паузе;
///  - терминал: водитель «на месте» в терминале и дал согласие на проверку отъезда.
/// Без соответствующего согласия отправка не запускается.
bool shouldSendLocation({
  required TrackingConsent consent,
  required bool hasTrackedDeal,
  required bool onSiteAtTerminal,
}) {
  if (hasTrackedDeal && consent.tripSharingActive) return true;
  if (onSiteAtTerminal && consent.terminal) return true;
  return false;
}

/// Системный запрос разрешения на геолокацию — после нашей шторки с
/// объяснением. Вынесен в провайдер, чтобы сквозные сценарии не упирались в
/// системный диалог ОС (его робот нажать не может). Отказ в системе действие
/// не ломает: координаты просто не уйдут.
final osLocationPermissionRequestProvider = Provider<Future<void> Function()>((ref) => () async {
      try {
        if (await Geolocator.checkPermission() == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      } catch (e) {
        debugPrint('TrackingConsent: permission request failed: $e');
      }
    });
