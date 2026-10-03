import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDashboardTitle)),
      body: stats.when(
        loading: () => const LoadingView(),
        error: (e, st) => ErrorView(message: t.commonError, onRetry: () => ref.invalidate(statsProvider)),
        data: (s) {
          final cards = [
            (t.adminStatDrivers, s.drivers.toString(), LucideIcons.user, StatusBadge.info),
            (t.adminStatCompanies, s.companies.toString(), LucideIcons.building2, StatusBadge.info),
            (t.adminStatCargosPublished, s.cargosPublished.toString(), LucideIcons.truck, StatusBadge.success),
            (t.adminStatDealsActive, s.dealsActive.toString(), LucideIcons.fileCheck2, StatusBadge.warning),
            (t.adminStatDealsDelivered, s.dealsDelivered.toString(), LucideIcons.checkCircle, StatusBadge.success),
            (t.adminStatPendingDocs, s.pendingDocs.toString(), LucideIcons.clock, StatusBadge.warning),
            (t.adminStatOpenComplaints, s.openComplaints.toString(), LucideIcons.flag, StatusBadge.danger),
          ];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(statsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final (label, value, icon, color) = cards[index];
                return AppCard(
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value, style: Theme.of(context).textTheme.headlineSmall),
                            Text(label, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
