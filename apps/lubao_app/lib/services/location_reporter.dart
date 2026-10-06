import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';

/// Отправляет текущие координаты водителя на бэкенд, пока приложение открыто
/// и пользователь залогинен как водитель. Фоновый трекинг (когда экран
/// заблокирован) не реализован — это отдельная задача (Always-разрешение,
/// foreground-service на Android, доп. согласование в App Store).
class LocationReporter {
  LocationReporter(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next?.user.role == UserRole.driver) {
        _start();
      } else {
        _stop();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  Timer? _timer;

  void _start() {
    _stop();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Решение «два уровня» (008): координаты уходят только пока у водителя
  /// есть активная сделка в статусе «Загружен»/«В пути» (и, 040, пока он «на
  /// месте» в терминале с геозоной); иначе трекинга нет.
  Future<bool> _hasTrackedDeal() async {
    final deals = await _ref.read(dealRepositoryProvider).mine();
    return deals.any((d) => d.status == DealStatus.loaded || d.status == DealStatus.inTransit);
  }

  /// Геозона терминала (040, п.4): водитель «на месте» в городе-терминале —
  /// сервер сам закроет анонс, когда он выйдет за радиус; для этого нужны
  /// координаты. В обычном городе («на месте» по нажатию) трекинга нет.
  Future<bool> _isOnSiteAtTerminal() async {
    final current = (await _ref.read(arrivalRepositoryProvider).mine()).current;
    if (current == null || current.status != ArrivalStatus.onSite) return false;
    final refData = _ref.read(referenceDataProvider).valueOrNull;
    return refData?.pointOrNull(current.pointId)?.kind == PointKind.terminal;
  }

  Future<void> _tick() async {
    try {
      if (!await _hasTrackedDeal() && !await _isOnSiteAtTerminal()) return;
      // Разрешение здесь НЕ запрашиваем (041, п.8): его просят с объяснением
      // в момент первого осознанного действия (📍 в чате); нет разрешения —
      // просто не шлём.
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
