import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../shared/pd_consent.dart';
import '../../shared/photo_picker.dart';
import '../../../services/disk_bytes_cache.dart';

/// Своё фото машины с сервера (053 п.5). Ключ — id документа: после
/// «Переснять» id новый, миниатюра перечитывается.
final ownVehiclePhotoProvider = FutureProvider.autoDispose.family<Uint8List, ({String vehicleId, String type, String documentId})>(
  // 060 п.4: кэш на диске — по id документа (новое фото — новый id).
  (ref, key) => DiskBytesCache.instance.getOrFetch('vphoto:${key.documentId}', () => ref.read(driverRepositoryProvider).ownVehiclePhoto(key.vehicleId, key.type)),
);

/// Фото спереди вместо иконки (053 п.4) — в гараже, выборе машины при анонсе,
/// сделке. Нет фото — иконка кузова. Нажатие на фото — крупно.
class VehicleFrontThumb extends ConsumerWidget {
  const VehicleFrontThumb({super.key, required this.vehicle, this.bodyTypeCode, this.width = 56});

  final GarageVehicle vehicle;
  final String? bodyTypeCode;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = vehicle.photoFrontId;
    final icon = BodyTypeIcon(bodyTypeCode: bodyTypeCode, vehicleKind: vehicle.kind, width: width);
    if (id == null) return icon;
    final bytes = ref.watch(ownVehiclePhotoProvider((vehicleId: vehicle.id, type: 'front', documentId: id)));
    return bytes.maybeWhen(
      data: (b) => GestureDetector(
        key: Key('vehicleFrontPhoto-${vehicle.id}'),
        onTap: () => showVehiclePhotoLarge(context, b),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: Image.memory(b, width: width, height: width * 0.75, fit: BoxFit.cover, errorBuilder: (_, _, _) => icon),
        ),
      ),
      orElse: () => icon,
    );
  }
}

Future<void> showVehiclePhotoLarge(BuildContext context, Uint8List bytes) => showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const Key('vehiclePhotoLarge'),
        child: InteractiveViewer(child: Image.memory(bytes)),
      ),
    );

enum _UploadState { idle, uploading, done, failed }

/// Карточка съёмки (053 п.2–3, эталон 31): до съёмки — подсказка в рамке и
/// «Сфотографировать»; сразу после — миниатюра из байтов на телефоне,
/// поверх — загрузка, потом ✓ и «Переснять»; ошибка — «Не отправилось ·
/// Повторить», миниатюра остаётся. Уже есть на сервере — миниатюра оттуда.
class VehiclePhotoCaptureCard extends ConsumerStatefulWidget {
  const VehiclePhotoCaptureCard({
    super.key,
    required this.vehicle,
    required this.angle,
    required this.bodyTypeCode,
    required this.onUploaded,
  });

  final GarageVehicle vehicle;
  final VehiclePhotoAngle angle;
  final String? bodyTypeCode;
  final VoidCallback onUploaded;

  @override
  ConsumerState<VehiclePhotoCaptureCard> createState() => _VehiclePhotoCaptureCardState();
}

class _VehiclePhotoCaptureCardState extends ConsumerState<VehiclePhotoCaptureCard> {
  Uint8List? _local;
  XFile? _picked;
  _UploadState _state = _UploadState.idle;

  VerificationDocType get _type => widget.angle == VehiclePhotoAngle.front ? VerificationDocType.vehiclePhotoFront : VerificationDocType.vehiclePhotoSide;
  String? get _serverId => widget.angle == VehiclePhotoAngle.front ? widget.vehicle.photoFrontId : widget.vehicle.photoSideId;

  Future<void> _take() async {
    if (!await ensurePdConsent(context, ref) || !mounted) return;
    final picked = await pickPhoto(ImageSource.camera);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    // Миниатюра — сразу, не ждём загрузки.
    setState(() {
      _picked = picked;
      _local = bytes;
    });
    await _upload();
  }

  Future<void> _upload() async {
    final picked = _picked, bytes = _local;
    if (picked == null || bytes == null) return;
    setState(() => _state = _UploadState.uploading);
    try {
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
      await ref.read(driverRepositoryProvider).submitVerificationDocument(type: _type, fileUrl: key, vehicleId: widget.vehicle.id);
      if (!mounted) return;
      setState(() => _state = _UploadState.done);
      widget.onUploaded();
    } catch (e) {
      debugPrint('VehiclePhotoCaptureCard: $e');
      if (mounted) setState(() => _state = _UploadState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final front = widget.angle == VehiclePhotoAngle.front;
    final serverId = _serverId;
    Widget? image;
    if (_local != null) {
      image = Image.memory(_local!, fit: BoxFit.cover);
    } else if (serverId != null) {
      image = ref
          .watch(ownVehiclePhotoProvider((vehicleId: widget.vehicle.id, type: front ? 'front' : 'side', documentId: serverId)))
          .maybeWhen(data: (b) => Image.memory(b, fit: BoxFit.cover), orElse: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final hasPhoto = _local != null || serverId != null;
    final done = _state == _UploadState.done || (_local == null && serverId != null);

    return Container(
      key: Key('vehiclePhoto-${_type.name}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(front ? t.vehiclePhotoFrontTitle : t.vehiclePhotoSideTitle, style: AppTextStyles.bodyStrong),
          Text(front ? t.vehiclePhotoFrontHint : t.vehiclePhotoSideHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          if (!hasPhoto)
            VehiclePhotoHint(angle: widget.angle, bodyTypeCode: widget.bodyTypeCode, vehicleKind: widget.vehicle.kind)
          else
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppColors.bg, child: image),
                    if (_state == _UploadState.uploading)
                      Container(
                        key: Key('vehiclePhotoUploading-${_type.name}'),
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    if (done)
                      const Positioned(
                        right: 6,
                        bottom: 6,
                        child: CircleAvatar(radius: 14, backgroundColor: AppColors.success, child: Icon(LucideIcons.check, size: 16, color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (!hasPhoto)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: Key('vehiclePhotoTake-${_type.name}'),
                onPressed: _take,
                icon: const Icon(LucideIcons.camera, size: 18),
                label: Text(t.vehiclePhotoTake),
              ),
            )
          else if (_state == _UploadState.failed)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text(t.vehiclePhotoFailed, key: Key('vehiclePhotoFailed-${_type.name}'), style: AppTextStyles.caption.copyWith(color: StatusBadge.danger)),
                TextButton(key: Key('vehiclePhotoRetry-${_type.name}'), onPressed: _upload, child: Text(t.commonRetry)),
              ],
            )
          else
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                if (done) Text(t.commonDone, key: Key('vehiclePhotoDone-${_type.name}'), style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                TextButton(
                  key: Key('vehiclePhotoRetake-${_type.name}'),
                  onPressed: _state == _UploadState.uploading ? null : _take,
                  child: Text(t.vehiclePhotoRetake),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
