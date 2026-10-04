import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';

const _pageSize = 50;

enum _StatusFilter { all, pending, verified, blocked }

class AdminCompaniesScreen extends ConsumerStatefulWidget {
  const AdminCompaniesScreen({super.key});

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
        page: _page,
      );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final pageAsync = ref.watch(adminCompaniesSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(t.adminCompaniesTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: t.commonSearch,
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    hintText: t.adminSearchCompanyHint,
                  ),
                ),
                const SizedBox(width: 16),
                for (final f in _StatusFilter.values) ...[
                  ChoiceChip(
                    label: Text(switch (f) {
                      _StatusFilter.all => t.adminFilterAll,
                      _StatusFilter.pending => t.adminFilterPending,
                      _StatusFilter.verified => t.adminFilterVerified,
                      _StatusFilter.blocked => t.adminFilterBlocked,
                    }),
                    selected: _filter == f,
                    onSelected: (_) => setState(() {
                      _filter = f;
                      _page = 1;
                    }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pageAsync.when(
                loading: () => const LoadingView(),
                error: (e, st) {
                  debugPrint('AdminCompaniesScreen: $e');
                  return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminCompaniesSearchProvider(_query)));
                },
                data: (page) {
                  if (page.items.isEmpty) return EmptyState(message: t.adminCompaniesEmpty, icon: LucideIcons.building2);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
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
                      _Pager(page: _page, total: page.total, onChanged: (p) => setState(() => _page = p)),
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
