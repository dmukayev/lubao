import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/city_picking.dart';
import '../../shared/status_helpers.dart';
import '../haul_hint.dart';
import '../../shared/driver_vehicle_photos.dart';

class DriversAtPointScreen extends ConsumerStatefulWidget {
  const DriversAtPointScreen({super.key});

  @override
  ConsumerState<DriversAtPointScreen> createState() => _DriversAtPointScreenState();
}

const _dayStripLength = 7;

const _capacityOptions = [10, 15, 20, 22, 25];

/// Диапазон для календаря — с запасом: водитель анонсирует прибытие максимум
/// на +14 дней (задача 015), остальное в календаре честно покажет 0.
const _calendarRangeDays = 90;

class _DriversAtPointScreenState extends ConsumerState<DriversAtPointScreen> {
  String? _countryId;
  String? _bodyTypeId;
  String? _pointId;
  int? _minCapacityTons;
  bool _verifiedOnly = false;
  int _dayOffset = 0;
  Future<List<ArrivalListing>>? _future;
  Future<List<ArrivalSummaryDay>>? _summaryFuture;
  String? _openingChatDriverId;

  @override
  void initState() {
    super.initState();
    _initCity();
  }

  /// По умолчанию — город последнего груза компании (040, п.8); нет грузов —
  /// все города, логист выбирает сам.
  Future<void> _initCity() async {
    try {
      final cargos = await ref.read(myCargosProvider.future);
      _pointId = cargos.firstOrNull?.pointId;
    } catch (e) {
      debugPrint('DriversAtPointScreen: default city failed: $e');
    }
    if (!mounted) return;
    _loadSummary();
    _reload();
  }

