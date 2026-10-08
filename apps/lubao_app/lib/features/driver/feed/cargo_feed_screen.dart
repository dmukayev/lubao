import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';
import 'announce_arrival_sheet.dart';
import '../../shared/error_feedback.dart';
import '../../shared/tracking_consent_sheet.dart';
import '../deals/my_responses_screen.dart';
import 'driver_status.dart';

class CargoFeedScreen extends ConsumerStatefulWidget {
  const CargoFeedScreen({super.key});

  @override
  ConsumerState<CargoFeedScreen> createState() => _CargoFeedScreenState();
}

class _CargoFeedScreenState extends ConsumerState<CargoFeedScreen> {
  /// Страницы после первой (первая приходит из `cargoFeedProvider`); при
  /// перезагрузке ленты (новый объект первой страницы) сбрасываются.
  CargoFeedPage? _firstPage;
  final List<Cargo> _more = [];
  int _total = 0;
  bool _loadingMore = false;

  /// 045 п.11: первый вход после регистрации — шторка «Где вы сейчас?» сама,
  /// один раз (без отдельного шага «Ищете груз?» и без автоматического анонса).
  bool _askedWhereNow = false;

  void _maybeAskWhereNow(ReferenceData refData) {
    if (_askedWhereNow) return;
    // Без роутера (виджет-тесты экрана) спрашивать нечего.
    if (GoRouter.maybeOf(context) == null) return;
    if (GoRouterState.of(context).uri.queryParameters['where'] != '1') return;
    _askedWhereNow = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showWhereNowSheet(context, ref, refData: refData);
    });
  }

  Future<void> _loadMore(CargoFeedPage first) async {
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(cargoRepositoryProvider).feed(offset: first.items.length + _more.length);
      if (!mounted) return;
      setState(() {
        _more.addAll(page.items);
        _total = page.total;
      });
    } catch (e) {
      if (mounted) showApiError(context, e, onRetry: () => _loadMore(first));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final referenceData = ref.watch(referenceDataProvider);
    final cargoFeed = ref.watch(cargoFeedProvider);

    return Scaffold(
      body: SafeArea(
        child: referenceData.when(
          loading: () => const LoadingView(),
          error: (e, st) {
            debugPrint('CargoFeedScreen (referenceData): $e');
            return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(referenceDataProvider));
          },
          data: (refData) => cargoFeed.when(
            loading: () => const LoadingView(),
            error: (e, st) {
              debugPrint('CargoFeedScreen (cargoFeed): $e');
              return ErrorView(
                message: t.commonError,
                onRetry: () => ref.invalidate(cargoFeedProvider),
                retryLabel: t.commonRetry,
              );
            },
            data: (first) {
              _maybeAskWhereNow(refData);
              if (!identical(first, _firstPage)) {
                _firstPage = first;
                _more.clear();
                _total = first.total;
              }
              final items = [...first.items, ..._more];
              final hasMore = items.length < _total;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(cargoFeedProvider);
                  ref.invalidate(myArrivalsProvider);
                  ref.invalidate(myResponsesProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.lg),
                  children: [
                    // 053 п.6: наверху — строка статуса (045 п.11, главный вход),
                    // без приветствия и пустого колокольчика.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: DriverStatusBar(refData: refData),
                    ),
                    // Под ней — «нужно действие», только пока актуально:
                    // пригласили / выбрали (045 п.3), затем анонс с вопросами
                    // «вы на месте?» и «ещё ищете?».
                    const _MyResponsesSummary(),
                    if (ref.watch(myArrivalsProvider).valueOrNull?.current != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                        child: _AnonsCard(refData: refData),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: Text(t.driverHomeFeedCount(_total), style: AppTextStyles.title),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: EmptyState(message: t.feedEmpty),
                      )
                    else
                      for (final cargo in items) _feedCard(context, refData, cargo),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.md),
                        child: OutlinedButton(
                          key: const Key('feedLoadMoreButton'),
                          onPressed: _loadingMore ? null : () => _loadMore(first),
                          child: _loadingMore
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(t.feedLoadMore),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Строка груза по эталону 28 (047 п.5): маршрут во всю ширину; слева —
  /// «Категория · 20 т · тент», «1 230 км · погрузка завтра», компания мелко;
  /// справа — цена и «690 ₸/км» синим. Плашки — только состояние для водителя.
  Widget _feedCard(BuildContext context, ReferenceData refData, Cargo cargo) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final country = refData.countryById(cargo.destinationCountryId);
    final city = refData.cityById(cargo.destinationCityId);
    final origin = refData.pointOrNull(cargo.pointId)?.name.forLanguageCode(locale);
    final destination = city?.name.forLanguageCode(locale) ?? country.name.forLanguageCode(locale);
    final bodyType = refData.bodyTypeById(cargo.bodyTypeId);
    final category = refData.categoryById(cargo.categoryId)?.name.forLanguageCode(locale);
    final isHomeSection = cargo.feedSection == CargoFeedSection.home;
    final accent = cargo.pickupRank == 0 || isHomeSection;
    final (stateLabel, stateColor) = switch (cargo.myResponseStatus) {
      ResponseStatus.selected => (t.feedStateSelected, StatusBadge.info),
      ResponseStatus.invited => (t.feedStateInvited, StatusBadge.warning),
      ResponseStatus.pending => (t.feedStateResponded, StatusBadge.success),
      _ => (null, StatusBadge.neutral),
    };
    final perKmKzt = cargo.pricePerKm == null ? null : refData.convertToKzt(cargo.pricePerKm!, cargo.currency);
    // 055: водителю — тонны («18,5 т»), меньше тонны — кг.
    final weight = cargo.weightKg == null ? null : formatCargoWeight(cargo.weightKg!, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: locale);
    final grey = AppTextStyles.body.copyWith(color: AppColors.textSecondary);
    final blue = AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
    final small = AppTextStyles.small.copyWith(color: AppColors.textSecondary);
    final companyLine = [
      cargo.companyName,
      if (cargo.companyRatingCount > 0) '★ ${cargo.companyRatingAvg.toStringAsFixed(1)}',
      if (cargo.responsesCount > 0 && cargo.myResponseStatus == null) t.feedRespondedCount(cargo.responsesCount),
    ].join(' · ');

    return AppCard(
      key: Key('feedCargoCard-${cargo.id}'),
      onTap: () => context.push('/driver/cargo/${cargo.id}'),
      borderColor: accent ? AppColors.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(origin == null ? destination : '$origin → $destination', style: AppTextStyles.route, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs),
          // 049 п.13: на узком экране с крупным шрифтом (360 dp × 1,3) колонка цены
          // сжимала атрибуты до разрыва слова («Стройматериал|ы») — тогда цена и
          // ₸/км уходят отдельной строкой под атрибуты.
          LayoutBuilder(
            builder: (context, constraints) {
              final details = _feedDetails(category, weight, bodyType.name.forLanguageCode(locale), cargo, t, grey, blue, small, companyLine);
              final price = Text(formatMoney(cargo.price, cargo.currency), style: AppTextStyles.priceCard);
              final perKm = perKmKzt == null ? null : Text(t.perKmKzt(formatThousands(perKmKzt.round())), key: Key('feedCargoPerKm-${cargo.id}'), style: blue);
              final narrow = constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) < 260;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    details,
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [price, ?perKm],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: AppSpacing.md),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [price, ?perKm]),
                ],
              );
            },
          ),
          if (isHomeSection || cargo.allowPartial || stateLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (isHomeSection) _pill(t.feedSectionHome, AppColors.accentSoft, AppColors.accentText),
                if (cargo.allowPartial) _pill(t.feedBadgePartial, AppColors.primarySoft, AppColors.primary),
                if (stateLabel != null) StatusBadge(label: stateLabel, color: stateColor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _feedDetails(String? category, String? weight, String bodyName, Cargo cargo, LubaoLocalizations t, TextStyle grey, TextStyle blue, TextStyle small, String companyLine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              if (category != null) TextSpan(text: category, style: AppTextStyles.bodyStrong),
              TextSpan(text: [if (category != null) '', ?weight, bodyName].join(' · '), style: grey),
            ],
          ),
        ),
        Text.rich(
          key: Key('feedCargoKm-${cargo.id}'),
          TextSpan(
            children: [
              if (cargo.distanceKm != null && cargo.distanceKm! > 0) ...[
                TextSpan(text: '${formatThousands(cargo.distanceKm!)} ${t.unitKm}', style: blue),
                TextSpan(text: ' · ', style: grey),
              ],
              TextSpan(text: loadingDayLabel(t, cargo.readyDate), style: grey),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(companyLine, style: small, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _pill(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyles.small.copyWith(color: fg)),
  );
}

/// «Ваши отклики: 3 · ждут ответа 2 · приглашение 1» (045 п.3) — тап открывает
/// «Мои отклики»; нет активных откликов — секции нет.
class _MyResponsesSummary extends ConsumerWidget {
  const _MyResponsesSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final entries = ref.watch(myResponsesProvider).valueOrNull ?? const [];
    final pending = entries.where((e) => e.status == ResponseStatus.pending).length;
    final invited = entries.where((e) => e.status == ResponseStatus.invited).length;
    final selected = entries.where((e) => e.status == ResponseStatus.selected).length;
    final total = pending + invited + selected;
    if (total == 0) return const SizedBox.shrink();
    final parts = [
      t.homeMyResponsesSummary(total),
      if (pending > 0) t.homeMyResponsesPending(pending),
      if (invited > 0) t.homeMyResponsesInvited(invited),
      if (selected > 0) t.homeMyResponsesSelected(selected),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
      child: AppCard(
        key: const Key('homeMyResponses'),
        onTap: () => context.push('/driver/responses'),
        child: Row(
          children: [
            Icon(LucideIcons.send, color: invited > 0 || selected > 0 ? AppColors.accentText : AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(parts.join(' · '), style: AppTextStyles.bodyStrong)),
            const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AnonsCard extends ConsumerWidget {
  const _AnonsCard({required this.refData});

  final ReferenceData refData;

  Future<void> _openSheet(BuildContext context, WidgetRef ref, {Arrival? editing}) async {
    final driver = ref.read(sessionProvider)?.driver;
    final result = await showAnnounceArrivalSheet(
      context,
      refData: refData,
      editing: editing,
      driverAnyCountry: driver?.anyCountry ?? false,
      driverDirectionCountryIds: driver?.directionCountryIds ?? const [],
      driverHomeCityId: driver?.homeCityId,
    );
    if (result == true) {
      ref.invalidate(myArrivalsProvider);
      ref.invalidate(arrivalTemplateProvider);
      ref.invalidate(cargoFeedProvider);
    }
  }

  /// Любое действие над анонсом: выполнить, обновить анонсы и ленту (город
  /// анонса задаёт порядок ленты), ошибка — понятным текстом с повтором.
  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(myArrivalsProvider);
      ref.invalidate(arrivalTemplateProvider);
      ref.invalidate(cargoFeedProvider);
    } catch (e) {
      if (context.mounted) showApiError(context, e, onRetry: () => _run(context, ref, action));
    }
  }

  /// «Я на месте»: в городе-терминале сначала согласие на проверку отъезда
  /// (040, п.4 / 041, п.11); отказ от шторки не мешает отметке.
  Future<void> _checkIn(BuildContext context, WidgetRef ref, Arrival arrival) async {
    final isTerminal = refData.pointOrNull(arrival.pointId)?.kind == PointKind.terminal;
    if (isTerminal) await ensureTerminalWatchConsent(context, ref);
    if (!context.mounted) return;
    await _run(context, ref, () => ref.read(arrivalRepositoryProvider).checkIn(arrivalId: arrival.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final arrivalsAsync = ref.watch(myArrivalsProvider);
    final repo = ref.read(arrivalRepositoryProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
      child: arrivalsAsync.when(
        loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (e, st) {
          debugPrint('CargoFeedScreen (myArrivals): $e');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.commonError, style: AppTextStyles.body.copyWith(color: Colors.white)),
              TextButton(
                onPressed: () => ref.invalidate(myArrivalsProvider),
                child: Text(t.commonRetry, style: AppTextStyles.body.copyWith(color: Colors.white)),
              ),
            ],
          );
        },
        data: (mine) {
          final pill = _Pill(label: t.driverHomeAnonsTitle);
          final arrival = mine.current;
          if (arrival == null) {
            final templateAsync = ref.watch(arrivalTemplateProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pill,
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.driverHomeCheckInEmpty,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                AccentButton(
                  key: const Key('driverAnnounceArrivalButton'),
                  label: t.driverHomeAnnounceButton,
                  icon: LucideIcons.calendarPlus,
                  onPressed: () => _openSheet(context, ref),
                ),
                templateAsync.maybeWhen(
                  data: (template) => template == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Center(
                            child: TextButton(
                              onPressed: () => _run(context, ref, repo.repeat),
                              child: Text(
                                t.driverHomeRepeatButton,
                                style: AppTextStyles.caption.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            );
          }

          final cityName = refData.pointOrNull(arrival.pointId)?.name.forLanguageCode(locale) ?? '';
          final isOnSite = arrival.status == ArrivalStatus.onSite;
          final countryChips = <Widget>[
            if (arrival.anyCountry)
              _Pill(label: t.driverSetupAnyCountry)
            else
              for (final countryId in arrival.countryIds) CountryCode(code: refData.countryById(countryId).code, onDark: true),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: pill),
                  const SizedBox(width: AppSpacing.sm),
                  const Spacer(),
                  Icon(LucideIcons.eye, color: Colors.white.withAlpha(200), size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      t.driverHomeLogistsCount(arrival.viewsCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withAlpha(200)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(cityName, key: const Key('anonsCityName'), style: AppTextStyles.headline.copyWith(color: Colors.white)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isOnSite
                    ? t.driverHomeSince(formatDateTime(arrival.arrivedAt ?? arrival.plannedAt))
                    : t.driverHomePlannedFor(formatDate(arrival.plannedDay)),
                style: AppTextStyles.body.copyWith(color: Colors.white.withAlpha(200)),
              ),
              if (countryChips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: countryChips),
              ],
              if (arrival.ask != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Question(
                  arrival: arrival,
                  onStillLooking: () => _run(context, ref, () => repo.stillLooking(arrivalId: arrival.id)),
                  onLeft: () => _run(context, ref, () => repo.cancel(arrivalId: arrival.id)),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (!isOnSite) ...[
                AccentButton(
                  key: const Key('driverCheckInButton'),
                  label: t.driverHomeCheckInButton,
                  icon: LucideIcons.mapPin,
                  onPressed: () => _checkIn(context, ref, arrival),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    key: const Key('anonsEditButton'),
                    onPressed: () => _openSheet(context, ref, editing: arrival),
                    child: Text(t.driverHomeEditButton, style: AppTextStyles.caption.copyWith(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => _run(context, ref, () => repo.cancel(arrivalId: arrival.id)),
                    child: Text(
                      isOnSite ? t.driverHomeLeaveButton : t.driverHomeCancelButton,
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              for (final other in mine.others)
                _OtherArrivalRow(
                  key: Key('otherArrival-${other.id}'),
                  arrival: other,
                  cityName: refData.pointOrNull(other.pointId)?.name.forLanguageCode(locale) ?? '',
                  onCheckIn: () => _checkIn(context, ref, other),
                  onCancel: () => _run(context, ref, () => repo.cancel(arrivalId: other.id)),
                  onStillLooking: () => _run(context, ref, () => repo.stillLooking(arrivalId: other.id)),
                ),
              if (mine.all.length < _maxArrivals)
                Center(
                  child: TextButton.icon(
                    key: const Key('driverAnnounceAnotherButton'),
                    onPressed: () => _openSheet(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                    label: Text(t.announceArrivalAddAnother, style: AppTextStyles.caption.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

const _maxArrivals = 5;

/// Вопрос по правилу свежести (040, п.4): «Доехали?» (в день приезда) или
/// «Ещё ищете груз?» (на месте, 12 ч без ответа). На «Доехали?» отвечает
/// кнопка «Я на месте» самой карточки; на «Ещё ищете груз?» — «Да / Уехал».
class _Question extends StatelessWidget {
  const _Question({required this.arrival, required this.onStillLooking, required this.onLeft});

  final Arrival arrival;
  final VoidCallback onStillLooking;
  final VoidCallback onLeft;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final still = arrival.ask == ArrivalQuestion.stillLooking;
    return Container(
      key: const Key('arrivalQuestion'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            still ? t.arrivalQuestionStill : t.arrivalQuestionDay,
            style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
          ),
          if (still) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AccentButton(key: const Key('arrivalStillYesButton'), label: t.arrivalStillYes, onPressed: onStillLooking),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('arrivalStillLeftButton'),
                  onPressed: onLeft,
                  child: Text(t.arrivalStillLeft, style: AppTextStyles.bodyStrong.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Остальные анонсы водителя («дальше в планах»): город, день, быстрые
/// действия — «Я на месте» (если день уже наступил), «Отменить».
class _OtherArrivalRow extends StatelessWidget {
  const _OtherArrivalRow({
    super.key,
    required this.arrival,
    required this.cityName,
    required this.onCheckIn,
    required this.onCancel,
    required this.onStillLooking,
  });

  final Arrival arrival;
  final String cityName;
  final VoidCallback onCheckIn;
  final VoidCallback onCancel;
  final VoidCallback onStillLooking;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final isOnSite = arrival.status == ArrivalStatus.onSite;
    final today = DateTime.now();
    final dayReached = !arrival.plannedDay.isAfter(DateTime(today.year, today.month, today.day));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withAlpha(60), height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$cityName · ${isOnSite ? t.driverHomeSince(formatDateTime(arrival.arrivedAt ?? arrival.plannedAt)) : t.driverHomePlannedFor(formatDate(arrival.plannedDay))}',
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
              ),
              if (!isOnSite && dayReached)
                TextButton(
                  key: Key('otherArrivalCheckIn-${arrival.id}'),
                  onPressed: onCheckIn,
                  child: Text(t.driverHomeCheckInButton, style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
                ),
              TextButton(
                key: Key('otherArrivalCancel-${arrival.id}'),
                onPressed: onCancel,
                child: Text(isOnSite ? t.driverHomeLeaveButton : t.driverHomeCancelButton, style: AppTextStyles.caption.copyWith(color: Colors.white)),
              ),
            ],
          ),
          if (arrival.ask != null) _Question(arrival: arrival, onStillLooking: onStillLooking, onLeft: onCancel),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(999)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.small.copyWith(color: Colors.white)),
    );
  }
}
