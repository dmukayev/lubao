import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';

/// 053 п.6: отдельного списка уведомлений нет — непрочитанные сообщения и
/// сделки, ждущие водителя, цифрами на вкладках; обновляются по сокету.
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  static const _tabs = ['/driver/feed', '/driver/chats', '/driver/deals', '/driver/profile'];

  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final realtime = ref.read(realtimeServiceProvider);
    void chats(Object? _) => ref.invalidate(myChatsProvider);
    _subs
      ..add(realtime.onMessageNew.listen(chats))
      ..add(realtime.onMessageRead.listen(chats))
      ..add(realtime.onChatUpdated.listen(chats))
      ..add(realtime.onDealUpdated.listen((_) => ref.invalidate(dealsMineProvider)));
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

  Widget _counted(IconData icon, int count, String key) => Badge.count(
        key: Key(key),
        count: count,
        isLabelVisible: count > 0,
        backgroundColor: AppColors.primary,
        child: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
    final unread = (ref.watch(myChatsProvider).valueOrNull ?? const <MyChatEntry>[]).fold<int>(0, (sum, c) => sum + c.unreadCount);
    // Сделки, где ход за водителем: выбран — подтвердите.
    final waiting = (ref.watch(dealsMineProvider).valueOrNull ?? const <Deal>[]).where((d) => d.status == DealStatus.selected).length;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) ref.invalidate(myChatsProvider);
          if (index == 2) ref.invalidate(dealsMineProvider);
          context.go(_tabs[index]);
        },
        destinations: [
          NavigationDestination(icon: const Icon(LucideIcons.truck), label: t.navFeed),
          NavigationDestination(icon: _counted(LucideIcons.messageCircle, unread, 'navChatsBadge'), label: t.navChats),
          NavigationDestination(icon: _counted(LucideIcons.fileCheck2, waiting, 'navDealsBadge'), label: t.navDeals),
          NavigationDestination(icon: const Icon(LucideIcons.user), label: t.profileTitle),
        ],
      ),
    );
  }
}
