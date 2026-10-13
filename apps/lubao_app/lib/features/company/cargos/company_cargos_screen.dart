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
import '../../shared/cargo_price_column.dart';
import '../../shared/status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../shared/share_link_prompt.dart';
import '../company_shell.dart';
import '../../../router/tab_scroll.dart';
import '../../shared/error_feedback.dart';

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
      // 069: текст уходит водителям — китайское название латиницей.
      buildText: (url) => companyShareText(t, refData, company.nameLatin ?? company.name, active, url, lang),
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
      // 063 (эталон 35): компактная «+ Груз».
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('companyPostCargoFab'),
        onPressed: () => _openForm('/company/cargos/new'),
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(t.postCargoFab),
        tooltip: t.postCargoTitle,
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

  /// Водитель сменил статус сделки («Загружен», «В пути»…) или откликнулся — список и числа
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
    // 061 п.11: повторное нажатие на «Грузы» — этот список наверх.
    attachTabScroll('company.cargos', _scroll);
    final realtime = ref.read(realtimeServiceProvider);
    _subs
      ..add(realtime.onDealUpdated.listen(_refreshSoon))
      ..add(realtime.onResponsesUpdated.listen(_refreshSoon))
      ..add(realtime.onReconnected.listen(_refreshSoon));
    _load(reset: true);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _refreshDebounce?.cancel();
    detachTabScroll('company.cargos', _scroll);
    _scroll.dispose();
    super.dispose();
  }

  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load({bool reset = false}) async {
    // 057 п.19: идёт загрузка, а фильтр архива сменили — перезагрузить после неё.
    if (_loading) {
      if (reset) _refreshPending = true;
      return;
    }
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
      body = const SkeletonList();
    } else if (_items.isEmpty && _error != null) {
      body = ErrorView(message: errorMessage(t, _error!), onRetry: () => _load(reset: true));
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

    // 063 (эталон 35): маршрут одной строкой с флагами, справа — когда
    // опубликован (номера в списке нет); слева — кузов·вес, км·погрузка, машины;
    // справа — цена, ₸/км (в любой валюте), когда и как платят; аванс — плашкой;
    // внизу — отклики и маленькие кнопки.
    final route = refData == null
        ? null
        : cargoRouteLabels(refData, pointId: cargo.pointId, destinationCountryId: cargo.destinationCountryId, destinationCityId: cargo.destinationCityId, languageCode: locale);
    final routeText = route == null ? destinationLabel : (route.origin == null ? route.destination : '${route.origin} → ${route.destination}');
    // Плашка — только особые состояния: в «Активных» — «Истекает сегодня/завтра»,
    // в работе и архиве — шаг сделки или статус груза, как раньше.
    String? badgeLabel;
    var badgeColor = statusColor;
    if (widget.tab == CompanyCargoTab.active) {
      final now = DateTime.now();
      final daysLeft = DateTime(cargo.expiresAt.year, cargo.expiresAt.month, cargo.expiresAt.day).difference(DateTime(now.year, now.month, now.day)).inDays;
      if (cargo.status == CargoStatus.published && daysLeft <= 1) {
        badgeLabel = daysLeft <= 0 ? t.cargoExpiresToday : t.cargoExpiresTomorrow;
        badgeColor = StatusBadge.warning;
      } else if (cargo.status != CargoStatus.published) {
        badgeLabel = statusLabel;
      }
    } else {
      badgeLabel = statusLabel;
    }
    final grey = AppTextStyles.caption;
    final advance = advancePillText(t, advanceAmount: cargo.advanceAmount, currency: cargo.currency);
    final size = cargoSizeLabel(t, weightKg: cargo.weightKg, volumeM3: cargo.volumeM3, languageCode: locale);
    final left = [
      // 075: что везут — первым.
      [if (refData != null) cargoWhatLabel(refData, goodsName: cargo.goodsName, categoryId: cargo.categoryId, languageCode: locale), bodyType?.name.forLanguageCode(locale), if (size.isNotEmpty) size].whereType<String>().join(' · '),
      [if (cargo.distanceKm != null) '${formatThousands(cargo.distanceKm!)} ${t.unitKm}', loadingDayLabel(t, cargo.readyDate)].join(' · '),
      logistTrucksLabel(t, needed: cargo.trucksNeeded, taken: cargo.trucksTaken),
    ];
    final smallButton = OutlinedButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      side: const BorderSide(color: AppColors.divider),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      minimumSize: const Size(44, 36),
      visualDensity: VisualDensity.compact,
      textStyle: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
    );

    return AppCard(
      key: Key('companyCargoCard-${cargo.id}'),
      onTap: () => _open(cargo),
      // Эталон 35: на Android 360 с крупным шрифтом — около трёх карточек.
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Маршрут — одной строкой: не помещается — уменьшается, город назначения не теряется.
              Expanded(child: _RouteLine(text: routeText, textKey: Key('companyCargoRoute-${cargo.id}'))),
              const SizedBox(width: AppSpacing.sm),
              // Мелко (11–12 sp) и не растёт с крупным шрифтом — маршрут важнее.
              Text(
                formatPublishedAt(t, cargo.publishedAt, languageCode: locale),
                key: Key('companyCargoPublished-${cargo.id}'),
                style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontSize: 12),
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
              ),
            ],
          ),
          if (badgeLabel != null) ...[const SizedBox(height: AppSpacing.xs), StatusBadge(label: badgeLabel, color: badgeColor)],
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 075: «что везут» добавило строке длины — как маршрут: сначала
                // уменьшается до 60%, потом перенос (на 360 dp видно две карточки).
                _RouteLine(text: left[0], textKey: Key('companyCargoWhat-${cargo.id}'), style: AppTextStyles.bodyStrong),
                Text(left[1], style: grey),
                Text(left[2], key: Key('companyCargoTrucks-${cargo.id}'), style: grey),
                if (cargo.allowPartial) Text(t.feedBadgePartial, style: AppTextStyles.small.copyWith(color: AppColors.primary)),
              ],
            );
            // 065 (эталон 35): цена, ≈ ₸, ₸/км, когда и как — общий столбец справа;
            // на узком экране с крупным шрифтом — блоком под описанием, как в ленте
            // водителя (иначе название кузова рвётся посреди слова).
            if (constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) < 260) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [details, const SizedBox(height: AppSpacing.xs), CargoPriceColumn(cargo: cargo, refData: refData, keyPrefix: 'companyCargo', inline: true)],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
                  child: CargoPriceColumn(cargo: cargo, refData: refData, keyPrefix: 'companyCargo'),
                ),
              ],
            );
          }),
          if (advance != null) ...[const SizedBox(height: AppSpacing.sm), AdvancePill(advance, key: Key('companyCargoAdvance-${cargo.id}'))],
          if (deal != null) ...[const SizedBox(height: AppSpacing.sm), _DealDriverRow(deal: deal)],
          if (showResponses || canRepeat) ...[
            const Divider(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: showResponses
                      ? Text.rich(
                          key: Key('cargoResponsesLine-${cargo.id}'),
                          // 071 п.4: «Отклики: 3 · 2 новых · Приглашено: 2».
                          TextSpan(children: [
                            if (cargo.responsesCount == 0)
                              TextSpan(text: t.cargoNoResponses, style: AppTextStyles.small.copyWith(color: AppColors.textSecondary))
                            else ...[
                              TextSpan(text: t.cargoResponsesCount(cargo.responsesCount), style: AppTextStyles.small.copyWith(color: AppColors.text)),
                              if (cargo.newResponsesCount > 0)
                                TextSpan(
                                  text: ' · ${t.cargoResponsesNew(cargo.newResponsesCount)}',
                                  style: AppTextStyles.small.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                                ),
                            ],
                            // Приглашено — компактно (значок и число), чтобы строка не росла
                            // на узком экране; полный текст — для экранного диктора.
                            if (cargo.invitedCount > 0) ...[
                              TextSpan(text: ' · ', style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Semantics(
                                  label: t.cargoInvitedCount(cargo.invitedCount),
                                  child: Row(
                                    key: Key('cargoInvitedCount-${cargo.id}'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.send, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 2),
                                      Text('${cargo.invitedCount}', style: AppTextStyles.small.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        )
                      : const SizedBox.shrink(),
                ),
                if (showResponses)
                  OutlinedButton(
                    key: Key('cargoShare-${cargo.id}'),
                    style: smallButton,
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
                    child: Icon(LucideIcons.share, size: 18, semanticLabel: t.shareButton),
                  ),
                if (canRepeat) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: Key('cargoRepeat-${cargo.id}'),
                    style: smallButton,
                    onPressed: () => widget.onRepeat(cargo),
                    icon: const Icon(LucideIcons.rotateCw, size: 16),
                    label: Text(t.cargoRepeat),
                  ),
                ],
              ],
            ),
          ],
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



/// 065: маршрут одной строкой — не помещается, уменьшается (не меньше ¾),
/// дальше — многоточие: город назначения не пропадает, текст не становится мелким.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.text, required this.textKey, this.style});

  final String text;
  final Key textKey;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? AppTextStyles.route.copyWith(fontSize: 18);
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      if (width <= constraints.maxWidth) return Text(text, key: textKey, style: style, maxLines: 1);
      // 071 п.6: не помещается и уменьшенным до 60% — на две строки (город
      // назначения не пропадает целиком, как было с «Астана → …»); иначе одна
      // строка, уменьшенная, — карточка не растёт (на 360 dp видно две).
      if (width * 0.6 > constraints.maxWidth) {
        return Text(text, key: textKey, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
      }
      return FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(text, key: textKey, style: style, maxLines: 1, softWrap: false));
    });
  }
}
