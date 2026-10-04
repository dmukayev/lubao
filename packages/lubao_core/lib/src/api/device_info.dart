import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Простая метка устройства для списка «Мои устройства» — без доп.
/// пакетов (device_info_plus) достаточно, чтобы отличить одно устройство
/// от другого в списке сессий.
class DeviceInfo {
  const DeviceInfo({required this.name, required this.platform});

  final String name;
  final String platform;

  static DeviceInfo current() {
    if (kIsWeb) return const DeviceInfo(name: 'Web', platform: 'web');
    final platform = Platform.operatingSystem;
    return DeviceInfo(name: platform, platform: platform);
  }
}
