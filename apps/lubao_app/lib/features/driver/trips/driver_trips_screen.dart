import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/error_feedback.dart';
import '../../shared/status_helpers.dart';

/// Отклики водителя (041, п.9) — источник «Моих рейсов» и «Истории рейсов».
final myResponsesProvider = FutureProvider.autoDispose<List<MyResponseEntry>>((ref) {
  return ref.watch(cargoRepositoryProvider).myResponses();
});

/// Сколько часов осталось ответить на приглашение (не меньше 1, пока не истекло).
int inviteHoursLeft(DateTime? expiresAt, DateTime now) {
  if (expiresAt == null) return 0;
  final minutes = expiresAt.difference(now).inMinutes;
  if (minutes <= 0) return 0;
  return (minutes / 60).ceil();
}

/// Сделки, где ход за водителем («Вас выбрали — подтвердите»).
bool dealNeedsDriver(Deal d) => d.status == DealStatus.selected;

/// Сделка в работе: подтверждена → загружен → в пути (и запрос отмены по ней).
bool dealInWork(Deal d) => const {DealStatus.confirmedByDriver, DealStatus.loaded, DealStatus.inTransit, DealStatus.cancelRequested, DealStatus.disputed}.contains(d.status);

/// Цифра на вкладке «Мои рейсы» — раздел «Нужно ответить».
int tripsNeedAnswerCount(List<Deal> deals, List<MyResponseEntry> responses) =>
    deals.where(dealNeedsDriver).length + responses.where((r) => r.status == ResponseStatus.invited).length;

