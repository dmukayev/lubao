import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import '../../router/tab_scroll.dart';
import 'trips/driver_trips_screen.dart';

/// 053 п.6: отдельного списка уведомлений нет — непрочитанные сообщения и
/// «Нужно ответить» цифрами на вкладках; обновляются по сокету.
/// 056 п.6: внизу Грузы · Мои рейсы · Чаты · Профиль.
class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.navigationShell});

  /// 060: вкладки в памяти (StatefulShellRoute.indexedStack).
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  static const _tabIds = ['driver.feed', 'driver.trips', 'driver.chats', 'driver.profile'];

  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final realtime = ref.read(realtimeServiceProvider);
    void chats(Object? _) => ref.invalidate(myChatsProvider);
    void trips(Object? _) {
      ref.invalidate(dealsMineProvider);
      ref.invalidate(myResponsesProvider);
      // 058 п.5: встречная цена — карточка груза обновится сама.
      ref.invalidate(myCargoResponseProvider);
      // 058 п.6: «Компания X добавила вас» — без перезапуска.
      ref.invalidate(driverCompaniesProvider);
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


  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final currentIndex = widget.navigationShell.currentIndex;
    final unread = (ref.watch(myChatsProvider).valueOrNull ?? const <MyChatEntry>[]).fold<int>(0, (sum, c) => sum + c.unreadCount);
    // «Нужно ответить»: выбран — подтвердите, приглашён — ответьте.
    final waiting = tripsNeedAnswerCount(
      ref.watch(dealsMineProvider).valueOrNull ?? const <Deal>[],
      ref.watch(myResponsesProvider).valueOrNull ?? const <MyResponseEntry>[],
    );

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        // 060: переключение мгновенное, данные — из памяти (свежие приходят
        // по сокету); повторное нажатие — прокрутка наверх.
        onDestinationSelected: (index) {
          if (index == currentIndex) {
            scrollTabToTop(_tabIds[index]);
          } else {
            widget.navigationShell.goBranch(index);
          }
        },
        // Эталон 33: свои цветные иконки (design/brand/nav).
        destinations: [
          navDestination(NavIconAsset.cargo, t.navFeed),
          navDestination(NavIconAsset.trips, t.navTrips, count: waiting, badgeKey: const Key('navTripsBadge')),
          navDestination(NavIconAsset.chats, t.navChats, count: unread, badgeKey: const Key('navChatsBadge')),
          navDestination(NavIconAsset.profile, t.profileTitle),
        ],
      ),
    );
  }
}
