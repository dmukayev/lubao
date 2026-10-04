import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';

/// Глобальный поиск сверху сводки (задача 028, п.6) — имя, телефон, email,
/// госномер, № груза/сделки, результаты сгруппированы по типу.
class AdminSearchBar extends ConsumerStatefulWidget {
  const AdminSearchBar({super.key});

  @override
  ConsumerState<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends ConsumerState<AdminSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _q = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _q = value.trim()));
  }

  void _clear() {
    _controller.clear();
    setState(() => _q = '');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: t.adminGlobalSearchHint,
          controller: _controller,
          onChanged: _onChanged,
        ),
        if (_q.length >= 2) ...[
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final resultsAsync = ref.watch(adminGlobalSearchProvider(_q));
              return resultsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
                error: (e, st) => const SizedBox.shrink(),
                data: (results) {
                  if (results.isEmpty) return AppCard(child: Text(t.adminSearchNoResults));
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _group(context, t.adminNavDrivers, results.drivers, (id) {
                          _clear();
                          context.push('/drivers/$id');
                        }),
                        _group(context, t.adminNavCompanies, results.companies, (id) {
                          _clear();
                          context.push('/companies/$id');
                        }),
                        _group(context, t.adminNavCargos, results.cargos, (id) {
                          _clear();
                          context.push('/cargos/$id');
                        }),
                        _group(context, t.adminNavDeals, results.deals, (id) {
                          _clear();
                          context.push('/deals/$id');
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _group(BuildContext context, String label, List<AdminSearchHit> hits, ValueChanged<String> onTap) {
    if (hits.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        for (final hit in hits)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.arrowRight, size: 16),
            title: Text(hit.title),
            onTap: () => onTap(hit.id),
          ),
      ],
    );
  }
}