  void _loadSummary() {
    _summaryFuture = ref.read(arrivalRepositoryProvider).summary(days: _dayStripLength, pointId: _pointId);
  }

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _dayOffset));

  void _reload() {
    setState(() {
      _future = ref
          .read(arrivalRepositoryProvider)
          .listForCompany(
            date: _selectedDate,
            pointId: _pointId,
            countryId: _countryId,
            bodyTypeId: _bodyTypeId,
            minCapacityTons: _minCapacityTons?.toDouble(),
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
    final summaryFuture = ref.read(arrivalRepositoryProvider).summary(days: _calendarRangeDays, pointId: _pointId);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
      ),
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

  /// Номер водителя — по нажатию (043 п.11): только проверенной компании,
  /// с суточным лимитом; contact_event пишет сервер.
  Future<String?> _revealPhone(ArrivalListing driver, String type) async {
    try {
      return await ref.read(cargoRepositoryProvider).revealDriverContact(driver.driverId, type: type);
    } catch (e) {
      debugPrint('DriversAtPointScreen: reveal contact: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(contactErrorText(context.l10n, e))));
      return null;
    }
  }

  Future<void> _call(ArrivalListing driver) async {
    final phone = await _revealPhone(driver, 'CALL');
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _whatsapp(ArrivalListing driver) async {
    final phone = await _revealPhone(driver, 'WHATSAPP');
    if (phone == null) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.chatOpenFailed),
            action: SnackBarAction(label: t.commonRetry, onPressed: () => _chat(driver)),
          ),
        );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
      ),
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

    // Задача 038, п.9 (037, п.3) — водитель уже занят и новый груз, похоже,
    // не поместится: предупреждаем, но не запрещаем (жёсткая проверка — на
    // подтверждении водителем).
    if (refData != null &&
        haulLooksFull(
          activeDealsCount: driver.activeDealsCount,
          committedWeightKg: driver.committedWeightKg,
          hasUnknownWeight: driver.committedHasUnknownWeight,
          capacityTons: driver.capacityTons,
          newCargoWeightKg: selectedCargo.weightKg,
        )) {
      final hint = haulHintText(
        t,
        refData,
        locale,
        activeDealsCount: driver.activeDealsCount,
        committedWeightKg: driver.committedWeightKg,
        hasUnknownWeight: driver.committedHasUnknownWeight,
        capacityTons: driver.capacityTons,
        destinationCountryId: driver.committedDestinationCountryId,
        destinationCityId: driver.committedDestinationCityId,
        readyDate: driver.committedReadyDate,
      );
      final proceed = await confirmSelectBusyDriver(context, hint ?? '');
      if (!proceed || !mounted) return;
    }

    try {
      await ref.read(cargoRepositoryProvider).inviteDriver(selectedCargo.id, driver.driverId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseConflictText(t, e) ?? t.commonError)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.driversAtPointInviteSent)));
  }

  /// Выбор из нижнего листа (задача 036, п.4): «Страна ▾» / «Кузов ▾» —
  /// первый пункт сбрасывает фильтр. Возвращает выбранный id или null
  /// («Любая»/«Все»); отмена листа (свайп вниз) — `_sheetDismissed`.
  Future<Object?> _pickFromSheet(
    BuildContext context, {
    required String title,
    String? anyLabel,
    required List<(String id, String label)> options,
    required String? current,
  }) {
    return showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
                child: Text(title, style: AppTextStyles.title),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (anyLabel != null)
                      ListTile(
                        title: Text(anyLabel),
                        trailing: current == null ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                        onTap: () => Navigator.pop(sheetContext, _clearFilter),
                      ),
                    for (final option in options)
                      ListTile(
                        title: Text(option.$2),
                        trailing: current == option.$1 ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                        onTap: () => Navigator.pop(sheetContext, option.$1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _clearFilter = '__clear__';

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final referenceData = ref.watch(referenceDataProvider);
    // Точка загрузки — справочник (решение 2026-10-04, «Не привязывать
    // продукт к Хоргосу в текстах»): название берётся из справочника.
    // Чип точки (задача 036, п.1) — только когда активных точек больше
    // одной; единственную точку показывать незачем.
    final activePoints = referenceData.valueOrNull?.points.where((p) => p.isActive).toList() ?? const [];
    final selectedPoint = activePoints.where((p) => p.id == _pointId).firstOrNull;
    final selectedPointName = selectedPoint?.name.forLanguageCode(locale);
    // WhatsApp заблокирован в Китае — логисту оттуда вместо него только чат
    // Lubao (decisions.md «Звонки — обычные, через телефон», задача 017).
    final companyCountryId = ref.watch(sessionProvider)?.company?.countryId;
    final isChinaCompany =
        referenceData.valueOrNull?.countries.where((c) => c.id == companyCountryId).firstOrNull?.code == 'CN';

    return Scaffold(
      // AppBar сам отступает от выреза/строки статуса (задача 036, п.9) —
      // фиксированных отступов сверху нет.
      appBar: AppBar(
        title: Text(t.driversAtPointTitleShort),
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
        data: (refData) {
          final selectedCountry = _countryId == null ? null : refData.countryById(_countryId!);
          final selectedBodyType = _bodyTypeId == null ? null : refData.bodyTypeById(_bodyTypeId!);

          return Column(
            children: [
              // «Кто свободен: <город>» — город выбирается здесь же (040, п.8).
              InkWell(
                key: const Key('driversPointChip'),
                onTap: () async {
                  final picked = await pickCity(context, ref, refData: refData, selectedId: _pointId, title: t.driversAtPointPickPoint);
                  if (picked == null) return;
                  setState(() {
                    _pointId = picked.id;
                    _loadSummary();
                  });
                  _reload();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedPointName == null ? t.cityPickerTitle : t.driversAtPointTitle(selectedPointName),
                          style: AppTextStyles.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(LucideIcons.chevronDown, size: 20),
                    ],
                  ),
                ),
              ),
              // Полоса дней — квадратные плашки 52×52 (задача 036, п.3).
              SizedBox(
                height: 60,
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
                          label: index == 0 ? t.driversAtPointTodayShort : _weekdayLabel(t, date),
                          count: count,
                          selected: _dayOffset == index,
                          onTap: () => _selectDay(index),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Фильтры — одна строка чипов с горизонтальной прокруткой
              // (задача 036, п.4); активный — синий, со значением.
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  children: [
                    _FilterChip(
                      label: selectedCountry?.name.forLanguageCode(locale) ?? t.driversAtPointFilterCountry,
                      active: _countryId != null,
                      dropdown: true,
                      onTap: () async {
                        final picked = await _pickFromSheet(
                          context,
                          title: t.driversAtPointFilterCountry,
                          anyLabel: t.driverSetupAnyCountry,
                          options: [for (final c in refData.countries) (c.id, c.name.forLanguageCode(locale))],
                          current: _countryId,
                        );
                        if (picked == null) return; // лист закрыт без выбора
                        _countryId = picked == _clearFilter ? null : picked as String;
                        _reload();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      label: selectedBodyType?.name.forLanguageCode(locale) ?? t.driversAtPointFilterBodyType,
                      active: _bodyTypeId != null,
                      dropdown: true,
                      onTap: () async {
                        final picked = await _pickFromSheet(
                          context,
                          title: t.driversAtPointFilterBodyType,
                          anyLabel: t.driversAtPointFilterAll,
                          options: [for (final b in refData.bodyTypes) (b.id, b.name.forLanguageCode(locale))],
                          current: _bodyTypeId,
                        );
                        if (picked == null) return;
                        _bodyTypeId = picked == _clearFilter ? null : picked as String;
                        _reload();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      key: const Key('driversFilterCapacity'),
                      label: _minCapacityTons == null
                          ? t.driversAtPointFilterCapacityChip
                          : t.driversAtPointMinCapacityLabel(_minCapacityTons!),
                      active: _minCapacityTons != null,
                      dropdown: _minCapacityTons == null,
                      onTap: () async {
                        final picked = await _pickFromSheet(
                          context,
                          title: t.driversAtPointFilterMinCapacityTitle,
                          anyLabel: t.driversAtPointFilterAll,
                          options: [for (final n in _capacityOptions) ('$n', t.driversAtPointMinCapacityLabel(n))],
                          current: _minCapacityTons?.toString(),
                        );
                        if (picked == null) return;
                        _minCapacityTons = picked == _clearFilter ? null : int.parse(picked as String);
                        _reload();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterChip(
                      key: const Key('driversFilterVerified'),
                      label: t.driversAtPointFilterVerifiedChip,
                      active: _verifiedOnly,
                      leadingCheck: _verifiedOnly,
                      onTap: () {
                        _verifiedOnly = !_verifiedOnly;
                        _reload();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: FutureBuilder<List<ArrivalListing>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (_future == null || snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
                    if (snapshot.hasError) return ErrorView(message: t.commonError, onRetry: _reload);
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) return EmptyState(message: t.driversAtPointEmpty, icon: LucideIcons.users);

                    final onSite = list.where((d) => d.status == ArrivalStatus.onSite).length;
                    final planned = list.length - onSite;
                    // Строка итогов (задача 036, п.5): сегодня — «На месте
                    // сейчас · N» и «ещё M будут сегодня»; другой день —
                    // «Будут <дата> · N».
                    final summaryLeft = _dayOffset == 0
                        ? t.driversAtPointNowAtPlace(onSite)
                        : t.driversAtPointWillBeOnDay(_shortDate(_selectedDate), list.length);
                    final summaryRight = _dayOffset == 0 && planned > 0 ? t.driversAtPointMoreToday(planned) : null;

                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    summaryLeft,
                                    style: AppTextStyles.bodyStrong,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (summaryRight != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      summaryRight,
                                      style: AppTextStyles.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
          );
        },
      ),
    );
  }
}

String _shortDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}';
}

/// Короткое имя дня недели из ARB (задача 036, п.3) — раньше было
/// захардкожено и без английского.
List<String> _weekdayNames(LubaoLocalizations t) => [
  t.weekdayShort1,
  t.weekdayShort2,
  t.weekdayShort3,
  t.weekdayShort4,
  t.weekdayShort5,
  t.weekdayShort6,
  t.weekdayShort7,
];

String _weekdayLabel(LubaoLocalizations t, DateTime date) => _weekdayNames(t)[date.weekday - 1];

/// Плашка дня 52×52 (задача 036, п.3): день сверху, число водителей ниже;
/// ноль — серым, выбранный — синий. Шрифт ограничен масштабом 1.0..1.2,
/// чтобы 52×52 не ломалась на крупном системном шрифте.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;
    final fg = selected ? Colors.white : AppColors.text;
    final muted = selected ? Colors.white70 : AppColors.textSecondary;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: AppTextStyles.caption.copyWith(color: muted), maxLines: 1),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count?.toString() ?? '–',
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: isZero && !selected ? AppColors.textSecondary.withAlpha(150) : fg,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Чип фильтра (задача 036, п.4): серый — не задан, синий — активен.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.dropdown = false,
    this.leadingCheck = false,
  });

  final String label;
  final bool active;
  final bool dropdown;
  final bool leadingCheck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.text;
    return Material(
      color: active ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: active ? AppColors.primary.withAlpha(90) : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingCheck) ...[
                Icon(LucideIcons.check, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: AppTextStyles.bodyStrong.copyWith(color: color)),
              if (dropdown) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(LucideIcons.chevronDown, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// «Ерлан Тохтаров» → «Ерлан Т.» (задача 036, п.6) — компактное имя.
String _shortName(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  if (parts.length < 2 || parts[1].isEmpty) return full.trim();
  return '${parts[0]} ${parts[1].substring(0, 1).toUpperCase()}.';
}

/// Цвет аватара по водителю — стабильный, из палитры эталона 27.
const _avatarColors = [
  AppColors.primary,
  Color(0xFF2DA05A),
  Color(0xFF8B5CF6),
  Color(0xFFF08A24),
  Color(0xFF0EA5B7),
  Color(0xFFE5484D),
];

Color _avatarColor(String seed) => _avatarColors[seed.codeUnits.fold<int>(0, (a, b) => a + b) % _avatarColors.length];

String _initials(String full) {
  final parts = full.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final first = parts[0].substring(0, 1).toUpperCase();
  return parts.length > 1 ? '$first${parts[1].substring(0, 1).toUpperCase()}' : first;
}

/// Компактная карточка водителя (задача 036, п.6): аватар, имя, ✓, рейтинг;
/// «кузов · тоннаж · объём · страны»; статус и кнопки (звонок, чат,
/// «Пригласить»). WhatsApp (не для китайских компаний) и статус при
/// нехватке ширины уходят на свою строку, а не вызывают переполнение.
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

  String _ago(LubaoLocalizations t, DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inMinutes < 1) return t.driversAtPointAgoJustNow;
    if (diff.inMinutes < 60) return t.driversAtPointAgoMinutes(diff.inMinutes);
    return t.driversAtPointAgoHours(diff.inHours);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final bodyType = driver.bodyTypeId == null ? null : refData.bodyTypeById(driver.bodyTypeId!);
    final onSite = driver.status == ArrivalStatus.onSite;

    // «тент · 20 т · 90 м³ · 33 пал. · KZ UZ KG» — одна строка, обрезается.
    final countries = driver.anyCountry
        ? t.driverSetupAnyCountry
        : driver.directionCountryIds.map((id) => refData.countryById(id).code).join(' ');
    // 048 п.6: необъёмный кузов — строка по профилю («Цистерна · 30 000 л · Пищевое»).
    final profileLine = bodyType != null && !bodyType.isVolume && driver.specs != null ? specsSummary(t, locale, bodyType, driver.specs) : null;
    final spec = profileLine != null
        ? [profileLine, if (countries.isNotEmpty) countries].join(' · ')
        : [
      if (bodyType != null) bodyType.name.forLanguageCode(locale),
      if (driver.capacityTons != null) '${driver.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
      // 045 п.6: «м³ · пал.» — только у объёмных кузовов.
      if (driver.volumeM3 != null && isVolumeBodyType(bodyType?.code)) '${driver.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
      if (driver.palletsEuro != null && isVolumeBodyType(bodyType?.code)) '${driver.palletsEuro} ${t.unitPallets}',
      if (countries.isNotEmpty) countries,
    ].join(' · ');

    final statusText = onSite
        ? t.driversAtPointOnSiteAgo(_ago(t, driver.arrivedAt ?? driver.plannedAt))
        : t.driversAtPointPlannedApprox(_plannedDayLabel(t), _timeOf(driver.plannedAt));
    final statusColor = onSite ? AppColors.success : AppColors.primary;
    final statusStyle = AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600);
    // Иконка вместо эмодзи: эмодзи нет в шрифте, на части устройств рисуется «?».
    final status = Text.rich(
      TextSpan(
        style: statusStyle,
        children: [
          if (onSite) WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(LucideIcons.mapPin, size: 14, color: statusColor))),
          TextSpan(text: statusText),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    final haulHint = driver.activeDealsCount > 0
        ? haulHintText(
            t,
            refData,
            locale,
            activeDealsCount: driver.activeDealsCount,
            committedWeightKg: driver.committedWeightKg,
            hasUnknownWeight: driver.committedHasUnknownWeight,
            capacityTons: driver.capacityTons,
            destinationCountryId: driver.committedDestinationCountryId,
            destinationCityId: driver.committedDestinationCityId,
            readyDate: driver.committedReadyDate,
          )
        : null;

    final buttons = <Widget>[
      IconSquareButton(
        key: Key('driversAtPointCall-${driver.driverId}'),
        size: 34,
        icon: LucideIcons.phone,
        onPressed: driver.hasPhone ? () => onCall(driver) : null,
      ),
      const SizedBox(width: AppSpacing.xs + 2),
      IconSquareButton(
        key: Key('driversAtPointChat-${driver.driverId}'),
        size: 34,
        icon: LucideIcons.messageSquare,
        loading: openingChat,
        onPressed: () => onChat(driver),
      ),
      if (!isChinaCompany) ...[
        const SizedBox(width: AppSpacing.xs + 2),
        IconSquareButton(
          key: Key('driversAtPointWhatsapp-${driver.driverId}'),
          size: 34,
          child: const WhatsAppIcon(size: 18),
          background: WhatsAppIcon.whatsappSoft,
          semanticLabel: context.l10n.commonWhatsApp,
          onPressed: driver.hasPhone ? () => onWhatsapp(driver) : null,
        ),
      ],
    ];
    final invite = SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: () => onInvite(driver),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(t.driversAtPointInviteShort, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    return AppCard(
      key: Key('driversAtPointCard-${driver.driverId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _avatarColor(driver.driverId),
                child: Text(
                  _initials(driver.driverName),
                  style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _shortName(driver.driverName),
                            style: AppTextStyles.bodyStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (driver.isVerified) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            key: Key('driverVerifiedPill-${driver.driverId}'),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(LucideIcons.check, size: 16, color: AppColors.success),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(LucideIcons.star, size: 13, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(
                          driver.ratingCount > 0 ? driver.ratingAvg.toStringAsFixed(1) : '–',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    if (spec.isNotEmpty)
                      // 045 п.4: миниатюра кузова (40 px) перед строкой машины.
                      // 044 п.7: тап по строке машины — её фото («Фото нет», если не добавлены).
                      InkWell(
                        key: Key('driversAtPointPhotos-${driver.driverId}'),
                        onTap: () => showDriverVehiclePhotos(context, driverId: driver.driverId, driverName: driver.driverName),
                        child: Row(
                          children: [
                            BodyTypeIcon(bodyTypeCode: bodyType?.code, width: 40),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: Text(spec, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const Icon(LucideIcons.image, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (haulHint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              haulHint,
              style: AppTextStyles.caption.copyWith(color: AppColors.accentText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // 046 п.3: «отменил 1 из 15 · после загрузки 1»; старый сервер — прежняя строка.
          if (cancelStatsText(t, driver.cancelStats) case final stats?)
            Text(stats, key: const Key('driverCancelStats'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))
          else if (driver.cancelStats == null && driver.dealsCancelledByDriver > 0)
            Text(
              t.driverCancelShare(driver.dealsCancelledByDriver, driver.dealsTotal),
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              // Статус и кнопки в одну строку, если хватает места (эталон
              // 27); иначе статус — отдельной строкой, ничего не переполняется.
              final sameRow = constraints.maxWidth >= (isChinaCompany ? 260 : 300);
              if (sameRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: AppSpacing.sm),
                    ...buttons,
                    const SizedBox(width: AppSpacing.sm),
                    invite,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  status,
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      ...buttons,
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: invite),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _plannedDayLabel(LubaoLocalizations t) {
    final now = DateTime.now();
    // День — календарный (plannedDay), без пересчёта часовых поясов.
    final day = driver.plannedDay;
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    return isToday ? t.driversAtPointToday : _weekdayLabel(t, day);
  }

  String _timeOf(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Шторка-календарь: месяц за месяцем, под каждым числом — сколько машин
/// планируется на точке в этот день (из того же /arrivals/summary, что и
/// полоса дней). Свой грид вместо showDatePicker — стандартный пикер не
/// даёт подписать ячейки числом машин.
class _ArrivalsCalendarSheet extends StatefulWidget {
  const _ArrivalsCalendarSheet({
    required this.summaryFuture,
    required this.firstSelectable,
    required this.lastSelectable,
  });

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
    final weekdayNames = _weekdayNames(context.l10n);

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
                        child: Center(
                          child: Text(name, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
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

String _monthLabel(String locale, DateTime month) {
  final text = DateFormat.yMMMM(locale).format(month);
  return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
