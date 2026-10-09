import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../shared/driver_avatar.dart';
import '../../shared/error_feedback.dart';

final _driverCardProvider = FutureProvider.autoDispose.family<DriverCard, String>((ref, id) {
  return ref.watch(driverRepositoryProvider).card(id);
});

/// 057 п.6: логист открыл ссылку водителя (/d/…) — карточка этого водителя,
/// а не общий список: фото, «Проверен», рейтинг, рейсы, анонс, машина; «Написать».
class DriverCardScreen extends ConsumerWidget {
  const DriverCardScreen({super.key, required this.driverId});

  final String driverId;

  Future<void> _chat(BuildContext context, WidgetRef ref) async {
    try {
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(driverId: driverId);
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
    return Scaffold(
      appBar: AppBar(title: Text(t.driverCardTitle)),
      body: card.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(_driverCardProvider(driverId))),
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
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Row(
                children: [
                  DriverAvatar(driverId: d.id, name: d.fullName, version: d.avatarVersion, radius: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.fullName, style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          if (d.isVerified) StatusBadge(label: t.profileVerified, color: StatusBadge.success),
                          Text('★ ${formatRating(d.ratingAvg, d.ratingCount)}', style: AppTextStyles.caption),
                          Text(t.driverCardTrips(d.trips), style: AppTextStyles.caption),
                        ]),
                      ],
                    ),
                  ),
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
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(key: const Key('driverCardChat'), label: t.driverCardChat, icon: LucideIcons.messageCircle, onPressed: () => _chat(context, ref)),
            ],
          );
        },
      ),
    );
  }
}
