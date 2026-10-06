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
    final cityStats = ref.watch(adminCityStatsProvider);
    final period = ref.watch(adminStatsPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.adminDashboardTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(adminAttentionProvider);
          ref.invalidate(adminRecentEventsProvider);
          ref.invalidate(adminCityStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AdminSearchBar(),
            const SizedBox(height: 16),
            // Задача 030 — на узком экране Text+3 чипа в один Row не
            // помещались (RenderFlex overflow, обнаружено живой проверкой
            // в браузере, не flutter analyze): подпись сверху, чипы в
            // горизонтальной прокрутке, тот же паттерн, что в списках
            // водителей/компаний/грузов/сделок.
            Text(t.adminPeriodLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in const ['today', '7d', '30d'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (p) {
                          'today' => t.adminPeriodToday,
                          '7d' => t.adminPeriod7d,
                          _ => t.adminPeriod30d,
                        }),
                        selected: period == p,
                        onSelected: (_) => ref.read(adminStatsPeriodProvider.notifier).state = p,
                      ),
                    ),
                ],
              ),
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
            const SizedBox(height: 24),
            Text(t.adminCityStatsTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            cityStats.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              error: (e, st) {
                debugPrint('DashboardScreen (cityStats): $e');
                return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(adminCityStatsProvider));
              },
              data: (rows) => _CityStatsBlock(rows: rows),
            ),
          ],
        ),
      ),
    );
  }
}

/// Анонсы / грузы / сделки по городам (задача 040, п.9).
class _CityStatsBlock extends StatelessWidget {
  const _CityStatsBlock({required this.rows});

  final List<CityStatsRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    if (rows.isEmpty) {
      return Text(t.adminCityStatsEmpty, style: Theme.of(context).textTheme.bodyMedium);
    }
    return Card(
      key: const Key('adminCityStats'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(flex: 3, child: SizedBox.shrink()),
                for (final label in [t.adminCityStatsArrivals, t.adminCityStatsCargos, t.adminCityStatsDeals])
                  Expanded(
                    flex: 2,
                    child: Text(label, textAlign: TextAlign.end, style: Theme.of(context).textTheme.labelMedium, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
            const Divider(),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(r.name.forLanguageCode(locale), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text('${r.arrivals}', textAlign: TextAlign.end)),
                    Expanded(flex: 2, child: Text('${r.cargos}', textAlign: TextAlign.end)),
                    Expanded(flex: 2, child: Text('${r.dealsActive} / ${r.dealsDelivered}', textAlign: TextAlign.end)),
                  ],
                ),
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
      if (stats.cargosClosedTotal > 0)
        (
          t.adminStatClosedOutside,
          '${stats.cargosClosedOutsideSharePct}%',
          t.adminStatClosedOutsideHint(stats.cargosClosedOutside, stats.cargosClosedTotal),
          LucideIcons.logOut,
          StatusBadge.warning,
          '/cargos?status=CANCELLED',
        ),
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
                      // Задача 030 — без maxLines «На неделе: N» переносилось
                      // на вторую строку на узких плитках (2 колонки на
                      // телефоне) и вылезало за фиксированную высоту ячейки
                      // (RenderFlex overflow, поймано живой проверкой).
                      if (hint != null) Text(hint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      // 032 п.11 (038) — совпадения подтверждённых идентификаторов с
      // активным чёрным списком (кроме самих заблокированных).
      if (attention.blacklistMatches > 0) (t.adminAttentionBlacklistMatches(attention.blacklistMatches), true, '/drivers'),
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
