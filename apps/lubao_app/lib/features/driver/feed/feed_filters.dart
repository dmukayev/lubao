import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../shared/city_picking.dart';

/// 059: чипы «куда», фильтры и сортировка ленты водителя.

String sortLabel(LubaoLocalizations t, FeedSort s) => switch (s) {
      FeedSort.standard => t.feedSortStandard,
      FeedSort.priceAsc => t.feedSortPriceAsc,
      FeedSort.priceDesc => t.feedSortPriceDesc,
      FeedSort.perKm => t.feedSortPerKm,
      FeedSort.ready => t.feedSortReady,
      FeedSort.distanceAsc => t.feedSortDistanceAsc,
      FeedSort.distanceDesc => t.feedSortDistanceDesc,
      FeedSort.newest => t.feedSortNewest,
    };

String readyLabel(LubaoLocalizations t, FeedReady r) => switch (r) {
      FeedReady.any => t.feedReadyAny,
      FeedReady.today => t.feedReadyToday,
      FeedReady.threeDays => t.feedReady3d,
      FeedReady.week => t.feedReadyWeek,
    };

String _num(double v) => formatLimit(v);

/// Полоса над лентой: «Все 42 · Домой 8 · Россия 15 · …» + «Фильтры» + сортировка.
class FeedChipsBar extends ConsumerWidget {
  const FeedChipsBar({super.key, required this.chips, required this.refData});

  final FeedChips chips;
  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final filter = ref.watch(feedFilterProvider);
    final notifier = ref.read(feedFilterProvider.notifier);
    Widget chip(String key, String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            key: Key(key),
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onTap(),
          ),
        );
    return SizedBox(
      height: 48,
      child: ListView(
        key: const Key('feedChipsBar'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: [
          // Фильтры и сортировка — первыми: на узком экране видны сразу.
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Badge(
              isLabelVisible: filter.hasSheetFilters,
              smallSize: 8,
              backgroundColor: AppColors.primary,
              child: ActionChip(
                key: const Key('feedFiltersButton'),
                avatar: const Icon(LucideIcons.slidersHorizontal, size: 16),
                label: Text(t.feedFilters),
                onPressed: () => showFeedFilterSheet(context, ref, refData),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ActionChip(
              key: const Key('feedSortButton'),
              avatar: const Icon(LucideIcons.arrowDownUp, size: 16),
              label: Text(sortLabel(t, filter.sort)),
              onPressed: () => _pickSort(context, ref),
            ),
          ),
          chip('feedChipAll', t.feedChipAll('${chips.all}'), !filter.hasDestination, () => notifier.set(filter.withDestination())),
          if (chips.home > 0) chip('feedChipHome', t.feedChipHome('${chips.home}'), filter.toHome, () => notifier.set(filter.withDestination(home: !filter.toHome))),
          for (final c in chips.countries)
            chip('feedChipCountry-${c.id}', '${refData.countryById(c.id).name.forLanguageCode(locale)} ${c.count}', filter.toCountryId == c.id && filter.toCityId == null,
                () => notifier.set(filter.toCountryId == c.id && filter.toCityId == null ? filter.withDestination() : filter.withDestination(countryId: c.id))),
          for (final c in chips.cities)
            if (refData.cityById(c.id) case final city?)
              chip('feedChipCity-${c.id}', '${city.name.forLanguageCode(locale)} ${c.count}', filter.toCityId == c.id,
                  () => notifier.set(filter.toCityId == c.id ? filter.withDestination() : filter.withDestination(countryId: city.countryId, cityId: c.id))),
        ],
      ),
    );
  }

  Future<void> _pickSort(BuildContext context, WidgetRef ref) async {
    final t = context.l10n;
    final current = ref.read(feedFilterProvider);
    final picked = await showModalBottomSheet<FeedSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in FeedSort.values)
              ListTile(
                key: Key('feedSort-${s.name}'),
                title: Text(sortLabel(t, s)),
                trailing: s == current.sort ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(sheetContext, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(feedFilterProvider.notifier).set(ref.read(feedFilterProvider).copyWith(sort: picked));
  }
}

/// Строка активных фильтров с ✕ над лентой.
class ActiveFeedFilters extends ConsumerWidget {
  const ActiveFeedFilters({super.key, required this.refData});

  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final f = ref.watch(feedFilterProvider);
    final set = ref.read(feedFilterProvider.notifier).set;
    final items = <(String, String, FeedFilter)>[
      if (f.fromCityId != null)
        ('from', '${t.feedFilterFrom}: ${refData.cityById(f.fromCityId)?.name.forLanguageCode(locale) ?? ''}', f.copyWith(fromCityId: null, fromCountryId: null))
      else if (f.fromCountryId != null)
        ('from', '${t.feedFilterFrom}: ${refData.countryById(f.fromCountryId!).name.forLanguageCode(locale)}', f.copyWith(fromCountryId: null)),
      for (final id in f.bodyTypeIds) ('body-$id', refData.bodyTypeById(id).name.forLanguageCode(locale), f.copyWith(bodyTypeIds: [...f.bodyTypeIds]..remove(id))),
      if (f.weightMinT != null || f.weightMaxT != null)
        ('weight', t.feedActiveWeight('${f.weightMinT == null ? '0' : _num(f.weightMinT!)}–${f.weightMaxT == null ? '…' : _num(f.weightMaxT!)}'), f.copyWith(weightMinT: null, weightMaxT: null)),
      if (f.priceMin != null || f.priceMax != null)
        ('price', '${t.feedFilterPrice}: ${f.priceMin == null ? '0' : formatCurrencyAmount(f.priceMin!, f.priceCurrency)}–${f.priceMax == null ? '…' : formatCurrencyAmount(f.priceMax!, f.priceCurrency)}', f.copyWith(priceMin: null, priceMax: null)),
      if (f.perKmMin != null) ('perkm', t.feedActivePerKm('${f.perKmMin}'), f.copyWith(perKmMin: null)),
      if (f.ready != FeedReady.any) ('ready', readyLabel(t, f.ready), f.copyWith(ready: FeedReady.any)),
      if (f.withAdvance) ('advance', t.feedActiveAdvance, f.copyWith(withAdvance: false)),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xs),
      child: Wrap(
        key: const Key('feedActiveFilters'),
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (key, label, without) in items)
            InputChip(key: Key('feedActive-$key'), label: Text(label), onDeleted: () => set(without), deleteIcon: const Icon(LucideIcons.x, size: 16)),
        ],
      ),
    );
  }
}

