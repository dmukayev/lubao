import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_providers.dart';

/// 078: связь пропала, а экран ничего не запрашивает — полоса «Нет связи»
/// всё равно должна появиться. Пока приложение на экране — проверка раз в
/// 10 с и сразу при возврате из фона (короткий запрос /health).
class ConnectionWatcher {
  ConnectionWatcher(this._ref) {
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _check();
        _start();
      },
      onHide: _stop,
    );
    _start();
  }

  final Ref _ref;
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _check() => unawaited(_ref.read(apiClientProvider).checkConnection());

  void dispose() {
    _stop();
    _lifecycle.dispose();
  }
}

final connectionWatcherProvider = Provider<ConnectionWatcher>((ref) {
  final watcher = ConnectionWatcher(ref);
  ref.onDispose(watcher.dispose);
  return watcher;
});
