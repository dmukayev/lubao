import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'api_providers.dart';

/// true, пока идёт попытка восстановить сессию из secure storage при
/// старте приложения — роутер показывает сплэш, пока это не завершится.
final sessionRestoringProvider = StateProvider<bool>((ref) => true);

class SessionController extends StateNotifier<Session?> {
  SessionController(this._ref) : super(null) {
    _sessionExpiredSub = _ref.read(apiClientProvider).onSessionExpired.listen((_) {
      state = null;
    });
    _restore();
  }

  final Ref _ref;
  late final StreamSubscription<void> _sessionExpiredSub;

  Future<void> _restore() async {
    try {
      state = await _ref.read(authRepositoryProvider).restore();
    } finally {
      _ref.read(sessionRestoringProvider.notifier).state = false;
    }
  }

  Future<void> login(String email, String password) async {
    final session = await _ref.read(authRepositoryProvider).loginAdmin(email: email, password: password);
    state = session;
  }

  Future<void> logout() async {
    await _ref.read(authRepositoryProvider).logout();
    state = null;
  }

  @override
  void dispose() {
    _sessionExpiredSub.cancel();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionController, Session?>((ref) => SessionController(ref));
