import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/city_picking.dart';
import '../../shared/error_feedback.dart';
import '../../shared/status_helpers.dart';
import 'announce_arrival_sheet.dart';

/// Статус водителя вместо анонса (045 п.11, decisions.md 2026-10-08): «Ищу груз
/// из <город>» / «Еду, буду в <город> <день>» / «В рейсе» / «Не ищу». Под
/// капотом — те же анонсы и правила свежести 040, меняется только интерфейс.
enum DriverStatusKind { lookingHere, onTheWay, inTrip, notLooking }

const _tripStatuses = {DealStatus.confirmedByDriver, DealStatus.loaded, DealStatus.inTransit};

DriverStatusKind driverStatusOf(MyArrivals? arrivals, List<Deal>? deals) {
  if (deals != null && deals.any((d) => _tripStatuses.contains(d.status))) return DriverStatusKind.inTrip;
  final current = arrivals?.current;
  if (current == null) return DriverStatusKind.notLooking;
  return current.status == ArrivalStatus.onSite ? DriverStatusKind.lookingHere : DriverStatusKind.onTheWay;
}

/// Строка статуса на главной — тап открывает шторку «Где вы сейчас?».
class DriverStatusBar extends ConsumerWidget {
  const DriverStatusBar({super.key, required this.refData});

  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final arrivals = ref.watch(myArrivalsProvider).valueOrNull;
    final deals = ref.watch(dealsMineProvider).valueOrNull;
    final kind = driverStatusOf(arrivals, deals);
    final current = arrivals?.current;
    final city = current == null ? '' : refData.pointOrNull(current.pointId)?.name.forLanguageCode(locale) ?? '';
    final (label, color, icon) = switch (kind) {
      DriverStatusKind.lookingHere => (t.statusLookingFrom(city), AppColors.success, LucideIcons.radio),
      DriverStatusKind.onTheWay => (t.statusOnTheWay(city, formatDate(current!.plannedDay)), AppColors.primary, LucideIcons.navigation),
      DriverStatusKind.inTrip => (t.statusInTrip, AppColors.accentText, LucideIcons.truck),
      DriverStatusKind.notLooking => (t.statusNotLooking, AppColors.textSecondary, LucideIcons.pauseCircle),
    };
    return AppCard(
      key: const Key('driverStatusBar'),
      onTap: kind == DriverStatusKind.inTrip ? null : () => showWhereNowSheet(context, ref, refData: refData),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, key: Key('driverStatus-${kind.name}'), style: AppTextStyles.bodyStrong.copyWith(color: color))),
          if (kind != DriverStatusKind.inTrip) const Icon(LucideIcons.chevronDown, size: 18),
        ],
      ),
    );
  }
}

/// «Ищу груз из <город>»: анонс на сейчас + «я на месте» одним касанием.
Future<void> lookForCargoFrom(WidgetRef ref, LoadingPoint point) async {
  final driver = ref.read(sessionProvider)?.driver;
  final repo = ref.read(arrivalRepositoryProvider);
  final arrival = await repo.announce(
    pointId: point.id,
    plannedAt: DateTime.now(),
    anyCountry: driver?.anyCountry ?? true,
    countryIds: driver?.directionCountryIds ?? const [],
  );
  await repo.checkIn(arrivalId: arrival.id);
  ref.invalidate(myArrivalsProvider);
  ref.invalidate(arrivalTemplateProvider);
  ref.invalidate(cargoFeedProvider);
}

LoadingPoint? _pointForCity(ReferenceData refData, String? cityId) =>
    cityId == null ? null : refData.points.where((p) => p.cityId == cityId && p.isActive).firstOrNull;

