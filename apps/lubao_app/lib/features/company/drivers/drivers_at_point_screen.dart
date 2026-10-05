import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';

class DriversAtPointScreen extends ConsumerStatefulWidget {
  const DriversAtPointScreen({super.key});

  @override
  ConsumerState<DriversAtPointScreen> createState() => _DriversAtPointScreenState();
}

const _dayStripLength = 7;

/// Диапазон для календаря — с запасом: водитель анонсирует прибытие максимум
/// на +14 дней (задача 015), остальное в календаре честно покажет 0.
const _calendarRangeDays = 90;

class _DriversAtPointScreenState extends ConsumerState<DriversAtPointScreen> {
  String? _countryId;
  String? _bodyTypeId;
  bool _minCapacity = false;
  bool _verifiedOnly = false;
  int _dayOffset = 0;
  Future<List<ArrivalListing>>? _future;
  Future<List<ArrivalSummaryDay>>? _summaryFuture;
  String? _openingChatDriverId;

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

  /// Календарь по кнопке в AppBar — любая дата, не только ближайшие 7 дней
  /// из полосы (задача логиста, 2026-10-04). Переиспользует _selectDay —
  /// выбор дня в полосе и в календаре ведут к одному и тому же состоянию.
  Future<void> _openCalendar(BuildContext context) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final summaryFuture = ref.read(arrivalRepositoryProvider).summary(days: _calendarRangeDays);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
      builder: (sheetContext) => _ArrivalsCalendarSheet(
        summaryFuture: summaryFuture,
        firstSelectable: today,
        lastSelectable: today.add(const Duration(days: _calendarRangeDays - 1)),
      ),
    );
    if (picked != null) {
      _selectDay(picked.difference(today).inDays);
    }
  }

  /// Звонок/WhatsApp не должны ждать запись события (задача 017, п.5г).
  void _logContact(String driverId, String type) {
    final companyId = ref.read(sessionProvider)?.companyMember?.companyId;
    if (companyId == null) return;
    unawaited(ref.read(cargoRepositoryProvider).logContactEvent(driverId: driverId, companyId: companyId, type: type));
  }

  Future<void> _call(ArrivalListing driver) async {
    if (driver.phone == null) return;
    _logContact(driver.driverId, 'CALL');
    await launchUrl(Uri(scheme: 'tel', path: driver.phone!));
  }

  Future<void> _whatsapp(ArrivalListing driver) async {
    if (driver.phone == null) return;
    _logContact(driver.driverId, 'WHATSAPP');
    final digits = driver.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(Uri.parse('https://wa.me/$digits'), mode: LaunchMode.externalApplication);
  }

  Future<void> _chat(ArrivalListing driver) async {
    setState(() => _openingChatDriverId = driver.driverId);
    try {
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(driverId: driver.driverId);
      if (mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      debugPrint('DriversAtPointScreen: failed to open chat: $e');
      if (mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.chatOpenFailed),
          action: SnackBarAction(label: t.commonRetry, onPressed: () => _chat(driver)),
        ));
      }
    } finally {
      if (mounted) setState(() => _openingChatDriverId = null);
    }
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
    // Точка загрузки — справочник (решение 2026-10-04, «Не привязывать
    // продукт к Хоргосу в текстах»): название подставляется сюда, а не
    // пишется текстом — когда появятся другие точки (008), здесь же будет
    // их выбор.
    final primaryPoint = referenceData.valueOrNull?.points.where((p) => p.isActive).firstOrNull;
    final primaryPointName = primaryPoint?.name.forLanguageCode(locale) ?? '';
    // WhatsApp заблокирован в Китае — логисту оттуда вместо него только чат
    // Lubao (decisions.md «Звонки — обычные, через телефон», задача 017).
    final companyCountryId = ref.watch(sessionProvider)?.company?.countryId;
    final isChinaCompany = referenceData.valueOrNull?.countries.where((c) => c.id == companyCountryId).firstOrNull?.code == 'CN';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.driversAtPointTitle(primaryPointName)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            tooltip: t.driversAtPointPickDate,
            onPressed: () => _openCalendar(context),
          ),
        ],
      ),
      body: referenceData.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DriversAtPointScreen: $e');
          return ErrorView(message: t.commonError);
        },
        data: (refData) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.driversAtPointSubtitle, style: AppTextStyles.caption),
                  if (primaryPointName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(t.driversAtPointDispatchFrom(primaryPointName), style: AppTextStyles.caption),
                  ],
                ],
              ),
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
                        for (final driver in list)
                          _DriverCard(
                            driver: driver,
                            refData: refData,
                            isChinaCompany: isChinaCompany,
                            openingChat: _openingChatDriverId == driver.driverId,
                            onCall: _call,
                            onWhatsapp: _whatsapp,
                            onChat: _chat,
                            onInvite: _invite,
                          ),
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
  const _DriverCard({
    required this.driver,
    required this.refData,
    required this.isChinaCompany,
    required this.openingChat,
    required this.onCall,
    required this.onWhatsapp,
    required this.onChat,
    required this.onInvite,
  });

  final ArrivalListing driver;
  final ReferenceData refData;
  final bool isChinaCompany;
  final bool openingChat;
  final ValueChanged<ArrivalListing> onCall;
  final ValueChanged<ArrivalListing> onWhatsapp;
  final ValueChanged<ArrivalListing> onChat;
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
                        // Задача 033, п.9 — «тент · 20 т · 90 м³ · 33 пал.».
                        if (driver.volumeM3 != null) ...[
                          const Text(' · ', style: AppTextStyles.caption),
                          Text('${driver.volumeM3!.toStringAsFixed(0)} ${t.unitM3}', style: AppTextStyles.caption),
                        ],
                        if (driver.palletsEuro != null) ...[
                          const Text(' · ', style: AppTextStyles.caption),
                          Text('${driver.palletsEuro} ${t.unitPallets}', style: AppTextStyles.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconSquareButton(icon: LucideIcons.phone, onPressed: driver.phone == null ? null : () => onCall(driver)),
              const SizedBox(width: AppSpacing.sm),
              IconSquareButton(icon: LucideIcons.messageSquare, loading: openingChat, onPressed: () => onChat(driver)),
              if (!isChinaCompany) ...[
                const SizedBox(width: AppSpacing.sm),
                IconSquareButton(icon: LucideIcons.messageCircle, onPressed: driver.phone == null ? null : () => onWhatsapp(driver)),
              ],
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

/// Шторка-календарь: месяц за месяцем, под каждым числом — сколько машин
/// планируется на точке в этот день (из того же /arrivals/summary, что и
/// полоса дней). Свой грид вместо showDatePicker — стандартный пикер не
/// даёт подписать ячейки числом машин.
class _ArrivalsCalendarSheet extends StatefulWidget {
  const _ArrivalsCalendarSheet({required this.summaryFuture, required this.firstSelectable, required this.lastSelectable});

  final Future<List<ArrivalSummaryDay>> summaryFuture;
  final DateTime firstSelectable;
  final DateTime lastSelectable;

  @override
  State<_ArrivalsCalendarSheet> createState() => _ArrivalsCalendarSheetState();
}

class _ArrivalsCalendarSheetState extends State<_ArrivalsCalendarSheet> {
  late DateTime _visibleMonth = DateTime(widget.firstSelectable.year, widget.firstSelectable.month);

  bool get _canGoPrevMonth {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    return !prev.isBefore(DateTime(widget.firstSelectable.year, widget.firstSelectable.month));
  }

  bool get _canGoNextMonth {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastSelectable.year, widget.lastSelectable.month));
  }

  bool _inRange(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(widget.firstSelectable) && !d.isAfter(widget.lastSelectable);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final weekdayNames = _weekdayShort[locale] ?? _weekdayShort['ru']!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: FutureBuilder<List<ArrivalSummaryDay>>(
          future: widget.summaryFuture,
          builder: (context, snapshot) {
            final counts = <DateTime, int>{};
            for (final day in snapshot.data ?? const <ArrivalSummaryDay>[]) {
              final local = day.date.toLocal();
              counts[DateTime(local.year, local.month, local.day)] = day.count;
            }

            final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
            final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
            final leadingBlanks = firstOfMonth.weekday - 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft),
                      onPressed: _canGoPrevMonth
                          ? () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1))
                          : null,
                    ),
                    Text(_monthLabel(locale, _visibleMonth), style: AppTextStyles.title),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight),
                      onPressed: _canGoNextMonth
                          ? () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1))
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final name in weekdayNames)
                      Expanded(
                        child: Center(child: Text(name, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
                else
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                      for (var day = 1; day <= daysInMonth; day++)
                        _buildDayCell(context, DateTime(_visibleMonth.year, _visibleMonth.month, day), counts),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, Map<DateTime, int> counts) {
    final enabled = _inRange(date);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final count = counts[date];

    return InkWell(
      onTap: enabled ? () => Navigator.of(context).pop(date) : null,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: isToday ? Border.all(color: AppColors.primary) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTextStyles.bodyStrong.copyWith(color: enabled ? AppColors.text : AppColors.textSecondary),
            ),
            Text(
              enabled ? (count?.toString() ?? '0') : '',
              style: AppTextStyles.small.copyWith(
                color: (count ?? 0) > 0 ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _monthNames = {
  'ru': [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ],
  'kk': [
    'Қаңтар', 'Ақпан', 'Наурыз', 'Сәуір', 'Мамыр', 'Маусым',
    'Шілде', 'Тамыз', 'Қыркүйек', 'Қазан', 'Қараша', 'Желтоқсан',
  ],
  'zh': ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
};

String _monthLabel(String locale, DateTime month) {
  final names = _monthNames[locale] ?? _monthNames['ru']!;
  final name = names[month.month - 1];
  return locale == 'zh' ? '${month.year}年$name' : '$name ${month.year}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
