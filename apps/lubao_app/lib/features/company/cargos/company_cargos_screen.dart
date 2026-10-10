import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/city_picking.dart';
import '../../shared/share_action.dart';
import '../../shared/status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/share_link_prompt.dart';
import '../company_shell.dart';

/// 056 п.2: «Грузы» логиста — Активные (по умолчанию) / В работе / Архив, с
/// числами на вкладках. Нажатие: в «Активных» — отклики груза; в «В работе» и
/// «Архиве» — сделка (если была), иначе экран груза. «Повторить» (п.3) — в
/// «Активных» и «Архиве».
class CompanyCargosScreen extends ConsumerStatefulWidget {
  const CompanyCargosScreen({super.key, this.initialTab = CompanyCargoTab.active});

  final CompanyCargoTab initialTab;

  @override
  ConsumerState<CompanyCargosScreen> createState() => _CompanyCargosScreenState();
}

class _CompanyCargosScreenState extends ConsumerState<CompanyCargosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: CompanyCargoTab.values.length, vsync: this, initialIndex: widget.initialTab.index);
  Map<CompanyCargoTab, int> _counts = const {};
  int _reload = 0;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Новый/повторённый груз опубликован — списки и числа заново.
  Future<void> _openForm(String path, {Object? extra}) async {
    await context.push(path, extra: extra);
    if (!mounted) return;
    ref.invalidate(myCargosProvider);
    setState(() => _reload++);
  }

  String _tabLabel(LubaoLocalizations t, CompanyCargoTab tab) {
    final name = switch (tab) {
      CompanyCargoTab.active => t.cargosTabActive,
      CompanyCargoTab.work => t.cargosTabWork,
      CompanyCargoTab.archive => t.cargosTabArchive,
    };
    final n = _counts[tab];
    return n == null || n == 0 || tab == CompanyCargoTab.archive ? name : '$name $n';
  }

  /// 052 п.4: «Все» — до 10 активных грузов одной строкой каждый + ссылка /co.
  Future<void> _shareAll() async {
    final t = context.l10n;
    final company = ref.read(sessionProvider)?.company;
    final refData = ref.read(referenceDataProvider).valueOrNull;
    if (company == null || refData == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    List<Cargo> active;
    try {
      active = (await ref.read(cargoRepositoryProvider).companyTab(CompanyCargoTab.active, limit: 10)).items;
    } catch (_) {
      active = const [];
    }
    if (!mounted) return;
    await shareContent(
      context,
      ref,
      kind: ShareKind.company,
      targetId: company.id,
      dialogTitle: t.shareDialogAll,
      buildText: (url) => companyShareText(t, refData, company.name, active, url, lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.myCargosTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              key: const Key('shareAllCargos'),
              onPressed: _shareAll,
              icon: const Icon(LucideIcons.share, size: 18),
              label: Text(kIsWebWide(context) ? t.shareAllWeb : t.shareAllButton),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final tab in CompanyCargoTab.values) Tab(key: Key('companyCargosTab-${tab.name}'), text: _tabLabel(t, tab)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('companyPostCargoFab'),
        onPressed: () => _openForm('/company/cargos/new'),
        icon: const Icon(LucideIcons.plus),
        label: Text(t.postCargoTitle),
      ),
      body: Column(
        children: [
          const ShareLinkPrompt(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final tab in CompanyCargoTab.values)
                  _CargoTabList(
                    key: ValueKey('${tab.name}-$_reload'),
                    tab: tab,
                    onCounts: (counts) {
                      if (mounted && counts.toString() != _counts.toString()) setState(() => _counts = counts);
                    },
                    onRepeat: (cargo) => _openForm('/company/cargos/repeat', extra: cargo),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CargoTabList extends ConsumerStatefulWidget {
  const _CargoTabList({super.key, required this.tab, required this.onCounts, required this.onRepeat});

  final CompanyCargoTab tab;
  final ValueChanged<Map<CompanyCargoTab, int>> onCounts;
  final ValueChanged<Cargo> onRepeat;

  @override
  ConsumerState<_CargoTabList> createState() => _CargoTabListState();
}

class _CargoTabListState extends ConsumerState<_CargoTabList> with AutomaticKeepAliveClientMixin {
  final _items = <Cargo>[];
  final _scroll = ScrollController();
  int _total = 0;
  bool _loading = false;
  Object? _error;
  // Поиск в архиве: город (погрузки или назначения) и период погрузки.
  LoadingPoint? _city;
  DateTimeRange? _period;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _refreshDebounce;
  bool _refreshPending = false;

  @override
  bool get wantKeepAlive => true;

  /// Водитель сменил статус сделки («Загружен», «В пути»…) — список и числа
  /// вкладок заново без «потяните, чтобы обновить»; после обрыва сокета — тоже
  /// (события за это время пропущены). Пачку событий сводим в одну загрузку.
  void _refreshSoon(Object? _) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_loading) {
        _refreshPending = true;
      } else {
        _load(reset: true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    final realtime = ref.read(realtimeServiceProvider);
    _subs
      ..add(realtime.onDealUpdated.listen(_refreshSoon))
      ..add(realtime.onReconnected.listen(_refreshSoon));
    _load(reset: true);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _refreshDebounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(cargoRepositoryProvider).companyTab(
            widget.tab,
            offset: reset ? 0 : _items.length,
            cityId: _city?.cityId,
            from: _period == null ? null : _date(_period!.start),
            to: _period == null ? null : _date(_period!.end),
          );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _total = page.total;
      });
      widget.onCounts(page.counts);
    } catch (e) {
      debugPrint('CompanyCargosScreen(${widget.tab.name}): $e');
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (_refreshPending && mounted) {
      _refreshPending = false;
      _load(reset: true);
    }
  }

  void _loadMore() {
    if (!_loading && _items.length < _total) _load();
  }

  Future<void> _pickCity(ReferenceData refData) async {
    final picked = await pickCity(context, ref, refData: refData, selectedId: _city?.id, title: context.l10n.cargosArchiveCity);
    if (picked == null || !mounted) return;
    setState(() => _city = picked);
    _load(reset: true);
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _period,
    );
    if (picked == null || !mounted) return;
    setState(() => _period = picked);
    _load(reset: true);
  }

  Future<void> _open(Cargo cargo) async {
    final deal = cargo.activeDeal;
    if (widget.tab != CompanyCargoTab.active && deal != null) {
      await context.push('/deal/${deal.id}');
    } else {
      await context.push('/company/cargos/${cargo.id}/responses');
    }
    // 057 п.17: открыл отклики — «новые» погасли на сервере; список и цифра на
    // вкладке «Грузы» — заново, без ухода с вкладки.
    if (!mounted) return;
    ref.invalidate(companyCargoCountsProvider);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = context.l10n;
    final refData = ref.watch(referenceDataProvider).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;
    final isArchive = widget.tab == CompanyCargoTab.archive;

    final filters = !isArchive || refData == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ActionChip(
                  key: const Key('cargosArchiveCity'),
                  avatar: const Icon(LucideIcons.mapPin, size: 16),
                  label: Text(_city?.name.forLanguageCode(locale) ?? t.cargosArchiveCity),
                  onPressed: () => _pickCity(refData),
                ),
                ActionChip(
                  key: const Key('cargosArchivePeriod'),
                  avatar: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(_period == null ? t.cargosArchivePeriod : '${formatDate(_period!.start)} – ${formatDate(_period!.end)}'),
                  onPressed: _pickPeriod,
                ),
                if (_city != null || _period != null)
                  TextButton(
                    key: const Key('cargosArchiveReset'),
                    onPressed: () {
                      setState(() {
                        _city = null;
                        _period = null;
                      });
                      _load(reset: true);
                    },
                    child: Text(t.cargosArchiveReset),
                  ),
              ],
            ),
          );

    Widget body;
    if (_items.isEmpty && _loading) {
      body = const LoadingView();
    } else if (_items.isEmpty && _error != null) {
      body = ErrorView(message: t.commonError, onRetry: () => _load(reset: true));
    } else if (_items.isEmpty) {
      body = ListView(children: [
        const SizedBox(height: AppSpacing.xxl),
        EmptyState(
          message: switch (widget.tab) {
            CompanyCargoTab.active => t.cargosEmptyActive,
            CompanyCargoTab.work => t.cargosEmptyWork,
            CompanyCargoTab.archive => t.cargosEmptyArchive,
          },
        ),
      ]);
    } else {
      body = ListView.builder(
        key: Key('companyCargosList-${widget.tab.name}'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        // Внизу место под кнопку «Опубликовать груз».
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        itemCount: _items.length + (_items.length < _total ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Center(child: CircularProgressIndicator()));
          }
          return _card(context, refData, _items[index]);
        },
      );
    }

    return Column(
      children: [
        if (filters != null) filters,
        Expanded(child: RefreshIndicator(onRefresh: () => _load(reset: true), child: body)),
      ],
    );
  }

  Widget _card(BuildContext context, ReferenceData? refData, Cargo cargo) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final country = refData?.countryById(cargo.destinationCountryId);
    final city = refData?.cityById(cargo.destinationCityId);
    final destinationLabel = country == null
        ? ''
        : [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
    final bodyType = refData?.bodyTypeById(cargo.bodyTypeId);
    // Груз в сделке — на плашке шаг сделки («Загружен», «В пути»…), а не общее «В сделке».
    final deal = cargo.activeDeal;
    final (statusLabel, statusColor) = deal != null ? dealStatusPresentation(t, deal.status) : cargoStatusPresentation(t, cargo.status);
    final canRepeat = widget.tab != CompanyCargoTab.work;
    final showResponses = widget.tab == CompanyCargoTab.active;

    return CargoCard(
      key: Key('companyCargoCard-${cargo.id}'),
      originLabel: refData?.pointOrNull(cargo.pointId)?.name.forLanguageCode(locale),
      partialLabel: cargo.allowPartial ? t.feedBadgePartial : null,
      destinationLabel: destinationLabel,
      // Как у водителя в ленте: кузов и расстояние по дорогам («тент · 1 230 км»).
      bodyTypeLabel: [
        bodyType?.name.forLanguageCode(locale) ?? '',
        if (cargo.distanceKm != null) '${formatThousands(cargo.distanceKm!)} ${t.unitKm}',
      ].where((s) => s.isNotEmpty).join(' · '),
      priceLabel: formatMoney(cargo.price, cargo.currency),
      secondaryPriceLabel: refData == null ? null : formatKztConversion(refData.convertToKzt(cargo.price, cargo.currency)),
      readyDateLabel: formatDate(cargo.readyDate),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => _open(cargo),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (deal != null) _DealDriverRow(deal: deal),
          if (showResponses || canRepeat)
            Row(
              children: [
                if (showResponses)
                  Expanded(
                    child: Text.rich(
                      key: Key('cargoResponsesLine-${cargo.id}'),
                      TextSpan(
                        text: t.cargoResponsesCount(cargo.responsesCount),
                        children: [
                          if (cargo.newResponsesCount > 0)
                            TextSpan(
                              text: ' · ${t.cargoResponsesNew(cargo.newResponsesCount)}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                      style: AppTextStyles.caption,
                    ),
                  )
                else
                  const Spacer(),
                if (showResponses)
                  IconButton(
                    key: Key('cargoShare-${cargo.id}'),
                    tooltip: t.shareButton,
                    icon: const Icon(LucideIcons.share, size: 20, color: AppColors.primary),
                    onPressed: () {
                      final rd = refData;
                      if (rd == null) return;
                      shareContent(
                        context,
                        ref,
                        kind: ShareKind.cargo,
                        targetId: cargo.id,
                        dialogTitle: t.shareDialogCargo,
                        buildText: (url) => cargoShareText(t, rd, cargo, url, locale),
                      );
                    },
                  ),
                if (canRepeat)
                  TextButton.icon(
                    key: Key('cargoRepeat-${cargo.id}'),
                    onPressed: () => widget.onRepeat(cargo),
                    icon: const Icon(LucideIcons.rotateCw, size: 16),
                    label: Text(t.cargoRepeat),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// «Водитель: <имя> · подтвердил» + «Документы» / «· ждём подтверждения» (044 п.3).
class _DealDriverRow extends StatelessWidget {
  const _DealDriverRow({required this.deal});
  final CargoActiveDeal deal;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final confirmed = deal.status != DealStatus.selected;
    return Row(
      key: Key('cargoDealDriver-${deal.id}'),
      children: [
        Icon(confirmed ? LucideIcons.checkCircle2 : LucideIcons.clock, size: 16, color: confirmed ? AppColors.success : AppColors.accentText),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            confirmed ? t.cargoDealDriverConfirmed(deal.driverName) : t.cargoDealDriverWaiting(deal.driverName),
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (confirmed)
          TextButton(
            key: Key('cargoDealDocs-${deal.id}'),
            onPressed: () => context.push('/deal/${deal.id}'),
            child: Text(t.driverDocsOpen),
          ),
      ],
    );
  }
}

/// Веб на широком экране — подпись «Поделиться всеми», на телефоне — «Все».
bool kIsWebWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

