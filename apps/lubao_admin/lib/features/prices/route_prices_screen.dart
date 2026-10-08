import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import 'csv_download.dart';

final _routePricesProvider = FutureProvider.autoDispose.family<List<AdminRoutePrice>, (String?, int?)>(
  (ref, f) => ref.watch(adminRepositoryProvider).routePrices(bucket: f.$1, tonnageClass: f.$2),
);

String bucketLabel(LubaoLocalizations t, String bucket) => switch (bucket) {
      'KZ' => t.bucketKz,
      'CIS' => t.bucketCis,
      _ => t.bucketCnFar,
    };

String tonnageLabel(LubaoLocalizations t, int tonnageClass) => tonnageClass >= 20 ? t.tonnageOver : t.tonnageUpTo(tonnageClass);

/// «Цены по маршрутам» (047 п.8): медиана и P25–P75 ₸/км за 30 дней по
/// маршруту, направлению и тоннажу; фильтры и выгрузка CSV.
class RoutePricesScreen extends ConsumerStatefulWidget {
  const RoutePricesScreen({super.key});

  @override
  ConsumerState<RoutePricesScreen> createState() => _RoutePricesScreenState();
}

class _RoutePricesScreenState extends ConsumerState<RoutePricesScreen> {
  String? _bucket;
  int? _tonnage;

  Future<void> _export() async {
    final t = context.l10n;
    try {
      final bytes = await ref.read(adminRepositoryProvider).routePricesCsv(bucket: _bucket, tonnageClass: _tonnage);
      final ok = await downloadCsv('route-prices.csv', bytes);
      if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.adminCsvSaved)));
    } catch (e) {
      debugPrint('RoutePricesScreen: csv: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final rows = ref.watch(_routePricesProvider((_bucket, _tonnage)));
    Widget chip<T>(String label, T? value, T? current, void Function(T?) onTap) => ChoiceChip(
          label: Text(label),
          selected: value == current,
          onSelected: (_) => setState(() => onTap(value)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminRoutePricesTitle),
        actions: [
          TextButton.icon(
            key: const Key('routePricesCsv'),
            onPressed: _export,
            icon: const Icon(LucideIcons.download, size: 18),
            label: Text(t.adminExportCsv),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip<String>(t.adminAllFilter, null, _bucket, (v) => _bucket = v),
              for (final b in const ['KZ', 'CIS', 'CN_FAR']) chip<String>(bucketLabel(t, b), b, _bucket, (v) => _bucket = v),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip<int>(t.adminAllFilter, null, _tonnage, (v) => _tonnage = v),
              for (final c in const [5, 10, 20]) chip<int>(tonnageLabel(t, c), c, _tonnage, (v) => _tonnage = v),
            ],
          ),
          const SizedBox(height: 16),
          rows.when(
            loading: () => const LoadingView(),
            error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(_routePricesProvider)),
            data: (items) => items.isEmpty
                ? AppCard(key: const Key('routePricesEmpty'), child: Text(t.adminRoutePricesEmpty))
                : AppCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(t.adminColRoute)),
                          DataColumn(label: Text(t.adminColBucket)),
                          DataColumn(label: Text(t.adminColTonnage)),
                          DataColumn(label: Text(t.adminColMedian), numeric: true),
                          DataColumn(label: Text(t.adminColRange)),
                          DataColumn(label: Text(t.adminColPoints), numeric: true),
                          DataColumn(label: Text(t.adminColDealPoints), numeric: true),
                        ],
                        rows: [
                          for (final r in items)
                            DataRow(cells: [
                              DataCell(Text('${r.fromName?.forLanguageCode(locale) ?? '—'} → ${r.toName?.forLanguageCode(locale) ?? '—'}')),
                              DataCell(Text(bucketLabel(t, r.bucket))),
                              DataCell(Text(tonnageLabel(t, r.tonnageClass))),
                              DataCell(Text(r.median.round().toString())),
                              DataCell(Text('${r.p25.round()}–${r.p75.round()}')),
                              DataCell(Text('${r.points}')),
                              DataCell(Text('${r.dealPoints}')),
                            ]),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
