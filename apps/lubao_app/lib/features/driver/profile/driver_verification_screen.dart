import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';

const _requiredDocs = [
  VerificationDocType.selfie,
  VerificationDocType.vehiclePassport,
  VerificationDocType.trailerPassport,
  VerificationDocType.driverLicense,
];

class DriverVerificationScreen extends ConsumerWidget {
  const DriverVerificationScreen({super.key});

  String _label(BuildContext context, VerificationDocType type) {
    final t = context.l10n;
    return switch (type) {
      VerificationDocType.selfie => t.driverVerificationSelfie,
      VerificationDocType.vehiclePassport => t.driverVerificationVehiclePassport,
      VerificationDocType.trailerPassport => t.driverVerificationTrailerPassport,
      VerificationDocType.driverLicense => t.driverVerificationLicense,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final docsAsync = ref.watch(driverVerificationDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.driverVerificationTitle)),
      body: docsAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DriverVerificationScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(driverVerificationDocumentsProvider));
        },
        data: (docs) {
          final byType = {for (final d in docs) d.type: d};
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(t.driverVerificationIntro, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              for (final type in _requiredDocs) ...[
                _DocSlot(type: type, label: _label(context, type), doc: byType[type]),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DocSlot extends ConsumerStatefulWidget {
  const _DocSlot({required this.type, required this.label, required this.doc});

  final VerificationDocType type;
  final String label;
  final VerificationDocument? doc;

  @override
  ConsumerState<_DocSlot> createState() => _DocSlotState();
}

class _DocSlotState extends ConsumerState<_DocSlot> {
  bool _uploading = false;

  bool get _locked => widget.doc?.status == VerificationDocStatus.approved;

  Future<void> _pick(ImageSource source) async {
    if (_locked) return;
    final t = context.l10n;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final key = await ref.read(uploadsRepositoryProvider).uploadDocument(bytes, filename: picked.name);
      await ref.read(driverRepositoryProvider).submitVerificationDocument(type: widget.type, fileUrl: key);
      ref.invalidate(driverVerificationDocumentsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driverVerificationUploadFailed)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final doc = widget.doc;

    final (statusLabel, statusColor, statusIcon) = switch (doc?.status) {
      VerificationDocStatus.approved => (t.driverVerificationStatusApproved, AppColors.success, LucideIcons.checkCircle2),
      VerificationDocStatus.pending => (t.driverVerificationStatusPending, AppColors.accentText, LucideIcons.clock),
      VerificationDocStatus.rejected => (t.driverVerificationStatusRejected, AppColors.error, LucideIcons.xCircle),
      null => (t.driverVerificationStatusNone, AppColors.textSecondary, LucideIcons.circle),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (doc != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  child: Image.network(doc.fileUrl, width: 48, height: 48, fit: BoxFit.cover),
                ),
              if (doc != null) const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(widget.label, style: AppTextStyles.bodyStrong)),
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: AppSpacing.xs),
              Text(statusLabel, style: AppTextStyles.caption.copyWith(color: statusColor)),
            ],
          ),
          if (doc?.status == VerificationDocStatus.rejected && doc?.rejectReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(doc!.rejectReason!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ],
          if (!_locked) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(LucideIcons.camera),
                    label: Text(t.postCargoAddPhotoCamera),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(LucideIcons.image),
                    label: Text(t.postCargoAddPhotoGallery),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
