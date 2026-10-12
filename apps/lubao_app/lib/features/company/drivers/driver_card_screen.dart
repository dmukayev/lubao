import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../shared/driver_avatar.dart';
import '../../shared/driver_vehicle_photos.dart';
import '../../shared/error_feedback.dart';

final _driverCardProvider = FutureProvider.autoDispose.family<DriverCard, String>((ref, id) {
  return ref.watch(driverRepositoryProvider).card(id);
});

/// 057 п.6: логист открыл ссылку водителя (/d/…) — карточка этого водителя,
/// а не общий список: фото, «Проверен», рейтинг, рейсы, анонс, машина; «Написать».
class DriverCardScreen extends StatelessWidget {
  const DriverCardScreen({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driverCardTitle)),
      body: DriverInfoView(driverId: driverId),
    );
  }
}

/// Нажатие на фото или имя водителя у логиста — шторка с карточкой водителя:
/// крупное фото, «Проверен», рейтинг, рейсы, где ищет груз, машина и её фото.
Future<void> showDriverInfoSheet(BuildContext context, {required String driverId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (sheetContext, controller) => DriverInfoView(driverId: driverId, controller: controller, inSheet: true),
    ),
  );
}

/// Карточка водителя — и экраном (ссылка /d/…), и шторкой по нажатию на водителя.
class DriverInfoView extends ConsumerWidget {
  const DriverInfoView({super.key, required this.driverId, this.controller, this.inSheet = false});

  final String driverId;
  final ScrollController? controller;
  final bool inSheet;

  Future<void> _chat(BuildContext context, WidgetRef ref) async {
    try {
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(driverId: driverId);
      if (!context.mounted) return;
      if (inSheet) Navigator.of(context).pop();
      if (context.mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final card = ref.watch(_driverCardProvider(driverId));
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    return card.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: errorMessage(t, e), onRetry: () => ref.invalidate(_driverCardProvider(driverId))),
      data: (d) {
        final vehicle = [
          if (d.bodyTypeId != null && refData != null) refData.bodyTypeById(d.bodyTypeId!).name.forLanguageCode(locale),
          if (d.capacityTons != null) '${d.capacityTons!.toStringAsFixed(d.capacityTons! % 1 == 0 ? 0 : 1)} ${t.unitTon}',
          if (d.volumeM3 != null) '${d.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
        ].join(' · ');
        final city = d.pointId == null ? null : refData?.pointOrNull(d.pointId!)?.name.forLanguageCode(locale);
        final countries = d.anyCountry || refData == null
            ? t.driverSetupAnyCountry
            : d.countryIds.map((id) => refData.countryById(id).name.forLanguageCode(locale)).join(', ');
        return ListView(
          key: const Key('driverCard'),
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            // Крупное фото — по центру; нет фото — буквы имени.
            Center(child: DriverAvatar(driverId: d.id, name: d.fullName, version: d.avatarVersion, radius: 56)),
            const SizedBox(height: AppSpacing.md),
            Text(d.fullName, key: const Key('driverCardName'), style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (d.isVerified) StatusBadge(label: t.profileVerified, color: StatusBadge.success),
                Text('★ ${formatRating(d.ratingAvg, d.ratingCount)}', style: AppTextStyles.caption),
                Text(t.driverCardTrips(d.trips), style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (vehicle.isNotEmpty)
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(LucideIcons.truck), title: Text(vehicle)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.mapPin),
              title: Text(city == null ? t.driverCardNotLooking : t.statusLookingFrom(city)),
              subtitle: city == null ? null : Text(countries),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(t.driverCardVehiclePhotos, style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            DriverVehiclePhotos(driverId: d.id),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(key: const Key('driverCardChat'), label: t.driverCardChat, icon: LucideIcons.messageCircle, onPressed: () => _chat(context, ref)),
          ],
        );
      },
    );
  }
}
