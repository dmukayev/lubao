import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../shared/admin_status_helpers.dart';

const _pageSize = 50;

/// Таблица грузов (задача 028, п.14); карточка `/cargos/:id` с действиями
/// («Снять с публикации», «Исправить») — `cargo_detail_screen.dart`.
class AdminCargosScreen extends ConsumerStatefulWidget {
  const AdminCargosScreen({super.key, this.queryParams = const {}});

  final Map<String, String> queryParams;

  @override
  ConsumerState<AdminCargosScreen> createState() => _AdminCargosScreenState();
}

class _AdminCargosScreenState extends ConsumerState<AdminCargosScreen> {
  final _searchController = TextEditingController();
  String? _status;
  int _page = 1;
  Timer? _debounce;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _applyParams(widget.queryParams);
  }

  @override
  void didUpdateWidget(covariant AdminCargosScreen oldWidget) {
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
    _page = int.tryParse(params['page'] ?? '') ?? 1;
  }

  void _pushUrl() {
    final params = <String, String>{
      if (_q.isNotEmpty) 'q': _q,
      if (_status != null) 'status': _status!,
      if (_page != 1) 'page': '$_page',
    };
    context.go(Uri(path: '/cargos', queryParameters: params.isEmpty ? null : params).toString());
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

  static const _statuses = ['PUBLISHED', 'ARCHIVED', 'EXPIRED', 'CANCELLED'];

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final providerArgs = (q: _q, status: _status, companyId: null, destinationCountryId: null, page: _page);
    final pageAsync = ref.watch(adminCargosSearchProvider(providerArgs));

    return Scaffold(
      appBar: AppBar(title: Text(t.adminCargosTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: AppTextField(label: t.commonSearch, controller: _searchController, onChanged: _onSearchChanged)),
                const SizedBox(width: 16),
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
                const SizedBox(width: 8),
                for (final s in _statuses) ...[
                  ChoiceChip(
                    label: Text(cargoStatusLabel(t, s)),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() {
                        _status = s;
                        _page = 1;
                      });
                      _pushUrl();
                    },
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
                  debugPrint('AdminCargosScreen: $e');
                  return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminCargosSearchProvider(providerArgs)));
                },
                data: (page) {
                  if (page.items.isEmpty) return EmptyState(message: t.adminCargosEmpty, icon: LucideIcons.truck);
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
                                DataColumn(label: Text(t.adminColBodyType)),
                                DataColumn(label: Text(t.adminColPrice)),
                                DataColumn(label: Text(t.adminColCompany)),
                                DataColumn(label: Text(t.adminColResponses)),
                                DataColumn(label: Text(t.adminColStatus)),
                                DataColumn(label: Text(t.adminColPublished)),
                              ],
                              rows: page.items
                                  .map(
                                    (c) => DataRow(
                                      onSelectChanged: (_) => context.push('/cargos/${c.id}'),
                                      cells: [
                                        DataCell(Text('${c.pointName.forLanguageCode(locale)} → ${c.destinationCityName?.forLanguageCode(locale) ?? c.destinationCountryName.forLanguageCode(locale)}')),
                                        DataCell(Text(c.bodyTypeName.forLanguageCode(locale))),
                                        DataCell(Text(formatMoney(c.price, currencyFromJson(c.currency)))),
                                        DataCell(InkWell(onTap: () => context.push('/companies/${c.companyId}'), child: Text(c.companyName, style: const TextStyle(decoration: TextDecoration.underline)))),
                                        DataCell(Text('${c.responseCount}')),
                                        DataCell(Text(cargoStatusLabel(t, c.status))),
                                        DataCell(Text(formatAdminDate(c.publishedAt))),
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
