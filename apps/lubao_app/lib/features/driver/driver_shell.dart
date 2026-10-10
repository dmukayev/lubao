import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import 'trips/driver_trips_screen.dart';

/// 053 п.6: отдельного списка уведомлений нет — непрочитанные сообщения и
/// «Нужно ответить» цифрами на вкладках; обновляются по сокету.
/// 056 п.6: внизу Грузы · Мои рейсы · Чаты · Профиль.
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  static const _tabs = ['/driver/feed', '/driver/trips', '/driver/chats', '/driver/profile'];

  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final realtime = ref.read(realtimeServiceProvider);
    void chats(Object? _) => ref.invalidate(myChatsProvider);
    void trips(Object? _) {
      ref.invalidate(dealsMineProvider);
      ref.invalidate(myResponsesProvider);
    }
    _subs
      ..add(realtime.onMessageNew.listen(chats))
      ..add(realtime.onMessageRead.listen(chats))
      ..add(realtime.onChatUpdated.listen(chats))
      ..add(realtime.onDealUpdated.listen(trips))
      // Пригласили / выбрали / отклонили — цифра «Мои рейсы» и шапка в ленте.
      ..add(realtime.onResponsesUpdated.listen(trips))
      // Пока сокета не было, события пропущены — перечитать.
      ..add(realtime.onReconnected.listen((_) {
        chats(null);
        trips(null);
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
    // «Нужно ответить»: выбран — подтвердите, приглашён — ответьте.
    final waiting = tripsNeedAnswerCount(
      ref.watch(dealsMineProvider).valueOrNull ?? const <Deal>[],
      ref.watch(myResponsesProvider).valueOrNull ?? const <MyResponseEntry>[],
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            ref.invalidate(dealsMineProvider);
            ref.invalidate(myResponsesProvider);
          }
          if (index == 2) ref.invalidate(myChatsProvider);
          context.go(_tabs[index]);
        },
        destinations: [
          NavigationDestination(icon: const Icon(LucideIcons.truck), label: t.navFeed),
          NavigationDestination(icon: _counted(tripsTabIcon, waiting, 'navTripsBadge'), label: t.navTrips),
          NavigationDestination(icon: _counted(LucideIcons.messageCircle, unread, 'navChatsBadge'), label: t.navChats),
          NavigationDestination(icon: const Icon(LucideIcons.user), label: t.profileTitle),
        ],
      ),
    );
  }
}
