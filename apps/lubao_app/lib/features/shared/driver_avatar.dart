import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../services/disk_bytes_cache.dart';
import '../company/drivers/driver_card_screen.dart' show showDriverInfoSheet;

/// 054: миниатюра фото профиля водителя по версии (`?v` меняется при смене —
/// кэш не показывает старое). Нет фото / сбой — null, у вызывающего буквы.
/// 061 п.9: удачное фото держится в памяти (до выхода — там invalidate), сбой —
/// нет: иначе пустой ответ, полученный в момент выхода, оставался бы
/// у следующего вошедшего.
final driverAvatarProvider = FutureProvider.autoDispose.family<Uint8List?, ({String driverId, String version})>((ref, key) async {
  try {
    // 060 п.4: кэш на диске по версии фото (новое фото — новая версия).
    final bytes = await DiskBytesCache.instance.getOrFetch('avatar:${key.driverId}:${key.version}', () => ref.read(driverRepositoryProvider).driverAvatar(key.driverId));
    ref.keepAlive();
    return bytes;
  } catch (_) {
    return null;
  }
});

/// Фото водителя или буквы имени — во всех местах, где логист видит водителя.
class DriverAvatar extends ConsumerWidget {
  const DriverAvatar({super.key, required this.driverId, required this.name, this.version, this.radius = 24, this.fallback, this.openCard = false});

  final String driverId;
  final String name;
  final String? version;
  final double radius;

  /// Своя «буквенная» заглушка экрана (например, цветной кружок в «Кто свободен»).
  final Widget? fallback;

  /// Логист нажал на фото — шторка с карточкой водителя и его фото.
  final bool openCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = version;
    final bytes = v == null ? null : ref.watch(driverAvatarProvider((driverId: driverId, version: v))).valueOrNull;
    final avatar = bytes == null && fallback != null
        ? KeyedSubtree(key: Key('driverAvatar-$driverId-letters'), child: fallback!)
        : PersonAvatar(key: Key('driverAvatar-$driverId-${bytes == null ? 'letters' : 'photo'}'), name: name, bytes: bytes, radius: radius);
    if (!openCard || driverId.isEmpty) return avatar;
    return GestureDetector(key: Key('driverAvatarTap-$driverId'), onTap: () => showDriverInfoSheet(context, driverId: driverId), child: avatar);
  }
}
