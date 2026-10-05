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

class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key, this.queryParams = const {}});

  final Map<String, String> queryParams;

  @override
  ConsumerState<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends ConsumerState<AdminCompaniesScreen> {
  final _searchController = TextEditingController();
  _StatusFilter _filter = _StatusFilter.all;
  int _page = 1;
  Timer? _debounce;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _applyParams(widget.queryParams);
  }

  @override
  void didUpdateWidget(covariant AdminCompaniesScreen oldWidget) {
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
      if (_page != 1) 'page': '$_page',
    };
    context.go(Uri(path: '/companies', queryParameters: params.isEmpty ? null : params).toString());
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
        onSite: null,
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

  Widget _buildFilterBar(BuildContext context) {
    final t = context.l10n;
    final search = AppTextField(
      label: t.commonSearch,
      controller: _searchController,
      onChanged: _onSearchChanged,
      hintText: t.adminSearchCompanyHint,
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
    final providerArgs = _query;
    final pageAsync = ref.watch(adminCompaniesSearchProvider(providerArgs));

    return Scaffold(
      appBar: AppBar(title: Text(t.adminCompaniesTitle)),
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
                  debugPrint('AdminCompaniesScreen: $e');
                  return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminCompaniesSearchProvider(providerArgs)));
                },
                data: (page) {
                  if (page.items.isEmpty) return EmptyState(message: t.adminCompaniesEmpty, icon: LucideIcons.building2);
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
                                  final c = page.items[index];
                                  return Card(
                                    child: ListTile(
                                      onTap: () => context.push('/companies/${c.id}'),
                                      title: Text(c.name),
                                      subtitle: Text('${c.ownerEmail ?? c.ownerName ?? '—'} · ${c.employeeCount}'),
                                      trailing: _StatusCell(isVerified: c.isVerified, isBlocked: c.isBlocked, pendingDocsCount: c.pendingDocsCount),
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
                                      DataColumn(label: Text(t.adminColOwner)),
                                      DataColumn(label: Text(t.adminColEmployees)),
                                      DataColumn(label: Text(t.adminColCargos)),
                                      DataColumn(label: Text(t.adminColStatus)),
                                      DataColumn(label: Text(t.adminColRating)),
                                      DataColumn(label: Text(t.adminColDeals)),
                                    ],
                                    rows: page.items
                                        .map(
                                          (c) => DataRow(
                                            onSelectChanged: (_) => context.push('/companies/${c.id}'),
                                            cells: [
                                              DataCell(Text(c.name)),
                                              DataCell(Text(c.ownerEmail ?? c.ownerName ?? '—')),
                                              DataCell(Text('${c.employeeCount}')),
                                              DataCell(Text('${c.activeCargoCount}')),
                                              DataCell(_StatusCell(isVerified: c.isVerified, isBlocked: c.isBlocked, pendingDocsCount: c.pendingDocsCount)),
                                              DataCell(Text('★ ${c.ratingAvg.toStringAsFixed(1)} (${c.ratingCount})')),
                                              DataCell(Text('${c.dealCount}')),
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
