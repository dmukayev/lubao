import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../router/tab_scroll.dart';

/// 056 п.5: числа «Грузов» и новые отклики этого сотрудника — цифра на вкладке.
final companyCargoCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(cargoRepositoryProvider).companyCounts();
});

class CompanyShell extends ConsumerStatefulWidget {
  const CompanyShell({super.key, required this.navigationShell});

  /// 060: вкладки в памяти (StatefulShellRoute.indexedStack).
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends ConsumerState<CompanyShell> {
  /// 056 п.4: вкладки «Сделки» у логиста нет — «В работе» и архив в «Грузах».
  static const _tabs = ['/company/cargos', '/company/drivers', '/company/chats', '/company/profile'];
  static const _tabIds = ['company.cargos', 'company.drivers', 'company.chats', 'company.profile'];

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

  bool _isTab(String location) => _tabs.any(location.startsWith);


  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    // Вернулись в «Грузы» (например, из откликов груза) — новые пересчитать.
    // 060: между вкладками ничего не перечитываем — только при возврате с
    // вложенного экрана (отклики, чат).
    if (_lastLocation != null && _lastLocation != location && !_isTab(_lastLocation!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Вернулись из откликов / из чата — новые и непрочитанные пересчитать.
        if (location.startsWith('/company/cargos')) ref.invalidate(companyCargoCountsProvider);
        ref.invalidate(myChatsProvider);
      });
    }
    _lastLocation = location;
    final currentIndex = widget.navigationShell.currentIndex;
    final newResponses = ref.watch(companyCargoCountsProvider).valueOrNull?['newResponses'] ?? 0;
    final unread = (ref.watch(myChatsProvider).valueOrNull ?? const <MyChatEntry>[]).fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        // 060: мгновенно, из памяти; повторное нажатие — наверх.
        onDestinationSelected: (index) {
          if (index == currentIndex) {
            scrollTabToTop(_tabIds[index]);
          } else {
            widget.navigationShell.goBranch(index);
          }
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
