import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';

final _photosProvider = FutureProvider.autoDispose.family<List<({String documentId, String type, String? plateNumber})>, String>(
  (ref, driverId) => ref.watch(cargoRepositoryProvider).driverVehiclePhotos(driverId),
);

final _photoFileProvider = FutureProvider.autoDispose.family<Uint8List, (String, String)>(
  (ref, key) => ref.watch(cargoRepositoryProvider).driverVehiclePhotoFile(key.$1, key.$2),
);

/// Фото машины водителя у логиста (044 п.7): «Кто свободен», отклик. Нет фото —
/// «Фото нет»; для сделки фото не обязательны.
Future<void> showDriverVehiclePhotos(BuildContext context, {required String driverId, required String driverName}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => SafeArea(top: false, child: _PhotosSheet(driverId: driverId, driverName: driverName)),
  );
}

class _PhotosSheet extends ConsumerWidget {
  const _PhotosSheet({required this.driverId, required this.driverName});
  final String driverId;
  final String driverName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final photos = ref.watch(_photosProvider(driverId));
    return Padding(
      key: const Key('driverVehiclePhotosSheet'),
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(driverName, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          photos.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text(t.commonError),
            data: (list) => list.isEmpty
                ? Text(t.vehiclePhotosNone, key: const Key('driverVehiclePhotosNone'), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final p in list)
                        SizedBox(
                          width: 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.field),
                                child: SizedBox(
                                  width: 150,
                                  height: 100,
                                  child: ref.watch(_photoFileProvider((driverId, p.documentId))).when(
                                        loading: () => const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                                        error: (e, st) => const Icon(LucideIcons.imageOff),
                                        data: (bytes) => Image.memory(bytes, fit: BoxFit.cover),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [p.type == 'VEHICLE_PHOTO_FRONT' ? t.vehiclePhotoFront : t.vehiclePhotoSide, if (p.plateNumber != null) p.plateNumber!].join(' · '),
                                style: AppTextStyles.caption,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