/// Шторка «Где вы сейчас?» (045 п.11): город — текущего статуса, иначе домашний;
/// если по последней геопозиции водитель > 200 км от него — подсказка «Вы теперь в …?».
Future<void> showWhereNowSheet(BuildContext context, WidgetRef ref, {required ReferenceData refData}) async {
  final driver = ref.read(sessionProvider)?.driver;
  final current = ref.read(myArrivalsProvider).valueOrNull?.current;
  var point = current != null ? refData.pointOrNull(current.pointId) : _pointForCity(refData, driver?.homeCityId);
  LoadingPoint? gpsPoint;
  final location = driver?.location;
  if (location != null) {
    final near = nearestPoint(refData.points, location.lat, location.lng, maxKm: 50);
    if (near != null && near.id != point?.id) {
      final far = point?.lat == null || point?.lng == null || haversineKm(location.lat, location.lng, point!.lat!, point.lng!) > 200;
      if (far) gpsPoint = near;
    }
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        final t = sheetContext.l10n;
        final locale = Localizations.localeOf(sheetContext).languageCode;
        final cityName = point?.name.forLanguageCode(locale);

        Future<void> act(Future<void> Function() action) async {
          try {
            await action();
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          } catch (e) {
            if (sheetContext.mounted) showApiError(sheetContext, e, onRetry: () => act(action));
          }
        }

        return SafeArea(top: false, child: SingleChildScrollView(
          key: const Key('whereNowSheet'),
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.whereNowTitle, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.sm),
              if (cityName != null)
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(cityName, style: AppTextStyles.title)),
                  ],
                ),
              if (gpsPoint != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('whereNowGpsHint'),
                  onPressed: () => setSheet(() {
                    point = gpsPoint;
                    gpsPoint = null;
                  }),
                  icon: const Icon(LucideIcons.locateFixed, size: 18),
                  label: Text(t.whereNowGpsHint(gpsPoint!.name.forLanguageCode(locale))),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (point != null)
                PrimaryButton(
                  key: const Key('whereNowLooking'),
                  label: t.statusLookingFrom(cityName!),
                  icon: LucideIcons.radio,
                  onPressed: () => act(() => lookForCargoFrom(ref, point!)),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                key: const Key('whereNowGoing'),
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final result = await showAnnounceArrivalSheet(
                    context,
                    refData: refData,
                    driverAnyCountry: driver?.anyCountry ?? false,
                    driverDirectionCountryIds: driver?.directionCountryIds ?? const [],
                    driverHomeCityId: driver?.homeCityId,
                  );
                  if (result == true) {
                    ref.invalidate(myArrivalsProvider);
                    ref.invalidate(cargoFeedProvider);
                  }
                },
                child: Text(t.whereNowGoing),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('whereNowNotLooking'),
                onPressed: () => act(() async {
                  final arrivals = ref.read(myArrivalsProvider).valueOrNull?.all ?? const [];
                  for (final a in arrivals) {
                    await ref.read(arrivalRepositoryProvider).cancel(arrivalId: a.id);
                  }
                  ref.invalidate(myArrivalsProvider);
                  ref.invalidate(cargoFeedProvider);
                }),
                child: Text(t.whereNowNotLooking),
              ),
              TextButton.icon(
                key: const Key('whereNowOtherCity'),
                onPressed: () async {
                  final picked = await pickCity(sheetContext, ref, refData: refData, selectedId: point?.id);
                  if (picked != null) setSheet(() => point = picked);
                },
                icon: const Icon(LucideIcons.mapPin, size: 16),
                label: Text(t.whereNowOtherCity),
              ),
            ],
          ),
        ));
      },
    ),
  );
}

/// После «Доставлено» (045 п.11): «Вы в <город>. Ищете груз отсюда?» — одним касанием.
Future<void> askLookingFromDestination(BuildContext context, WidgetRef ref, {required ReferenceData refData, required String? destinationCityId}) async {
  final point = _pointForCity(refData, destinationCityId);
  if (point == null) return;
  final t = context.l10n;
  final locale = Localizations.localeOf(context).languageCode;
  final yes = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.deliveredAskTitle(point.name.forLanguageCode(locale))),
      actions: [
        TextButton(key: const Key('deliveredNotLooking'), onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.whereNowNotLooking)),
        FilledButton(
          key: const Key('deliveredLookHere'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t.statusLookingFrom(point.name.forLanguageCode(locale))),
        ),
      ],
    ),
  );
  if (yes == true) {
    try {
      await lookForCargoFrom(ref, point);
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }
}