/// 056 п.6: «Мои рейсы» — отклики и сделки в одном месте. Разделы сверху вниз
/// (пустой не показываем): «Нужно ответить» (выбран / приглашён с таймером) →
/// «Жду ответа логиста» (ближайшая погрузка сверху) → «В работе».
class DriverTripsScreen extends ConsumerWidget {
  const DriverTripsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dealsMineProvider);
    ref.invalidate(myResponsesProvider);
    ref.invalidate(cargoFeedProvider);
  }

  Future<void> _act(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
    await _refresh(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final dealsAsync = ref.watch(dealsMineProvider);
    final responsesAsync = ref.watch(myResponsesProvider);
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final repo = ref.read(cargoRepositoryProvider);

    Widget body;
    if ((dealsAsync.isLoading && !dealsAsync.hasValue) || (responsesAsync.isLoading && !responsesAsync.hasValue)) {
      body = const LoadingView();
    } else if (dealsAsync.hasError || responsesAsync.hasError) {
      body = ErrorView(message: t.commonError, onRetry: () => _refresh(ref));
    } else {
      final deals = dealsAsync.value ?? const <Deal>[];
      final responses = responsesAsync.value ?? const <MyResponseEntry>[];
      final now = DateTime.now();
      final selected = deals.where(dealNeedsDriver).toList();
      final invited = responses.where((r) => r.status == ResponseStatus.invited && inviteHoursLeft(r.inviteExpiresAt, now) > 0).toList();
      final waiting = responses.where((r) => r.status == ResponseStatus.pending).toList()..sort((a, b) => a.readyDate.compareTo(b.readyDate));
      final inWork = deals.where(dealInWork).toList();

      if (selected.isEmpty && invited.isEmpty && waiting.isEmpty && inWork.isEmpty) {
        body = ListView(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            EmptyState(message: t.tripsEmpty),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: PrimaryButton(key: const Key('tripsGoFeed'), label: t.tripsGoFeed, onPressed: () => context.go('/driver/feed')),
            ),
          ],
        );
      } else {
        body = ListView(
          key: const Key('tripsList'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            if (selected.isNotEmpty || invited.isNotEmpty) ...[
              _SectionTitle(key: const Key('tripsSectionNeedAnswer'), title: t.tripsNeedAnswer, count: selected.length + invited.length, color: AppColors.error),
              for (final d in selected)
                _TripCard(
                  key: Key('driverDealCard-${d.id}'),
                  refData: refData,
                  cargo: _TripCargo.fromDeal(d),
                  borderColor: AppColors.primary,
                  badge: StatusBadge(label: t.tripsSelectedBadge, color: StatusBadge.info),
                  onTap: () => context.push('/deal/${d.id}'),
                  actions: [
                    Expanded(child: PrimaryButton(key: Key('tripConfirm-${d.id}'), label: t.tripsConfirm, onPressed: () => context.push('/deal/${d.id}'))),
                  ],
                ),
              for (final r in invited)
                _TripCard(
                  key: Key('tripInvite-${r.id}'),
                  refData: refData,
                  cargo: _TripCargo.fromResponse(r),
                  borderColor: AppColors.accent,
                  badge: StatusBadge(label: t.tripsInvitedBadge(inviteHoursLeft(r.inviteExpiresAt, now)), color: StatusBadge.warning),
                  onTap: () => context.push('/driver/cargo/${r.cargoId}'),
                  actions: [
                    Expanded(child: PrimaryButton(key: Key('tripAccept-${r.id}'), label: t.tripsAccept, onPressed: () => _act(context, ref, () => repo.respond(r.cargoId)))),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        key: Key('tripDecline-${r.id}'),
                        onPressed: () => _act(context, ref, () => repo.withdrawResponse(r.id)),
                        child: Text(t.tripsDecline, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
            ],
            if (waiting.isNotEmpty) ...[
              _SectionTitle(key: const Key('tripsSectionWaiting'), title: t.tripsWaiting, count: waiting.length),
              for (final r in waiting)
                _TripCard(
                  key: Key('tripWaiting-${r.id}'),
                  refData: refData,
                  cargo: _TripCargo.fromResponse(r),
                  onTap: () => context.push('/driver/cargo/${r.cargoId}'),
                  actions: [
                    TextButton(
                      key: Key('tripWithdraw-${r.id}'),
                      onPressed: () => _act(context, ref, () => repo.withdrawResponse(r.id)),
                      child: Text(t.tripsWithdraw, style: const TextStyle(decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
            ],
            if (inWork.isNotEmpty) ...[
              _SectionTitle(key: const Key('tripsSectionInWork'), title: t.tripsInWork, count: inWork.length, color: AppColors.success),
              for (final d in inWork)
                Builder(builder: (context) {
                  final (label, color) = dealStatusPresentation(t, d.status);
                  return _TripCard(
                    key: Key('driverDealCard-${d.id}'),
                    refData: refData,
                    cargo: _TripCargo.fromDeal(d),
                    badge: StatusBadge(label: label, color: color),
                    onTap: () => context.push('/deal/${d.id}'),
                  );
                }),
            ],
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.tripsTitle)),
      body: RefreshIndicator(onRefresh: () => _refresh(ref), child: body),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({super.key, required this.title, required this.count, this.color});

  final String title;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          text: title.toUpperCase(),
          style: AppTextStyles.caption.copyWith(color: color ?? AppColors.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          children: [TextSpan(text: ' · $count', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))],
        ),
      ),
    );
  }
}

/// Сводка груза для карточки — из отклика или из сделки.
class _TripCargo {
  const _TripCargo({
    this.pointId,
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    this.categoryId,
    this.weightKg,
    this.volumeM3,
    required this.price,
    required this.currency,
    required this.readyDate,
    required this.companyName,
    this.advanceAmount,
    this.paymentForm,
    this.paymentDelayDays,
  });

  final double? volumeM3;
  final double? advanceAmount;
  final PaymentForm? paymentForm;
  final int? paymentDelayDays;

  final String? pointId;
  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final String? categoryId;
  final double? weightKg;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String companyName;

  factory _TripCargo.fromResponse(MyResponseEntry r) => _TripCargo(
        pointId: r.pointId,
        destinationCountryId: r.destinationCountryId,
        destinationCityId: r.destinationCityId,
        bodyTypeId: r.bodyTypeId,
        categoryId: r.categoryId,
        weightKg: r.weightKg,
        volumeM3: r.volumeM3,
        price: r.price,
        currency: r.currency,
        readyDate: r.readyDate,
        companyName: r.companyName,
        advanceAmount: r.advanceAmount,
        paymentForm: r.paymentForm,
        paymentDelayDays: r.paymentDelayDays,
      );

  static _TripCargo? fromDealOrNull(Deal d) {
    final c = d.cargo;
    if (c == null) return null;
    return _TripCargo(
      pointId: c.pointId,
      destinationCountryId: c.destinationCountryId,
      destinationCityId: c.destinationCityId,
      bodyTypeId: c.bodyTypeId,
      categoryId: c.categoryId,
      weightKg: c.weightKg,
      volumeM3: c.volumeM3,
      price: c.price,
      currency: c.currency,
      readyDate: c.readyDate,
      companyName: d.companyName,
      advanceAmount: c.advanceAmount,
      paymentForm: c.paymentForm,
      paymentDelayDays: c.paymentDelayDays,
    );
  }

  factory _TripCargo.fromDeal(Deal d) =>
      fromDealOrNull(d) ??
      _TripCargo(destinationCountryId: '', bodyTypeId: '', price: 0, currency: Currency.kzt, readyDate: d.createdAt, companyName: d.companyName);
}

/// Карточка рейса по эталону 32: маршрут и цена, «категория · вес · кузов ·
/// погрузка», компания; плашка состояния и кнопки — по разделу.
class _TripCard extends StatelessWidget {
  const _TripCard({super.key, required this.refData, required this.cargo, this.badge, this.actions = const [], this.onTap, this.borderColor});

  final ReferenceData? refData;
  final _TripCargo cargo;
  final Widget? badge;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final rd = refData;
    // 058 п.3: флаги стран, «21 т · 35 м³»; п.1 — условия оплаты.
    final route = rd == null || cargo.destinationCountryId.isEmpty
        ? null
        : cargoRouteLabels(rd, pointId: cargo.pointId, destinationCountryId: cargo.destinationCountryId, destinationCityId: cargo.destinationCityId, languageCode: locale);
    final origin = route?.origin;
    final destination = route?.destination ?? '';
    final size = cargoSizeLabel(t, weightKg: cargo.weightKg, volumeM3: cargo.volumeM3, languageCode: locale);
    final terms = paymentTermsLine(t, advanceAmount: cargo.advanceAmount, paymentForm: cargo.paymentForm, paymentDelayDays: cargo.paymentDelayDays, currency: cargo.currency);
    final details = [
      if (cargo.categoryId != null) rd?.categoryById(cargo.categoryId)?.name.forLanguageCode(locale),
      if (size.isNotEmpty) size,
      if (rd != null && cargo.bodyTypeId.isNotEmpty) rd.bodyTypeById(cargo.bodyTypeId).name.forLanguageCode(locale),
      formatDate(cargo.readyDate),
    ].whereType<String>().join(' · ');

    return AppCard(
      onTap: onTap,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(origin == null ? destination : '$origin → $destination', style: AppTextStyles.route, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(formatMoney(cargo.price, cargo.currency), style: AppTextStyles.priceCard),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(details, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          if (terms.isNotEmpty) Text(terms, style: AppTextStyles.body),
          if (cargo.companyName.isNotEmpty) Text(cargo.companyName, style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
          if (badge != null) ...[const SizedBox(height: AppSpacing.sm), badge!],
          if (actions.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Row(children: actions)],
        ],
      ),
    );
  }
}