/// Шторка фильтров с живым счётчиком «Показать: N».
Future<void> showFeedFilterSheet(BuildContext context, WidgetRef ref, ReferenceData refData) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FeedFilterSheet(refData: refData),
  );
}

class _FeedFilterSheet extends ConsumerStatefulWidget {
  const _FeedFilterSheet({required this.refData});

  final ReferenceData refData;

  @override
  ConsumerState<_FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends ConsumerState<_FeedFilterSheet> {
  late FeedFilter _draft = ref.read(feedFilterProvider);
  late final _weightMin = TextEditingController(text: _draft.weightMinT == null ? '' : _num(_draft.weightMinT!));
  late final _weightMax = TextEditingController(text: _draft.weightMaxT == null ? '' : _num(_draft.weightMaxT!));
  late final _priceMin = TextEditingController(text: _draft.priceMin == null ? '' : _num(_draft.priceMin!));
  late final _priceMax = TextEditingController(text: _draft.priceMax == null ? '' : _num(_draft.priceMax!));
  late final _perKm = TextEditingController(text: _draft.perKmMin?.toString() ?? '');
  int? _count;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_weightMin, _weightMax, _priceMin, _priceMax, _perKm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(FeedFilter next) {
    setState(() => _draft = next);
    _refreshCount();
  }

  void _refreshCount() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final n = await ref.read(cargoRepositoryProvider).feedCount(_draft);
        if (mounted) setState(() => _count = n);
      } catch (_) {
        if (mounted) setState(() => _count = null);
      }
    });
  }

  FeedFilter _fromFields(FeedFilter f) => f.copyWith(
        weightMinT: parseDecimal(_weightMin.text),
        weightMaxT: parseDecimal(_weightMax.text),
        priceMin: parseDecimal(_priceMin.text),
        priceMax: parseDecimal(_priceMax.text),
        perKmMin: parseDecimal(_perKm.text)?.round(),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final rd = widget.refData;
    final bodies = rd.bodyTypes.where((b) => b.isActive).toList();
    final destOptions = rd.countryCityOptions(locale, wholeCountrySuffix: t.wholeCountrySuffix);
    final destLabel = _draft.toCountryId == null
        ? ''
        : destOptions.where((o) => o.countryId == _draft.toCountryId && o.cityId == _draft.toCityId).firstOrNull?.label ?? rd.countryById(_draft.toCountryId!).name.forLanguageCode(locale);
    Widget title(String s) => Padding(padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs), child: Text(s, style: AppTextStyles.bodyStrong));
    Widget range(TextEditingController a, TextEditingController b, String keyPrefix) => Row(
          children: [
            Expanded(child: AppTextField(key: Key('$keyPrefix-min'), label: t.feedFilterMin, controller: a, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _update(_fromFields(_draft)))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppTextField(key: Key('$keyPrefix-max'), label: t.feedFilterMax, controller: b, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _update(_fromFields(_draft)))),
          ],
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              key: const Key('feedFilterSheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              children: [
                Text(t.feedFilters, style: AppTextStyles.headline),
                title(t.feedFilterFrom),
                CityField(
                  key: const Key('feedFilterFromCity'),
                  label: t.feedFilterFrom,
                  value: _draft.fromCityId == null ? null : rd.cityById(_draft.fromCityId)?.name.forLanguageCode(locale),
                  onTap: () async {
                    final picked = await pickCity(context, ref, refData: rd, title: t.feedFilterFrom);
                    if (picked != null) _update(_draft.copyWith(fromCityId: picked.cityId, fromCountryId: null));
                  },
                ),
                title(t.feedFilterTo),
                Autocomplete<CountryCityOption>(
                  initialValue: TextEditingValue(text: destLabel),
                  displayStringForOption: (o) => o.label,
                  optionsBuilder: (v) => v.text.isEmpty ? destOptions : destOptions.where((o) => o.label.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (o) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _update(_draft.withDestination(countryId: o.countryId, cityId: o.cityId));
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) => AppTextField(
                    key: const Key('feedFilterTo'),
                    label: t.feedFilterTo,
                    hintText: t.searchCityCountryHint,
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (text) {
                      if (text.isEmpty) _update(_draft.withDestination());
                    },
                  ),
                ),
                title(t.feedFilterBody),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SelectableTile(key: const Key('feedFilterBodyMine'), label: t.feedFilterBodyMine, selected: _draft.bodyTypeIds.isEmpty, onTap: () => _update(_draft.copyWith(bodyTypeIds: const []))),
                    for (final b in bodies)
                      SelectableTile(
                        key: Key('feedFilterBody-${b.id}'),
                        label: b.name.forLanguageCode(locale),
                        selected: _draft.bodyTypeIds.contains(b.id),
                        onTap: () {
                          final list = [..._draft.bodyTypeIds];
                          list.contains(b.id) ? list.remove(b.id) : list.add(b.id);
                          _update(_draft.copyWith(bodyTypeIds: list));
                        },
                      ),
                  ],
                ),
                title(t.feedFilterWeight),
                range(_weightMin, _weightMax, 'feedFilterWeight'),
                title(t.feedFilterPrice),
                Row(
                  children: [
                    Expanded(child: range(_priceMin, _priceMax, 'feedFilterPrice')),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<Currency>(
                      key: const Key('feedFilterPriceCurrency'),
                      value: _draft.priceCurrency,
                      items: [for (final c in Currency.values) DropdownMenuItem(value: c, child: Text(currencySymbol(c)))],
                      onChanged: (c) => c == null ? null : _update(_draft.copyWith(priceCurrency: c)),
                    ),
                  ],
                ),
                title(t.feedFilterPerKm),
                AppTextField(key: const Key('feedFilterPerKm'), label: t.feedFilterPerKm, controller: _perKm, keyboardType: TextInputType.number, onChanged: (_) => _update(_fromFields(_draft))),
                title(t.feedFilterReady),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final r in FeedReady.values)
                      SelectableTile(key: Key('feedFilterReady-${r.name}'), label: readyLabel(t, r), selected: _draft.ready == r, onTap: () => _update(_draft.copyWith(ready: r))),
                  ],
                ),
                SwitchListTile(
                  key: const Key('feedFilterAdvance'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.feedFilterAdvance),
                  value: _draft.withAdvance,
                  onChanged: (v) => _update(_draft.copyWith(withAdvance: v)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
              child: Row(
                children: [
                  TextButton(
                    key: const Key('feedFilterReset'),
                    onPressed: () {
                      for (final c in [_weightMin, _weightMax, _priceMin, _priceMax, _perKm]) {
                        c.clear();
                      }
                      _update(_draft.resetSheet());
                    },
                    child: Text(t.feedFilterReset),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      key: const Key('feedFilterShow'),
                      label: t.feedFilterShow(_count == null ? '…' : '$_count'),
                      onPressed: () {
                        ref.read(feedFilterProvider.notifier).set(_draft);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
