import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import '../shared/admin_status_helpers.dart';
import 'admin_search_bar.dart';

/// Сводка — пульт, не витрина (задача 028, decisions.md 2026-10-05): любая
/// цифра ведёт в список с фильтром, «Требует внимания» — с чего админ
/// начинает день, «Последние события» — одна лента вместо разрозненных
/// разделов.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final stats = ref.watch(adminStatsProvider);
    final attention = ref.watch(adminAttentionProvider);
    final events = ref.watch(adminRecentEventsProvider);
    final period = ref.watch(adminStatsPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDashboardTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(adminAttentionProvider);
          ref.invalidate(adminRecentEventsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AdminSearchBar(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(t.adminPeriodLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: 12),
                for (final p in const ['today', '7d', '30d']) ...[
                  ChoiceChip(
                    label: Text(switch (p) {
                      'today' => t.adminPeriodToday,
                      '7d' => t.adminPeriod7d,
                      _ => t.adminPeriod30d,
                    }),
                    selected: period == p,
                    onSelected: (_) => ref.read(adminStatsPeriodProvider.notifier).state = p,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            stats.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                debugPrint('DashboardScreen (stats): $e');
                return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminStatsProvider));
              },
              data: (s) => _StatsGrid(stats: s),
            ),
            const SizedBox(height: 24),
            Text(t.adminAttentionTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            attention.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                debugPrint('DashboardScreen (attention): $e');
                return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminAttentionProvider));
              },
              data: (a) => _AttentionBlock(attention: a),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.adminRecentEventsTitle, style: Theme.of(context).textTheme.titleLarge),
                TextButton(onPressed: () => context.push('/audit'), child: Text(t.adminAuditLogLink)),
              ],
            ),
            const SizedBox(height: 8),
            events.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                debugPrint('DashboardScreen (events): $e');
                return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminRecentEventsProvider));
              },
              data: (list) => _RecentEventsList(events: list),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final tiles = [
      (t.adminStatDrivers, '${stats.drivers}', '+${stats.growth.drivers}', LucideIcons.user, StatusBadge.info, '/drivers'),
      (t.adminStatCompanies, '${stats.companies}', '+${stats.growth.companies}', LucideIcons.building2, StatusBadge.info, '/companies'),
      (t.adminStatOnSiteToday, '${stats.onSiteToday}', t.adminStatOnSiteWeek(stats.onSiteWeek), LucideIcons.mapPin, StatusBadge.success, '/drivers?onSite=today'),
      (t.adminStatCargosPublished, '${stats.cargosPublished}', '+${stats.growth.cargos}', LucideIcons.truck, StatusBadge.success, '/cargos?status=PUBLISHED'),
      (t.adminStatDealsActive, '${stats.dealsActive}', null, LucideIcons.fileCheck2, StatusBadge.warning, '/deals?status=active'),
      (t.adminStatDealsDelivered, '${stats.dealsDelivered}', '+${stats.growth.delivered}', LucideIcons.checkCircle, StatusBadge.success, '/deals?status=DELIVERED'),
      (t.adminStatPendingDocs, '${stats.pendingDocs}', null, LucideIcons.clock, StatusBadge.warning, '/verification'),
      (t.adminStatOpenComplaints, '${stats.openComplaints}', null, LucideIcons.flag, StatusBadge.danger, '/complaints'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 120,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final (label, value, hint, icon, color, route) = tiles[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(route),
          child: AppCard(
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value, style: Theme.of(context).textTheme.headlineSmall),
                      Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (hint != null) Text(hint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttentionBlock extends StatelessWidget {
  const _AttentionBlock({required this.attention});

  final AdminAttention attention;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final rows = [
      if (attention.pendingVerificationCount > 0)
        (
          t.adminAttentionPendingVerification(attention.pendingVerificationCount),
          attention.pendingVerificationOldestAgeHours >= 24,
          '/verification',
        ),
      if (attention.openComplaints > 0) (t.adminAttentionOpenComplaints(attention.openComplaints), false, '/complaints'),
      if (attention.staleDeals > 0) (t.adminAttentionStaleDeals(attention.staleDeals), true, '/deals?stale=true'),
      if (attention.unverifiedCompanies > 0)
        (t.adminAttentionUnverifiedCompanies(attention.unverifiedCompanies), false, '/companies?filter=pending'),
      if (attention.pendingCities > 0) (t.adminAttentionPendingCities(attention.pendingCities), false, '/reference'),
    ];

    if (rows.isEmpty) {
      return AppCard(child: Text(t.adminAttentionEmpty));
    }

    return AppCard(
      child: Column(
        children: [
          for (final (label, urgent, route) in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(LucideIcons.alertCircle, color: urgent ? StatusBadge.danger : StatusBadge.warning),
              title: Text(label),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.go(route),
            ),
        ],
      ),
    );
  }
}

class _RecentEventsList extends StatelessWidget {
  const _RecentEventsList({required this.events});

  final List<AdminEvent> events;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    if (events.isEmpty) return AppCard(child: Text(t.adminNoEvents));
    return AppCard(
      child: Column(
        children: [
          for (final e in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(e.type)),
              title: Text(e.title),
              trailing: Text(formatAdminDateTime(e.createdAt), style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'driver_registered':
        return LucideIcons.userPlus;
      case 'company_registered':
        return LucideIcons.building2;
      case 'cargo_published':
        return LucideIcons.truck;
      case 'deal_status':
        return LucideIcons.fileCheck2;
      default:
        return LucideIcons.activity;
    }
  }
}
