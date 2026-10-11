import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_providers.dart';

/// 061 п.10: списки (лента, «Кто свободен») могли устареть — приложение
/// вернулось из фона спустя [staleAfter] или сокет переподключился (события,
/// пока его не было, пропущены). Счётчик растёт — экраны тихо перечитывают,
/// не показывая крутилку поверх прошлых данных.
final staleRefreshProvider = StateProvider<int>((ref) => 0);

/// Дольше этого в фоне — данные считаем устаревшими.
const staleAfter = Duration(minutes: 3);

/// Чистое правило — покрыто тестом.
bool isStaleOnResume(DateTime? hiddenAt, DateTime now) => hiddenAt != null && now.difference(hiddenAt) > staleAfter;

class StaleRefreshWatcher {
  StaleRefreshWatcher(this._ref) {
    _lifecycle = AppLifecycleListener(onStateChange: _onState);
    _reconnected = _ref.read(realtimeServiceProvider).onReconnected.listen((_) => _bump());
  }

  final Ref _ref;
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<Object?> _reconnected;
  DateTime? _hiddenAt;

  void _onState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _hiddenAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        if (isStaleOnResume(_hiddenAt, DateTime.now())) _bump();
        _hiddenAt = null;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _bump() => _ref.read(staleRefreshProvider.notifier).state++;

  void dispose() {
    _lifecycle.dispose();
    unawaited(_reconnected.cancel());
  }
}

final staleRefreshWatcherProvider = Provider<StaleRefreshWatcher>((ref) {
  final watcher = StaleRefreshWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});
