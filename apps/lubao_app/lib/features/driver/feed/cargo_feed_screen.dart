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

class CargoFeedScreen extends ConsumerWidget {
  const CargoFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final referenceData = ref.watch(referenceDataProvider);
    final cargoFeed = ref.watch(cargoFeedProvider);
    final session = ref.watch(sessionProvider);
    final driver = session?.driver;

    return Scaffold(
      body: SafeArea(
        child: referenceData.when(
          loading: () => const LoadingView(),
          error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(referenceDataProvider)),
          data: (refData) => cargoFeed.when(
            loading: () => const LoadingView(),
            error: (e, st) => ErrorView(
              message: t.commonError,
              onRetry: () => ref.invalidate(cargoFeedProvider),
              retryLabel: t.commonRetry,
            ),
            data: (cargos) {
              final homeCity = driver == null ? null : refData.cityById(driver.homeCityId);
              final items = sortCargoFeed(
                cargos: cargos,
                driverHomeCountryId: homeCity?.countryId,
                driverDirectionCountryIds: driver?.directionCountryIds.toSet() ?? {},
                anyCountry: driver?.anyCountry ?? true,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(cargoFeedProvider);
                  ref.invalidate(myArrivalProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: _GreetingRow(fullName: driver?.fullName),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: _AnonsCard(refData: refData),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                      child: Text(t.driverHomeFeedCount(cargos.length), style: AppTextStyles.title),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (cargos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: EmptyState(message: t.feedEmpty),
                      )
                    else
                      for (final item in items) _feedCard(context, refData, item),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _feedCard(BuildContext context, ReferenceData refData, CargoFeedItem item) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cargo = item.cargo;
    final country = refData.countryById(cargo.destinationCountryId);
    final city = refData.cityById(cargo.destinationCityId);
    final destinationLabel =
        [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
    final bodyType = refData.bodyTypeById(cargo.bodyTypeId);
    final (statusLabel, statusColor) = cargoStatusPresentation(t, cargo.status);

    return CargoCard(
      destinationLabel: destinationLabel,
      bodyTypeLabel: bodyType.name.forLanguageCode(locale),
      priceLabel: formatMoney(cargo.price, cargo.currency),
      secondaryPriceLabel: formatKztConversion(refData.convertToKzt(cargo.price, cargo.currency)),
      readyDateLabel: formatDate(cargo.readyDate),
      statusLabel: statusLabel,
      statusColor: statusColor,
      accentBorder: item.section == CargoFeedSection.home,
      badge: item.section == CargoFeedSection.home
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(999)),
              child: Text(t.feedSectionHome, style: AppTextStyles.small.copyWith(color: AppColors.accentText)),
            )
          : CountryCode(code: country.code),
      onTap: () => context.push('/driver/cargo/${cargo.id}'),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.fullName});

  final String? fullName;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final firstName = (fullName ?? '').trim().split(' ').firstOrNull ?? '';
    final initials = firstName.isEmpty ? '' : firstName.substring(0, 1).toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primarySoft,
          child: Text(initials, style: AppTextStyles.title.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.driverHomeGreeting, style: AppTextStyles.caption),
              Text(firstName, style: AppTextStyles.title),
            ],
          ),
        ),
        IconSquareButton(icon: LucideIcons.bell, onPressed: null),
      ],
    );
  }
}

class _AnonsCard extends ConsumerWidget {
  const _AnonsCard({required this.refData});

  final ReferenceData refData;

  Future<void> _openSheet(BuildContext context, WidgetRef ref, {ArrivalTemplate? template}) async {
    final driver = ref.read(sessionProvider)?.driver;
    final result = await showAnnounceArrivalSheet(
      context,
      refData: refData,
      template: template,
      driverAnyCountry: driver?.anyCountry ?? false,
      driverDirectionCountryIds: driver?.directionCountryIds ?? const [],
    );
    if (result == true) {
      ref.invalidate(myArrivalProvider);
      ref.invalidate(arrivalTemplateProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final arrivalAsync = ref.watch(myArrivalProvider);

    Future<void> checkIn() async {
      await ref.read(arrivalRepositoryProvider).checkIn();
      ref.invalidate(myArrivalProvider);
    }

    Future<void> cancel() async {
      await ref.read(arrivalRepositoryProvider).cancel();
      ref.invalidate(myArrivalProvider);
      ref.invalidate(arrivalTemplateProvider);
    }

    Future<void> repeat() async {
      await ref.read(arrivalRepositoryProvider).repeat();
      ref.invalidate(myArrivalProvider);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
      child: arrivalAsync.when(
        loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (e, st) => Text(t.commonError, style: const TextStyle(color: Colors.white)),
        data: (arrival) {
          final pill = _Pill(label: t.driverHomeAnonsTitle);
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
                              onPressed: repeat,
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

          final point = refData.pointById(arrival.pointId);
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
                  pill,
                  const Spacer(),
                  Icon(LucideIcons.eye, color: Colors.white.withAlpha(200), size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.driverHomeLogistsCount(arrival.viewsCount),
                    style: AppTextStyles.caption.copyWith(color: Colors.white.withAlpha(200)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(point.name.forLanguageCode(locale), style: AppTextStyles.headline.copyWith(color: Colors.white)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isOnSite
                    ? t.driverHomeSince(formatDateTime(arrival.arrivedAt ?? arrival.plannedAt))
                    : t.driverHomePlannedFor(formatDateTime(arrival.plannedAt)),
                style: AppTextStyles.body.copyWith(color: Colors.white.withAlpha(200)),
              ),
              if (countryChips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: countryChips),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (!isOnSite) ...[
                AccentButton(label: t.driverHomeCheckInButton, icon: LucideIcons.mapPin, onPressed: checkIn),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _openSheet(
                      context,
                      ref,
                      template: ArrivalTemplate(
                        pointId: arrival.pointId,
                        anyCountry: arrival.anyCountry,
                        countryIds: arrival.countryIds,
                      ),
                    ),
                    child: Text(t.driverHomeEditButton, style: AppTextStyles.caption.copyWith(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: cancel,
                    child: Text(
                      isOnSite ? t.driverHomeLeaveButton : t.driverHomeCancelButton,
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
      child: Text(label, style: AppTextStyles.small.copyWith(color: Colors.white)),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
