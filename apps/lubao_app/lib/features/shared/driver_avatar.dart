import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../services/disk_bytes_cache.dart';

/// 054: миниатюра фото профиля водителя по версии (`?v` меняется при смене —
/// кэш не показывает старое). Нет фото / сбой — null, у вызывающего буквы.
final driverAvatarProvider = FutureProvider.family<Uint8List?, ({String driverId, String version})>((ref, key) async {
  try {
    // 060 п.4: кэш на диске по версии фото (новое фото — новая версия).
    return await DiskBytesCache.instance.getOrFetch('avatar:${key.driverId}:${key.version}', () => ref.read(driverRepositoryProvider).driverAvatar(key.driverId));
  } catch (_) {
    return null;
  }
});

/// Фото водителя или буквы имени — во всех местах, где логист видит водителя.
class DriverAvatar extends ConsumerWidget {
  const DriverAvatar({super.key, required this.driverId, required this.name, this.version, this.radius = 24, this.fallback});

  final String driverId;
  final String name;
  final String? version;
  final double radius;

  /// Своя «буквенная» заглушка экрана (например, цветной кружок в «Кто свободен»).
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = version;
    final bytes = v == null ? null : ref.watch(driverAvatarProvider((driverId: driverId, version: v))).valueOrNull;
    if (bytes == null && fallback != null) return KeyedSubtree(key: Key('driverAvatar-$driverId-letters'), child: fallback!);
    return PersonAvatar(key: Key('driverAvatar-$driverId-${bytes == null ? 'letters' : 'photo'}'), name: name, bytes: bytes, radius: radius);
  }
}
