import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';

import 'location_permission.dart';

final recentPointsStoreProvider = Provider((ref) => RecentPointsStore());

/// Общий выбор города для анонса, груза и «Кто свободен» (задача 040, п.2):
/// поиск, недавние, «рядом со мной» по геолокации. Выбранный город
/// запоминается в «недавних».
Future<LoadingPoint?> pickCity(
  BuildContext context,
  WidgetRef ref, {
  required ReferenceData refData,
  String? selectedId,
  String? title,
}) async {
  final store = ref.read(recentPointsStoreProvider);
  final recent = await store.load();
  if (!context.mounted) return null;
  final picked = await showCityPicker(
    context,
    points: refData.points,
    selectedId: selectedId,
    recentIds: recent,
    title: title,
    onFindNearby: () async {
      final position = await currentPositionWithRationale(context, accuracy: LocationAccuracy.low);
      if (position == null) return null;
      return nearestPoint(refData.points, position.latitude, position.longitude);
    },
  );
  if (picked != null) await store.remember(picked.id);
  return picked;
}
