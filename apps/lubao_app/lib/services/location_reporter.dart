import 'dart:async';

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

  Future<void> _tick() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      await _ref.read(driverRepositoryProvider).updateLocation(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // best-effort: нет разрешения/GPS выключен/сеть недоступна — просто пробуем в следующий тик
    }
  }

  void dispose() => _stop();
}

final locationReporterProvider = Provider<LocationReporter>((ref) {
  final reporter = LocationReporter(ref);
  ref.onDispose(reporter.dispose);
  return reporter;
});
