import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../services/disk_bytes_cache.dart';
import 'error_feedback.dart';
import 'fullscreen_photos.dart';

final _photosProvider = FutureProvider.autoDispose.family<List<({String documentId, String type, String? plateNumber})>, String>(
  (ref, driverId) => ref.watch(cargoRepositoryProvider).driverVehiclePhotos(driverId),
);

final _photoFileProvider = FutureProvider.autoDispose.family<Uint8List, (String, String)>(
  // 060 п.4: кэш на диске — по id документа.
  (ref, key) => DiskBytesCache.instance.getOrFetch('vphoto:${key.$2}', () => ref.read(cargoRepositoryProvider).driverVehiclePhotoFile(key.$1, key.$2)),
);

/// Фото машин водителя (044 п.7) — блоком в карточке водителя. Сервер
/// отказал — понятная причина вместо «Ошибка»: водитель компании не виден
/// (нет анонса, отклика, сделки), суточный лимит. 067: нажатие на фото — на
/// весь экран с листанием.
class DriverVehiclePhotos extends ConsumerWidget {
  const DriverVehiclePhotos({super.key, required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final photos = ref.watch(_photosProvider(driverId));
    final muted = AppTextStyles.body.copyWith(color: AppColors.textSecondary);
    return photos.when(
      // 079: без крутилки — блок появится, когда фото пришли.
      loading: () => const SizedBox.shrink(),
      error: (e, st) {
        final response = e is DioException ? e.response : null;
        final code = response?.data is Map ? (response!.data as Map)['code'] : null;
        final text = code == 'COMPANY_NOT_VERIFIED' || (response?.data is Map && '${(response!.data as Map)['message']}'.contains('verified'))
            ? t.vehiclePhotosAfterVerification
            : response?.statusCode == 429
                ? t.contactDailyLimit
                : response?.statusCode == 404
                    ? t.vehiclePhotosNone
                    : errorMessage(t, e);
        return Text(text, key: const Key('driverVehiclePhotosUnavailable'), style: muted);
      },
      data: (list) => list.isEmpty
          ? Text(t.vehiclePhotosNone, key: const Key('driverVehiclePhotosNone'), style: muted)
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (index, p) in list.indexed)
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          key: Key('driverVehiclePhoto-${p.documentId}'),
                          onTap: () => showFullScreenPhotos(
                            context,
                            initialIndex: index,
                            photos: [
                              for (final photo in list)
                                Consumer(
                                  builder: (context, ref, _) => ref.watch(_photoFileProvider((driverId, photo.documentId))).when(
                                        loading: () => const SizedBox.shrink(),
                                        error: (e, st) => const Icon(LucideIcons.imageOff, color: Colors.white),
                                        data: (bytes) => Image.memory(bytes, fit: BoxFit.contain),
                                      ),
                                ),
                            ],
                          ),
                          child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          child: SizedBox(
                            width: 150,
                            height: 100,
                            child: ref.watch(_photoFileProvider((driverId, p.documentId))).when(
                                  // 079: пока грузится — фон плитки, без индикатора.
                                  loading: () => const ColoredBox(color: AppColors.divider),
                                  error: (e, st) => const Icon(LucideIcons.imageOff),
                                  data: (bytes) => Image.memory(bytes, fit: BoxFit.cover, cacheWidth: (150 * MediaQuery.devicePixelRatioOf(context)).round()),
                                ),
                          ),
                        ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [p.type == 'VEHICLE_PHOTO_FRONT' ? t.vehiclePhotoFront : t.vehiclePhotoSide, if (p.plateNumber != null) p.plateNumber!].join(' · '),
                          style: AppTextStyles.caption,
                          // 076: одной строкой с многоточием, не узким столбиком.
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
