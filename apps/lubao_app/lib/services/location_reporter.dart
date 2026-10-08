import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../providers/tracking_provider.dart';

/// Отправляет координаты водителя на бэкенд, пока приложение открыто и
/// пользователь залогинен как водитель. Фоновый трекинг (экран заблокирован)
/// не реализован — это отдельная задача (Always-разрешение, foreground-service
/// на Android, согласование в App Store).
///
/// Когда шлёт (041, п.11, «два уровня»): только по отдельному согласию и
/// только в двух случаях — сделка «Загружен»/«В пути» (согласие на рейс, можно
/// поставить на паузу) и «на месте» в терминале (согласие на проверку
/// отъезда). Разовое разрешение «📍 в чате» сюда не относится.
///
/// Состояние сделок не опрашивается каждые 45 секунд (041, п.13): список
/// обновляется при старте, по событию `deal:updated` из личной комнаты
/// пользователя и редким запасным опросом раз в 10 минут (на случай, если
/// сокет не подключён).
class LocationReporter {
  LocationReporter(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next?.user.role == UserRole.driver) {
        _start();
      } else {
        _stop();
      }
    }, fireImmediately: true);
    // Согласие дали/сняли паузу — реагируем сразу, не дожидаясь тика.
    _ref.listen<TrackingConsent>(trackingConsentProvider, (previous, next) {
      if (_timer != null) _tick();
    });
  }

  final Ref _ref;
  Timer? _timer;
  Timer? _fallbackRefresh;
  StreamSubscription<Map<String, dynamic>>? _dealSub;
  ProviderSubscription<AsyncValue<MyArrivals>>? _arrivalsSub;
  bool _hasTrackedDeal = false;
  bool _onSiteAtTerminal = false;

  void _start() {
    _stop();
    _refreshDeals();
    _dealSub = _ref.read(realtimeServiceProvider).onDealUpdated.listen((_) => _refreshDeals());
    // Анонс сменился (приехал на терминал / уехал) — пересчитываем; только
    // у водителя, у логиста /arrivals/me недоступен.
    _arrivalsSub = _ref.listen<AsyncValue<MyArrivals>>(myArrivalsProvider, (previous, next) {
      _onSiteAtTerminal = _computeOnSiteAtTerminal(next.valueOrNull);
    });
    _fallbackRefresh = Timer.periodic(const Duration(minutes: 10), (_) => _refreshDeals());
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _fallbackRefresh?.cancel();
    _dealSub?.cancel();
    _arrivalsSub?.close();
    _arrivalsSub = null;
    _timer = null;
    _fallbackRefresh = null;
    _dealSub = null;
    _hasTrackedDeal = false;
    _onSiteAtTerminal = false;
  }

  Future<void> _refreshDeals() async {
    try {
      final deals = await _ref.read(dealRepositoryProvider).mine();
      final was = _hasTrackedDeal;
      // 046: пока решается отмена «в пути», груз всё ещё в машине — трекинг идёт.
      _hasTrackedDeal = deals.any((d) => const {DealStatus.loaded, DealStatus.inTransit, DealStatus.cancelRequested, DealStatus.disputed}.contains(d.status));
      if (_hasTrackedDeal && !was) _tick();
    } catch (e) {
      // best-effort: сеть пропала — оставляем прежнее состояние до следующего обновления
      debugPrint('LocationReporter: deals refresh failed: $e');
    }
  }

  /// Геозона терминала (040, п.4): «на месте» в терминале — сервер сам закроет
  /// анонс, когда водитель выйдет за радиус. В обычном городе — не нужно.
  bool _computeOnSiteAtTerminal(MyArrivals? mine) {
    final current = mine?.current;
    if (current == null || current.status != ArrivalStatus.onSite) return false;
    final refData = _ref.read(referenceDataProvider).valueOrNull;
    return refData?.pointOrNull(current.pointId)?.kind == PointKind.terminal;
  }

  Future<void> _tick() async {
    try {
      final consent = _ref.read(trackingConsentProvider);
      if (!shouldSendLocation(consent: consent, hasTrackedDeal: _hasTrackedDeal, onSiteAtTerminal: _onSiteAtTerminal)) return;
      // Разрешение ОС здесь НЕ запрашиваем: его просят в шторке согласия
      // (рейс/терминал) или по «📍» в чате; нет разрешения — просто не шлём.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      await _ref.read(driverRepositoryProvider).updateLocation(lat: position.latitude, lng: position.longitude);
    } catch (e) {
      // best-effort: GPS выключен/сеть недоступна — пробуем в следующий тик
      debugPrint('LocationReporter: tick failed: $e');
    }
  }

  void dispose() => _stop();
}

final locationReporterProvider = Provider<LocationReporter>((ref) {
  final reporter = LocationReporter(ref);
  ref.onDispose(reporter.dispose);
  return reporter;
});
