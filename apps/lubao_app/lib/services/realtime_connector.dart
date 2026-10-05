import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';

/// Держит один Socket.IO-сокет на сессию (задача 011, п.6) — подключается,
/// когда есть сессия, отключается при логауте. По аналогии с
/// LocationReporter: побочный эффект, подвешенный на sessionProvider,
/// не экран.
class RealtimeConnector {
  RealtimeConnector(this._ref) {
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next != null) {
        _ref.read(realtimeServiceProvider).connect();
      } else {
        _ref.read(realtimeServiceProvider).disconnect();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
}

final realtimeConnectorProvider = Provider<RealtimeConnector>((ref) => RealtimeConnector(ref));
