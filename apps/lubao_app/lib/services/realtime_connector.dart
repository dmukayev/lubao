import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';

/// Держит один Socket.IO-сокет на сессию (задача 011, п.6) — подключается,
/// когда есть сессия, отключается при логауте. По аналогии с
/// LocationReporter: побочный эффект, подвешенный на sessionProvider,
/// не экран.
///
/// Тот же сигнал «сеть снова есть» дозаправляет очередь контакт-событий
/// (задача 029, п.14) — звонок/WhatsApp без сети на границе не теряется,
/// а досылается при следующем подключении/переподключении сокета.
class RealtimeConnector {
  RealtimeConnector(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next != null) {
        _ref.read(realtimeServiceProvider).connect();
        unawaited(_ref.read(cargoRepositoryProvider).flushPendingContactEvents());
      } else {
        _ref.read(realtimeServiceProvider).disconnect();
      }
    }, fireImmediately: true);

    _ref.read(realtimeServiceProvider).onReconnected.listen((_) {
      unawaited(_ref.read(cargoRepositoryProvider).flushPendingContactEvents());
    });
  }

  final Ref _ref;
}

final realtimeConnectorProvider = Provider<RealtimeConnector>((ref) => RealtimeConnector(ref));
