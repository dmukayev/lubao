import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../shared/responsive.dart';

const _pageSize = 50;

enum _StatusFilter { all, pending, verified, blocked }

/// Фильтры читаются из query-параметров адреса при открытии и пишутся туда
/// же при каждом изменении (задача 028, п.3) — ссылка с плитки сводки
/// (`/drivers?onSite=today`) открывает нужный список, адрес переживает
/// перезагрузку страницы и годится для копирования.
class AdminDriversScreen extends ConsumerStatefulWidget {
  const AdminDriversScreen({super.key, this.queryParams = const {}});

  final Map<String, String> queryParams;

  @override
  ConsumerState<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends ConsumerState<AdminDriversScreen> {
  final _searchController = TextEditingController();
  _StatusFilter _filter = _StatusFilter.all;
  String? _onSite;
  int _page = 1;
  Timer? _debounce;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _applyParams(widget.queryParams);
  }

  @override
  void didUpdateWidget(covariant AdminDriversScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapEquals(oldWidget.queryParams, widget.queryParams)) {
      _applyParams(widget.queryParams);
    }
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  void _applyParams(Map<String, String> params) {
    _q = params['q'] ?? '';
    _searchController.text = _q;
    _onSite = params['onSite'];
    _page = int.tryParse(params['page'] ?? '') ?? 1;
    _filter = switch (params['filter']) {
      'pending' => _StatusFilter.pending,
      'verified' => _StatusFilter.verified,
      'blocked' => _StatusFilter.blocked,
      _ => _StatusFilter.all,
    };
  }

  void _pushUrl() {
    final params = <String, String>{
      if (_q.isNotEmpty) 'q': _q,
      if (_filter != _StatusFilter.all) 'filter': _filter.name,
      if (_onSite != null) 'onSite': _onSite!,
      if (_page != 1) 'page': '$_page',
    };
    context.go(Uri(path: '/drivers', queryParameters: params.isEmpty ? null : params).toString());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _q = value;
        _page = 1;
      });
      _pushUrl();
    });
  }

  AdminSearchQuery get _query => (
        q: _q,
        verified: switch (_filter) {
          _StatusFilter.verified => true,
          _StatusFilter.pending => false,
          _ => null,
        },
        blocked: _filter == _StatusFilter.blocked ? true : null,
        onSite: _onSite,
        page: _page,
      );

  List<ChoiceChip> _filterChips(BuildContext context) {
    final t = context.l10n;
    return [
      for (final f in _StatusFilter.values)
        ChoiceChip(
          label: Text(switch (f) {
            _StatusFilter.all => t.adminFilterAll,
            _StatusFilter.pending => t.adminFilterPending,
            _StatusFilter.verified => t.adminFilterVerified,
            _StatusFilter.blocked => t.adminFilterBlocked,
          }),
          selected: _filter == f,
          onSelected: (_) {
            setState(() {
              _filter = f;
              _page = 1;
            });
            _pushUrl();
          },
        ),
    ];
  }

  // Задача 030, п.1/4 — на телефоне поиск и лента фильтров-чипов в одну
  // строку с Row не помещаются (RenderFlex overflow): поиск сверху, чипы
  // снизу в горизонтальной прокрутке, а не сжатый Row.
  Widget _buildFilterBar(BuildContext context) {
    final t = context.l10n;
    final search = AppTextField(
      label: t.commonSearch,
      controller: _searchController,
      onChanged: _onSearchChanged,
      hintText: t.adminSearchDriverHint,
    );
    if (isMobileWidth(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search,
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (final chip in _filterChips(context)) Padding(padding: const EdgeInsets.only(right: 8), child: chip)]),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 16),
        for (final chip in _filterChips(context)) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final providerArgs = (q: _query.q, verified: _query.verified, blocked: _query.blocked, onSite: _onSite, page: _query.page);
    final pageAsync = ref.watch(adminDriversSearchProvider(providerArgs));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminDriversTitle),
        bottom: _onSite == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text(t.adminFilterOnSite),
                      onDeleted: () {
                        setState(() => _onSite = null);
                        _pushUrl();
                      },
                    ),
                  ),
                ),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: pageAsync.when(
                loading: () => const LoadingView(),
                error: (e, st) {
                  debugPrint('AdminDriversScreen: $e');
                  return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminDriversSearchProvider(providerArgs)));
                },
                data: (page) {
                  if (page.items.isEmpty) return EmptyState(message: t.adminDriversEmpty, icon: LucideIcons.user);
                  final isMobile = isMobileWidth(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: isMobile
                            ? ListView.separated(
                                itemCount: page.items.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final d = page.items[index];
                                  return Card(
                                    child: ListTile(
                                      onTap: () => context.push('/drivers/${d.id}'),
                                      title: Text(d.fullName),
                                      subtitle: Text('${d.phone ?? '—'} · ${d.homeCityName.forLanguageCode(locale)}'),
                                      trailing: _StatusCell(isVerified: d.isVerified, isBlocked: d.isBlocked, pendingDocsCount: d.pendingDocsCount),
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(label: Text(t.adminColName)),
                                      DataColumn(label: Text(t.adminColPhone)),
                                      DataColumn(label: Text(t.adminColCity)),
                                      DataColumn(label: Text(t.adminColVehicle)),
                                      DataColumn(label: Text(t.adminColStatus)),
                                      DataColumn(label: Text(t.adminColRating)),
                                      DataColumn(label: Text(t.adminColDeals)),
                                    ],
                                    rows: page.items
                                        .map(
                                          (d) => DataRow(
                                            onSelectChanged: (_) => context.push('/drivers/${d.id}'),
                                            cells: [
                                              DataCell(Text(d.fullName)),
                                              DataCell(Text(d.phone ?? '—')),
                                              DataCell(Text(d.homeCityName.forLanguageCode(locale))),
                                              DataCell(Text(d.vehicleBodyTypeName?.forLanguageCode(locale) ?? '—')),
                                              DataCell(_StatusCell(isVerified: d.isVerified, isBlocked: d.isBlocked, pendingDocsCount: d.pendingDocsCount)),
                                              DataCell(Text('★ ${d.ratingAvg.toStringAsFixed(1)} (${d.ratingCount})')),
                                              DataCell(Text('${d.completedDeals}')),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      _Pager(
                        page: _page,
                        total: page.total,
                        onChanged: (p) {
                          setState(() => _page = p);
                          _pushUrl();
                        },
                      ),
                    ],
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

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.isVerified, required this.isBlocked, required this.pendingDocsCount});

  final bool isVerified;
  final bool isBlocked;
  final int pendingDocsCount;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBlocked)
          StatusBadge(label: t.adminBlockedBadge, color: StatusBadge.danger)
        else if (isVerified)
          StatusBadge(label: t.adminVerified, color: StatusBadge.success)
        else
          StatusBadge(label: t.adminNotVerified, color: StatusBadge.neutral),
        if (pendingDocsCount > 0) ...[
          const SizedBox(width: 6),
          Text('($pendingDocsCount)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.total, required this.onChanged});

  final int page;
  final int total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final totalPages = (total / _pageSize).ceil().clamp(1, 999999);
    return Row(
      children: [
        Text(t.adminPageOf(page, totalPages)),
        const Spacer(),
        IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: page > 1 ? () => onChanged(page - 1) : null),
        IconButton(icon: const Icon(LucideIcons.chevronRight), onPressed: page < totalPages ? () => onChanged(page + 1) : null),
      ],
    );
  }
}
