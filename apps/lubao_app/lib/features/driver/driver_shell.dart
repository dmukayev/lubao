import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/driver/feed', '/driver/deals', '/driver/profile'];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index]),
        destinations: [
          NavigationDestination(icon: const Icon(LucideIcons.truck), label: t.navFeed),
          NavigationDestination(icon: const Icon(LucideIcons.fileCheck2), label: t.navDeals),
          NavigationDestination(icon: const Icon(LucideIcons.user), label: t.profileTitle),
        ],
      ),
    );
  }
}
