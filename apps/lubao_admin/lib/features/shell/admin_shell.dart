import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Порядок меню — задача 028, п.1: Сводка · Проверка · Жалобы · Водители ·
/// Компании · Грузы · Сделки · Справочники · Настройки.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    '/dashboard',
    '/verification',
    '/complaints',
    '/drivers',
    '/companies',
    '/cargos',
    '/deals',
    '/reference',
    '/settings',
  ];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final attention = ref.watch(adminAttentionProvider);
    final pendingVerification = attention.valueOrNull?.pendingVerificationCount;
    final openComplaints = attention.valueOrNull?.openComplaints;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => context.go(_tabs[index]),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Icon(LucideIcons.truck, size: 32)),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(LucideIcons.logOut),
                    tooltip: t.profileLogout,
                    onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  ),
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(icon: const Icon(LucideIcons.layoutDashboard), label: Text(t.adminNavDashboard)),
              NavigationRailDestination(
                icon: _BadgedIcon(icon: LucideIcons.badgeCheck, count: pendingVerification),
                label: Text(t.adminNavVerification),
              ),
              NavigationRailDestination(
                icon: _BadgedIcon(icon: LucideIcons.flag, count: openComplaints),
                label: Text(t.adminNavComplaints),
              ),
              NavigationRailDestination(icon: const Icon(LucideIcons.user), label: Text(t.adminNavDrivers)),
              NavigationRailDestination(icon: const Icon(LucideIcons.building2), label: Text(t.adminNavCompanies)),
              NavigationRailDestination(icon: const Icon(LucideIcons.truck), label: Text(t.adminNavCargos)),
              NavigationRailDestination(icon: const Icon(LucideIcons.fileCheck2), label: Text(t.adminNavDeals)),
              NavigationRailDestination(icon: const Icon(LucideIcons.clipboardList), label: Text(t.adminNavReference)),
              NavigationRailDestination(icon: const Icon(LucideIcons.settings), label: Text(t.adminNavSettings)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});

  final IconData icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (count == null || count == 0) return Icon(icon);
    return Badge(label: Text('$count'), backgroundColor: StatusBadge.danger, child: Icon(icon));
  }
}
