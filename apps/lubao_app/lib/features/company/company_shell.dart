import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

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
  final _subs = <StreamSubscription<Object?>>[];

  /// Непрочитанные сообщения — цифрой на «Чатах», как у водителя (053 п.6):
  /// обновляются по сокету и при переходе на вкладку.
  @override
  void initState() {
    super.initState();
    final realtime = ref.read(realtimeServiceProvider);
    void chats(Object? _) => ref.invalidate(myChatsProvider);
    _subs
      ..add(realtime.onMessageNew.listen(chats))
      ..add(realtime.onMessageRead.listen(chats))
      ..add(realtime.onChatUpdated.listen(chats))
      // Новый отклик / водитель отозвал — цифра на «Грузах».
      ..add(realtime.onResponsesUpdated.listen((_) {
        ref.invalidate(companyCargoCountsProvider);
        // 058 п.5: своя цена / «Нет» на встречную — список откликов сам.
        ref.invalidate(cargoResponsesProvider);
      }))
      ..add(realtime.onReconnected.listen((_) {
        ref.invalidate(myChatsProvider);
        ref.invalidate(companyCargoCountsProvider);
      }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    // Вернулись в «Грузы» (например, из откликов груза) — новые пересчитать.
    if (_lastLocation != null && _lastLocation != location) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Вернулись из откликов / из чата — новые и непрочитанные пересчитать.
        if (location.startsWith('/company/cargos')) ref.invalidate(companyCargoCountsProvider);
        ref.invalidate(myChatsProvider);
      });
    }
    _lastLocation = location;
    final currentIndex = _indexForLocation(location);
    final newResponses = ref.watch(companyCargoCountsProvider).valueOrNull?['newResponses'] ?? 0;
    final unread = (ref.watch(myChatsProvider).valueOrNull ?? const <MyChatEntry>[]).fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) ref.invalidate(companyCargoCountsProvider);
          if (index == 2) ref.invalidate(myChatsProvider);
          context.go(_tabs[index]);
        },
        // Эталон 33: свои цветные иконки (design/brand/nav).
        destinations: [
          navDestination(NavIconAsset.boxes, t.navCargos, count: newResponses, badgeKey: const Key('navCargosBadge')),
          navDestination(NavIconAsset.drivers, t.navDrivers),
          navDestination(NavIconAsset.chats, t.navChats, count: unread, badgeKey: const Key('navChatsBadge')),
          navDestination(NavIconAsset.profile, t.profileTitle),
        ],
      ),
    );
  }
}
