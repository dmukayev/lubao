import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';

class DriversAtPointScreen extends ConsumerStatefulWidget {
  const DriversAtPointScreen({super.key});

  @override
  ConsumerState<DriversAtPointScreen> createState() => _DriversAtPointScreenState();
}

const _dayStripLength = 7;

class _DriversAtPointScreenState extends ConsumerState<DriversAtPointScreen> {
  String? _countryId;
  String? _bodyTypeId;
  bool _minCapacity = false;
  bool _verifiedOnly = false;
  int _dayOffset = 0;
  Future<List<ArrivalListing>>? _future;
  Future<List<ArrivalSummaryDay>>? _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = ref.read(arrivalRepositoryProvider).summary(days: _dayStripLength);
    _reload();
  }

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _dayOffset));

  void _reload() {
    setState(() {
      _future = ref.read(arrivalRepositoryProvider).listForCompany(
            date: _selectedDate,
            countryId: _countryId,
            bodyTypeId: _bodyTypeId,
            minCapacityTons: _minCapacity ? 20 : null,
            verifiedOnly: _verifiedOnly,
          );
    });
  }

  void _selectDay(int offset) {
    setState(() => _dayOffset = offset);
    _reload();
  }

  Future<void> _call(String? phone) async {
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _invite(ArrivalListing driver) async {
    final t = context.l10n;
    final cargos = await ref.read(myCargosProvider.future);
    final publishedCargos = cargos.where((c) => c.status == CargoStatus.published).toList();
    if (!mounted) return;
    if (publishedCargos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driversAtPointNoCargos)));
      return;
    }
    final refData = ref.read(referenceDataProvider).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;

    final selectedCargo = await showModalBottomSheet<Cargo>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(t.driversAtPointPickCargo, style: AppTextStyles.title),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final cargo in publishedCargos)
                    ListTile(
                      title: Text(
                        refData == null
                            ? ''
                            : [
                                refData.cityById(cargo.destinationCityId)?.name.forLanguageCode(locale),
                                refData.countryById(cargo.destinationCountryId).name.forLanguageCode(locale),
                              ].whereType<String>().join(', '),
                        style: AppTextStyles.bodyStrong,
                      ),
                      subtitle: Text(formatMoney(cargo.price, cargo.currency)),
                      onTap: () => Navigator.of(context).pop(cargo),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (selectedCargo == null || !mounted) return;

    await ref.read(cargoRepositoryProvider).inviteDriver(selectedCargo.id, driver.driverId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driversAtPointInviteSent)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.driversAtPointTitle)),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError),
        data: (refData) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
              child: Text(t.driversAtPointSubtitle, style: AppTextStyles.caption),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 72,
              child: FutureBuilder<List<ArrivalSummaryDay>>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  final counts = snapshot.data;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                    itemCount: _dayStripLength,
                    separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final count = counts == null || index >= counts.length ? null : counts[index].count;
                      return _DayChip(
                        label: index == 0 ? t.driversAtPointToday : _weekdayLabel(context, date),
                        count: count,
                        selected: _dayOffset == index,
                        onTap: () => _selectDay(index),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _FilterDropdown<String?>(
                    label: t.driversAtPointFilterCountry,
                    value: _countryId,
                    items: [
                      DropdownMenuItem(value: null, child: Text(t.driverSetupAnyCountry)),
                      for (final country in refData.countries)
                        DropdownMenuItem(value: country.id, child: Text(country.name.forLanguageCode(locale))),
                    ],
                    onChanged: (value) {
                      _countryId = value;
                      _reload();
                    },
                  ),
                  _FilterDropdown<String?>(
                    label: t.driversAtPointFilterBodyType,
                    value: _bodyTypeId,
                    items: [
                      DropdownMenuItem(value: null, child: Text(t.driversAtPointFilterBodyType)),
                      for (final bodyType in refData.bodyTypes)
                        DropdownMenuItem(value: bodyType.id, child: Text(bodyType.name.forLanguageCode(locale))),
                    ],
                    onChanged: (value) {
                      _bodyTypeId = value;
                      _reload();
                    },
                  ),
                  SelectableTile(
                    label: t.driversAtPointFilterMinCapacity,
                    selected: _minCapacity,
                    onTap: () {
                      _minCapacity = !_minCapacity;
                      _reload();
                    },
                  ),
                  SelectableTile(
                    label: t.driversAtPointFilterVerifiedOnly,
                    selected: _verifiedOnly,
                    onTap: () {
                      _verifiedOnly = !_verifiedOnly;
                      _reload();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ArrivalListing>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                  if (snapshot.hasError) return ErrorView(message: t.commonError, onRetry: _reload);
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return EmptyState(message: t.driversAtPointEmpty, icon: LucideIcons.users);

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                          child: Text(t.driversAtPointCountAtPlace(list.length), style: AppTextStyles.bodyStrong),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final driver in list) _DriverCard(driver: driver, refData: refData, onCall: _call, onInvite: _invite),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _weekdayShort = {
  'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
  'kk': ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс'],
  'zh': ['一', '二', '三', '四', '五', '六', '日'],
};

String _weekdayLabel(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  final names = _weekdayShort[locale] ?? _weekdayShort['ru']!;
  return names[date.weekday - 1];
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: selected ? Colors.white : AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              count?.toString() ?? '–',
              style: AppTextStyles.bodyStrong.copyWith(color: selected ? Colors.white : AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: (v) => onChanged(v as T),
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.text),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.refData, required this.onCall, required this.onInvite});

  final ArrivalListing driver;
  final ReferenceData refData;
  final ValueChanged<String?> onCall;
  final ValueChanged<ArrivalListing> onInvite;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final bodyType = driver.bodyTypeId == null ? null : refData.bodyTypeById(driver.bodyTypeId!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  driver.driverName.isEmpty ? '' : driver.driverName.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(driver.driverName, style: AppTextStyles.bodyStrong)),
                        if (driver.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (driver.ratingCount > 0) ...[
                          const Icon(LucideIcons.star, size: 14, color: AppColors.accent),
                          const SizedBox(width: AppSpacing.xs),
                          Text(driver.ratingAvg.toStringAsFixed(1), style: AppTextStyles.caption),
                        ] else
                          Text(t.cargoDetailNoReviews, style: AppTextStyles.caption),
                        if (bodyType != null) ...[
                          const Text(' · ', style: AppTextStyles.caption),
                          Text(bodyType.name.forLanguageCode(locale), style: AppTextStyles.caption),
                        ],
                        if (driver.capacityTons != null) ...[
                          const Text(' · ', style: AppTextStyles.caption),
                          Text('${driver.capacityTons!.toStringAsFixed(0)} ${t.unitTon}', style: AppTextStyles.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconSquareButton(icon: LucideIcons.phone, onPressed: () => onCall(driver.phone)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (driver.anyCountry)
                _pill(t.driverSetupAnyCountry)
              else
                for (final countryId in driver.directionCountryIds) CountryCode(code: refData.countryById(countryId).code),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                driver.status == ArrivalStatus.onSite ? LucideIcons.mapPin : LucideIcons.calendarClock,
                size: 14,
                color: driver.status == ArrivalStatus.onSite ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                driver.status == ArrivalStatus.onSite
                    ? t.driversAtPointArrivedAt(_formatTime(driver.arrivedAt ?? driver.plannedAt))
                    : t.driversAtPointPlannedAt(_formatTime(driver.plannedAt)),
                style: AppTextStyles.caption.copyWith(
                  color: driver.status == ArrivalStatus.onSite ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: t.driversAtPointInvite, onPressed: () => onInvite(driver)),
        ],
      ),
    );
  }

  Widget _pill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: AppTextStyles.small.copyWith(color: AppColors.primary)),
      );

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }
}
