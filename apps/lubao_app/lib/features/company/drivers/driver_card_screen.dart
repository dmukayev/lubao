import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/fullscreen_photos.dart';
import '../../shared/status_helpers.dart';
import '../../shared/driver_avatar.dart';
import '../../shared/driver_vehicle_photos.dart';
import '../../shared/error_feedback.dart';

/// 078: открытая карточка водителя хранится сутки — повторно открывается сразу.
final _driverCardProvider = StreamProvider.autoDispose.family<DriverCard, String>((ref, id) {
  return cacheFirst(ref.watch(apiClientProvider), '/drivers/$id/card',
      parse: (d) => DriverCard.fromJson(d as Map<String, dynamic>), fetch: () => ref.watch(driverRepositoryProvider).card(id));
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

/// Нажатие на строку, фото или имя водителя у логиста (067) — шторка с полной
/// карточкой. Закрыть: свайп вниз, затемнение, «Назад» и ✕ в углу (не уезжает
/// при прокрутке). `onSelect` — в откликах кнопка «Выбрать» внизу шторки.
Future<void> showDriverInfoSheet(BuildContext context, {required String driverId, String? cargoId, String? selectLabel, VoidCallback? onSelect}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    // Поверх нижних вкладок: иначе панель закрывала кнопки внизу шторки.
    useRootNavigator: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (sheetContext, controller) => Stack(
        children: [
          DriverInfoView(driverId: driverId, controller: controller, inSheet: true, cargoId: cargoId, selectLabel: selectLabel, onSelect: onSelect),
          Positioned(
            top: 0,
            right: AppSpacing.sm,
            child: IconButton(
              key: const Key('driverCardClose'),
              tooltip: sheetContext.l10n.driverCardClose,
              style: IconButton.styleFrom(backgroundColor: AppColors.bg),
              icon: const Icon(LucideIcons.x),
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Карточка водителя — и экраном (ссылка /d/…), и шторкой по нажатию на водителя.
/// 067: фото крупно (на весь экран), статус, машина и допуски, отмены, фото
/// машины, отзывы; внизу «Позвонить», WhatsApp, «Написать» (в откликах —
/// «Выбрать»). Видна и непроверенной компании (066). Документов здесь нет —
/// только при обоюдной сделке (044).
class DriverInfoView extends ConsumerWidget {
  const DriverInfoView({super.key, required this.driverId, this.controller, this.inSheet = false, this.cargoId, this.selectLabel, this.onSelect});

  final String driverId;
  final ScrollController? controller;
  final bool inSheet;
  final String? cargoId;
  final String? selectLabel;
  final VoidCallback? onSelect;

  Future<void> _chat(BuildContext context, WidgetRef ref) async {
    try {
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(driverId: driverId, cargoId: cargoId);
      if (!context.mounted) return;
      if (inSheet) Navigator.of(context).pop();
      if (context.mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }

  /// Номер — по нажатию (043 п.11): сервер пишет contact_event и считает лимит.
  Future<void> _contact(BuildContext context, WidgetRef ref, String type) async {
    try {
      final phone = await ref.read(cargoRepositoryProvider).revealDriverContact(driverId, type: type, cargoId: cargoId);
      if (type == 'CALL') {
        await launchUrl(Uri(scheme: 'tel', path: phone));
      } else {
        await launchUrl(Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}'), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(contactErrorText(context.l10n, e))));
    }
  }

  void _openAvatar(BuildContext context, DriverCard d) {
    final version = d.avatarVersion;
    if (version == null) return;
    showFullScreenPhotos(context, photos: [
      Consumer(
        builder: (context, ref, _) => switch (ref.watch(driverAvatarProvider((driverId: d.id, version: version))).valueOrNull) {
          final bytes? => Image.memory(bytes, fit: BoxFit.contain),
          null => const CircularProgressIndicator(),
        },
      ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final card = ref.watch(_driverCardProvider(driverId));
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final companyCountryId = ref.watch(sessionProvider)?.company?.countryId;
    final isChinaCompany = refData?.countries.where((c) => c.id == companyCountryId).firstOrNull?.code == 'CN';
    return card.when(
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: errorMessage(t, e), onRetry: () => ref.invalidate(_driverCardProvider(driverId))),
      data: (d) {
        // Неразрывный пробел: «20 т» не разрывается на две строки.
        String tons(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}\u00A0${t.unitTon}';
        String? bodyName(String? id) => id == null || refData == null ? null : refData.bodyTypeById(id).name.forLanguageCode(locale);
        // Связка тягач + прицеп; старый сервер без связки — одна строка, как раньше.
        final vehicleLines = d.vehicles.isNotEmpty
            ? [
                for (final v in d.vehicles)
                  [
                    switch (v.kind) { 'TRACTOR' => t.garageKindTractor, 'TRAILER' => t.garageKindTrailer, _ => t.driverCardRigid },
                    if (v.brand != null && v.brand!.isNotEmpty) v.brand!,
                    ?bodyName(v.bodyTypeId),
                    if (v.capacityTons != null) tons(v.capacityTons!),
                    if (v.volumeM3 != null) '${v.volumeM3!.toStringAsFixed(0)}\u00A0${t.unitM3}',
                  ].join(' · '),
              ]
            : [
                [?bodyName(d.bodyTypeId), if (d.capacityTons != null) tons(d.capacityTons!), if (d.volumeM3 != null) '${d.volumeM3!.toStringAsFixed(0)} ${t.unitM3}'].join(' · '),
              ].where((l) => l.isNotEmpty).toList();
        final permits = refData == null
            ? const <String>[]
            : [for (final id in d.permitIds) ?refData.permits.where((p) => p.id == id).firstOrNull?.name.forLanguageCode(locale)];
        final city = d.pointId == null ? null : refData?.pointOrNull(d.pointId!)?.name.forLanguageCode(locale);
        final countries = d.anyCountry || refData == null
            ? t.driverSetupAnyCountry
            : d.countryIds.map((id) => refData.countryById(id).name.forLanguageCode(locale)).join(', ');
        final status = city == null
            ? t.driverCardNotLooking
            : d.onSite
                ? t.driverCardOnSite(city)
                : d.plannedDay == null
                    ? t.statusLookingFrom(city)
                    : t.statusOnTheWay(city, formatDate(d.plannedDay!));
        final seen = formatLastSeen(t, d.lastSeenAt);
        final reviews = d.reviews;

        final actions = <Widget>[
          OutlinedButton.icon(
            key: const Key('driverCardCall'),
            onPressed: () => _contact(context, ref, 'CALL'),
            icon: const Icon(LucideIcons.phone, size: 18),
            label: Text(t.commonCall),
          ),
          if (!isChinaCompany)
            OutlinedButton.icon(
              key: const Key('driverCardWhatsapp'),
              onPressed: () => _contact(context, ref, 'WHATSAPP'),
              icon: const WhatsAppIcon(size: 18),
              label: Text(t.commonWhatsApp),
            ),
          OutlinedButton.icon(
            key: const Key('driverCardChat'),
            onPressed: () => _chat(context, ref),
            icon: const Icon(LucideIcons.messageCircle, size: 18),
            label: Text(t.driverCardChat),
          ),
        ];

        return ListView(
          key: const Key('driverCard'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.screen),
          children: [
            // Крупное фото — по центру, нажатие — на весь экран; нет фото — буквы имени.
            Center(
              child: GestureDetector(
                key: const Key('driverCardAvatar'),
                onTap: () => _openAvatar(context, d),
                child: DriverAvatar(driverId: d.id, name: d.fullName, version: d.avatarVersion, radius: 64),
              ),
            ),
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
                if (seen != null) Text(seen, style: AppTextStyles.caption.copyWith(color: seen == t.lastSeenOnline ? AppColors.success : AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.mapPin, color: d.onSite ? AppColors.success : null),
              title: Text(status, key: const Key('driverCardStatus')),
              subtitle: city == null ? null : Text(countries),
            ),
            if (vehicleLines.isNotEmpty || permits.isNotEmpty)
              ListTile(
                key: const Key('driverCardVehicle'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.truck),
                title: Text(vehicleLines.isEmpty ? t.driverCardVehicle : vehicleLines.join('\n')),
                subtitle: permits.isEmpty ? null : Text(t.driverCardPermits(permits.join(', '))),
              ),
            // 046 п.3: «отменил 1 из 15 · после загрузки 1».
            if (cancelStatsText(t, d.cancelStats) case final stats?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(stats, key: const Key('driverCardCancelStats'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(t.driverCardVehiclePhotos, style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            DriverVehiclePhotos(driverId: d.id),
            const SizedBox(height: AppSpacing.lg),
            Text(t.driverCardReviews, style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.xs),
            if (reviews.isEmpty)
              Text(t.cargoDetailNoReviews, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))
            else
              _Reviews(reviews: reviews, total: d.reviewsCount),
            const SizedBox(height: AppSpacing.lg),
            if (onSelect != null) ...[
              PrimaryButton(
                key: const Key('driverCardSelect'),
                label: selectLabel ?? t.responseSelect,
                onPressed: () {
                  Navigator.of(context).pop();
                  onSelect!();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // Кнопки в ряд, не помещаются (узкий экран, крупный шрифт) — столбиком.
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                // Каждой кнопке — не меньше 160 dp при обычном шрифте: «Позвонить»
                // не рвётся посреди слова на SE с крупным шрифтом.
                final inRow = constraints.maxWidth / scale >= actions.length * 160;
                if (inRow) {
                  return Row(children: [for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: AppSpacing.sm), Expanded(child: a)]]);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(height: AppSpacing.sm), a]],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Последние 3 отзыва и «Все отзывы (N)» — раскрывает остальные (до 20 с сервера).
class _Reviews extends StatefulWidget {
  const _Reviews({required this.reviews, required this.total});

  final List<DriverCardReview> reviews;
  final int total;

  @override
  State<_Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<_Reviews> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final shown = _all ? widget.reviews : widget.reviews.take(3).toList();
    return Column(
      key: const Key('driverCardReviews'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'★' * r.rating}${'☆' * (5 - r.rating).clamp(0, 5)} · ${r.companyName} · ${formatDate(r.createdAt)}', style: AppTextStyles.caption),
                if (r.comment != null && r.comment!.isNotEmpty) Text(r.comment!, style: AppTextStyles.body),
              ],
            ),
          ),
        if (!_all && widget.reviews.length > 3)
          TextButton(
            key: const Key('driverCardAllReviews'),
            onPressed: () => setState(() => _all = true),
            child: Text(t.driverCardAllReviews(widget.total)),
          ),
      ],
    );
  }
}
