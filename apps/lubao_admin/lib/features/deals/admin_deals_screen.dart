import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../shared/admin_status_helpers.dart';

const _pageSize = 50;

/// Таблица сделок (задача 028, п.16); карточка `/deals/:id` (история
/// статусов, переписка только для просмотра, «Исправить статус»,
/// «Отменить») — `deal_detail_screen.dart`.
class AdminDealsScreen extends ConsumerStatefulWidget {
  const AdminDealsScreen({super.key, this.queryParams = const {}});

  final Map<String, String> queryParams;

  @override
  ConsumerState<AdminDealsScreen> createState() => _AdminDealsScreenState();
}

class _AdminDealsScreenState extends ConsumerState<AdminDealsScreen> {
  final _searchController = TextEditingController();
  String? _status;
  bool _stale = false;
  int _page = 1;
  Timer? _debounce;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _applyParams(widget.queryParams);
  }

  @override
  void didUpdateWidget(covariant AdminDealsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapEquals(oldWidget.queryParams, widget.queryParams)) _applyParams(widget.queryParams);
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
    _status = params['status'];
    _stale = params['stale'] == 'true';
    _page = int.tryParse(params['page'] ?? '') ?? 1;
  }

  void _pushUrl() {
    final params = <String, String>{
      if (_q.isNotEmpty) 'q': _q,
      if (_status != null) 'status': _status!,
      if (_stale) 'stale': 'true',
      if (_page != 1) 'page': '$_page',
    };
    context.go(Uri(path: '/deals', queryParameters: params.isEmpty ? null : params).toString());
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

  static const _statuses = ['active', 'SELECTED', 'CONFIRMED_BY_DRIVER', 'LOADED', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED'];

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final providerArgs = (q: _q, status: _status, stale: _stale, driverId: null, companyId: null, page: _page);
    final pageAsync = ref.watch(adminDealsSearchProvider(providerArgs));

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDealsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 280, child: AppTextField(label: t.commonSearch, controller: _searchController, onChanged: _onSearchChanged)),
                ChoiceChip(
                  label: Text(t.adminFilterAll),
                  selected: _status == null,
                  onSelected: (_) {
                    setState(() {
                      _status = null;
                      _page = 1;
                    });
                    _pushUrl();
                  },
                ),
                for (final s in _statuses)
                  ChoiceChip(
                    label: Text(s == 'active' ? t.adminFilterActive : dealStatusLabel(t, s)),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() {
                        _status = s;
                        _page = 1;
                      });
                      _pushUrl();
                    },
                  ),
                ChoiceChip(
                  label: Text(t.adminFilterStale),
                  selected: _stale,
                  onSelected: (_) {
                    setState(() {
                      _stale = !_stale;
                      _page = 1;
                    });
                    _pushUrl();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pageAsync.when(
                loading: () => const LoadingView(),
                error: (e, st) {
                  debugPrint('AdminDealsScreen: $e');
                  return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminDealsSearchProvider(providerArgs)));
                },
                data: (page) {
                  if (page.items.isEmpty) return EmptyState(message: t.adminDealsEmpty, icon: LucideIcons.fileCheck2);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(t.adminColRoute)),
                                DataColumn(label: Text(t.adminColDriver)),
                                DataColumn(label: Text(t.adminColCompany)),
                                DataColumn(label: Text(t.adminColPrice)),
                                DataColumn(label: Text(t.adminColStatus)),
                                DataColumn(label: Text(t.adminColStale)),
                                DataColumn(label: Text(t.adminColCreated)),
                              ],
                              rows: page.items
                                  .map(
                                    (d) => DataRow(
                                      onSelectChanged: (_) => context.push('/deals/${d.id}'),
                                      cells: [
                                        DataCell(Text('${d.pointName.forLanguageCode(locale)} → ${d.destinationCountryName.forLanguageCode(locale)}')),
                                        DataCell(InkWell(onTap: () => context.push('/drivers/${d.driverId}'), child: Text(d.driverName, style: const TextStyle(decoration: TextDecoration.underline)))),
                                        DataCell(InkWell(onTap: () => context.push('/companies/${d.companyId}'), child: Text(d.companyName, style: const TextStyle(decoration: TextDecoration.underline)))),
                                        DataCell(Text(formatMoney(d.price, currencyFromJson(d.currency)))),
                                        DataCell(Text(dealStatusLabel(t, d.status))),
                                        DataCell(d.staleDays > 0 ? Text(t.adminStaleDays(d.staleDays), style: const TextStyle(color: StatusBadge.danger)) : const Text('—')),
                                        DataCell(Text(formatAdminDate(d.createdAt))),
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
