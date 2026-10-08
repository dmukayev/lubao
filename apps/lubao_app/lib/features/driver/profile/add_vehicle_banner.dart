import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import 'add_vehicle_sheet.dart';

/// «Добавьте машину» (053 п.1, эталон 31): жёлтая плашка, пока в гараже нет ни
/// одной машины — в профиле первым блоком и в пустом гараже. Кузов и тоннаж
/// из регистрации (`preferred*`) — в тексте и уже подставлены в форму.
class AddVehicleBanner extends ConsumerWidget {
  const AddVehicleBanner({super.key, required this.buttonKey});

  final Key buttonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final driver = ref.watch(sessionProvider)?.driver;
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final bodyType = driver?.preferredBodyTypeId == null ? null : refData?.bodyTypes.where((b) => b.id == driver!.preferredBodyTypeId).firstOrNull;
    final tons = driver?.preferredCapacityTons;
    final details = bodyType == null
        ? null
        : !bodyType.isVolume && driver?.preferredSpecs != null
            ? specsSummary(t, locale, bodyType, driver!.preferredSpecs)
            : [bodyType.name.forLanguageCode(locale).toLowerCase(), if (tons != null) '${tons.toStringAsFixed(tons == tons.roundToDouble() ? 0 : 1)} ${t.unitTon}'].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        border: Border.all(color: AppColors.accent, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BodyTypeIcon(bodyTypeCode: bodyType?.code, vehicleKind: bodyType == null ? null : VehicleKind.trailer, width: 72),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.garageEmptyTitle, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details == null || details.isEmpty ? t.profileAddVehiclePlain : t.profileAddVehicleRegistered(details),
                      style: AppTextStyles.body.copyWith(color: AppColors.accentText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            key: buttonKey,
            label: t.garageAddVehicle,
            icon: LucideIcons.plus,
            onPressed: () async {
              final added = await showAddVehicleSheet(context, ref);
              if (added != null) ref.invalidate(garageVehiclesProvider);
            },
          ),
        ],
      ),
    );
  }
}
