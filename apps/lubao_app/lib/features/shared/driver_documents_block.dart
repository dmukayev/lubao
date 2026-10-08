import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/api_providers.dart';
import 'status_helpers.dart';

final _packageProvider = FutureProvider.autoDispose.family<DriverDocumentsPackage, String>(
  (ref, dealId) => ref.watch(dealRepositoryProvider).driverDocuments(dealId),
);

final _fileProvider = FutureProvider.autoDispose.family<Uint8List, (String, String)>(
  (ref, key) => ref.watch(dealRepositoryProvider).driverDocumentFile(key.$1, key.$2),
);

const _docsOpenStatuses = {DealStatus.confirmedByDriver, DealStatus.loaded, DealStatus.inTransit, DealStatus.delivered};

/// «Документы водителя» в карточке сделки логиста (044 п.2): после «Подтверждаю
/// перевозку» — ФИО, ИИН, права, машины, превью и «Скачать PDF»; до — «Откроются
/// после подтверждения водителем». Каждое открытие пишет сервер (audit_log).
class DriverDocumentsBlock extends ConsumerWidget {
  const DriverDocumentsBlock({super.key, required this.deal});

  final Deal deal;

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    try {
      final link = await ref.read(dealRepositoryProvider).driverDocumentsPdfLink(deal.id);
      await launchUrl(link, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('DriverDocumentsBlock: pdf: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    if (!_docsOpenStatuses.contains(deal.status)) {
      return _Shell(child: Text(t.driverDocsLocked, key: const Key('driverDocsLocked'), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)));
    }
    final pkg = ref.watch(_packageProvider(deal.id));
    return _Shell(
      child: pkg.when(
        loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: Center(child: CircularProgressIndicator())),
        error: (e, st) {
          final expired = e is DioException && (e.response?.data is Map) && (e.response!.data as Map)['code'] == 'DOCS_EXPIRED';
          return Text(expired ? t.driverDocsExpired : t.commonError, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary));
        },
        data: (p) => Column(
          key: const Key('driverDocsPackage'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.fullName, style: AppTextStyles.bodyStrong),
            if (p.iin != null) Text('${t.driverDocsIin}: ${p.iin}', style: AppTextStyles.body),
            if (p.licenseNumber != null)
              Text(
                '${t.driverDocsLicense}: ${p.licenseNumber}${p.licenseExpiry != null ? ' · ${p.licenseExpiry}' : ''}',
                style: AppTextStyles.body,
              ),
            for (final v in p.vehicles) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                [v.plateNumber ?? t.garageNoPlate, if (v.brand != null) v.brand!, if (v.vin != null) 'VIN ${v.vin}'].join(' · '),
                style: AppTextStyles.bodyStrong,
              ),
              if (!v.isVerified) StatusBadge(label: t.driverDocsVehiclePending, color: StatusBadge.warning),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (label, doc) in [
                    (t.driverDocsSelfie, p.selfie),
                    (t.driverDocsLicense, p.license),
                    for (final v in p.vehicles) ...[
                      (t.driverDocsPassport, v.passport),
                      (t.vehiclePhotoFront, v.photoFront),
                      (t.vehiclePhotoSide, v.photoSide),
                    ],
                  ])
                    _Thumb(dealId: deal.id, label: label, doc: doc),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('driverDocsDownloadPdf'),
              label: t.driverDocsDownloadPdf,
              icon: LucideIcons.download,
              onPressed: () => _downloadPdf(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.driverDocsTitle, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        AppCard(key: const Key('driverDocsBlock'), child: SizedBox(width: double.infinity, child: child)),
      ],
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.dealId, required this.label, required this.doc});
  final String dealId;
  final String label;
  final DriverDocRef? doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ref0 = doc;
    final Widget image = ref0 == null
        ? Center(child: Text(context.l10n.vehiclePhotosNone, style: AppTextStyles.caption, textAlign: TextAlign.center))
        : ref.watch(_fileProvider((dealId, ref0.id))).when(
              loading: () => const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, st) => const Icon(LucideIcons.imageOff),
              data: (bytes) => Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (context, e, st) => const Icon(LucideIcons.imageOff)),
            );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: ref0 == null ? null : () => _open(context, ref, ref0.id),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  child: Container(color: AppColors.bg, width: 96, child: image),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, String id) {
    final bytes = ref.read(_fileProvider((dealId, id))).valueOrNull;
    if (bytes == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(child: InteractiveViewer(child: Image.memory(bytes))),
    );
  }
}

/// Водителю: «Логист открыл документы <когда>» + список открытий по тапу (044 п.4).
class DriverDocsOpenedRow extends ConsumerWidget {
  const DriverDocsOpenedRow({super.key, required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final at = deal.driverDocsOpenedAt;
    if (at == null) return const SizedBox.shrink();
    return InkWell(
      key: const Key('driverDocsOpened'),
      onTap: () async {
        final log = await ref.read(dealRepositoryProvider).driverDocumentsAccessLog(deal.id);
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(t.dealDocsAccessTitle, style: AppTextStyles.title),
              for (final row in log)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(row.downloaded ? LucideIcons.download : LucideIcons.eye),
                  title: Text(row.by ?? '—'),
                  trailing: Text(formatDateTime(row.at), style: AppTextStyles.caption),
                ),
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            const Icon(LucideIcons.eye, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(t.dealDocsOpenedAt(formatDateTime(at)), style: AppTextStyles.body)),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}
