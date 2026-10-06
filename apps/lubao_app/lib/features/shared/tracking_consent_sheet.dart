import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/tracking_provider.dart';

/// Шторка согласия на геопозицию «на время рейса» (041, п.11): показывается
/// при переходе сделки в «Загружен». Это отдельное согласие, не то же самое,
/// что разовое «📍 в чате» («один раз, без слежки»). Возвращает `true`, если
/// согласие есть (уже было или только что дано кнопкой «Понятно»); закрыли
/// шторку — согласия нет, сделка при этом всё равно двигается, а репортер
/// координаты не шлёт.
Future<bool> ensureTripTrackingConsent(BuildContext context, WidgetRef ref) async {
  if (ref.read(trackingConsentProvider).trip) return true;
  final t = context.l10n;
  final granted = await _showConsentSheet(
    context,
    key: const Key('tripTrackingConsentSheet'),
    icon: LucideIcons.navigation,
    title: t.tripTrackingConsentTitle,
    body: t.tripTrackingConsentBody,
  );
  if (granted != true) return false;
  await ref.read(trackingConsentProvider.notifier).grantTrip();
  await ref.read(osLocationPermissionRequestProvider)();
  return true;
}

/// Согласие на проверку отъезда с терминала («Я на месте» в городе-терминале,
/// 040, п.4): координаты нужны, чтобы закрыть анонс, логисту они не уходят.
Future<bool> ensureTerminalWatchConsent(BuildContext context, WidgetRef ref) async {
  if (ref.read(trackingConsentProvider).terminal) return true;
  final t = context.l10n;
  final granted = await _showConsentSheet(
    context,
    key: const Key('terminalWatchConsentSheet'),
    icon: LucideIcons.mapPin,
    title: t.terminalWatchConsentTitle,
    body: t.terminalWatchConsentBody,
  );
  if (granted != true) return false;
  await ref.read(trackingConsentProvider.notifier).grantTerminal();
  await ref.read(osLocationPermissionRequestProvider)();
  return true;
}

Future<bool?> _showConsentSheet(
  BuildContext context, {
  required Key key,
  required IconData icon,
  required String title,
  required String body,
}) {
  final t = context.l10n;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (sheetContext) => Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppTextStyles.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(body, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            key: const Key('consentUnderstoodButton'),
            label: t.consentUnderstood,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
        ],
      ),
    ),
  );
}

/// Переключатель «Передавать местоположение логисту» в карточке сделки —
/// на время рейса (Загружен/В пути): пауза без отмены согласия (041, п.11).
class TripTrackingSwitch extends ConsumerWidget {
  const TripTrackingSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final consent = ref.watch(trackingConsentProvider);
    return SwitchListTile(
      key: const Key('tripTrackingSwitch'),
      contentPadding: EdgeInsets.zero,
      title: Text(t.tripTrackingSwitchTitle),
      subtitle: Text(consent.tripSharingActive ? t.tripTrackingSwitchOn : t.tripTrackingSwitchPaused),
      value: consent.tripSharingActive,
      onChanged: (on) async {
        if (!on) {
          await ref.read(trackingConsentProvider.notifier).setTripPaused(true);
        } else if (!consent.trip) {
          await ensureTripTrackingConsent(context, ref);
        } else {
          await ref.read(trackingConsentProvider.notifier).setTripPaused(false);
        }
      },
    );
  }
}
