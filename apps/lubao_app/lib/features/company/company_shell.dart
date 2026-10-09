import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';

/// 056 п.5: числа «Грузов» и новые отклики этого сотрудника — цифра на вкладке.
final companyCargoCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(cargoRepositoryProvider).companyCounts();
});

class CompanyShell extends ConsumerStatefulWidget {
  const CompanyShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends ConsumerState<CompanyShell> {
  /// 056 п.4: вкладки «Сделки» у логиста нет — «В работе» и архив в «Грузах».
  static const _tabs = ['/company/cargos', '/company/drivers', '/company/chats', '/company/profile'];

  String? _lastLocation;

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    // Вернулись в «Грузы» (например, из откликов груза) — новые пересчитать.
    if (_lastLocation != null && _lastLocation != location && location.startsWith('/company/cargos')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(companyCargoCountsProvider);
      });
    }
    _lastLocation = location;
    final currentIndex = _indexForLocation(location);
    final newResponses = ref.watch(companyCargoCountsProvider).valueOrNull?['newResponses'] ?? 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) ref.invalidate(companyCargoCountsProvider);
          context.go(_tabs[index]);
        },
        destinations: [
          NavigationDestination(
            icon: Badge.count(
              key: const Key('navCargosBadge'),
              count: newResponses,
              isLabelVisible: newResponses > 0,
              backgroundColor: AppColors.error,
              child: const Icon(LucideIcons.package),
            ),
            label: t.navCargos,
          ),
          NavigationDestination(icon: const Icon(LucideIcons.users), label: t.navDrivers),
          NavigationDestination(icon: const Icon(LucideIcons.messageCircle), label: t.navChats),
          NavigationDestination(icon: const Icon(LucideIcons.user), label: t.profileTitle),
        ],
      ),
    );
  }
}
