import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'api_providers.dart';

class SessionController extends StateNotifier<Session?> {
  SessionController(this._ref) : super(null);

  final Ref _ref;

  Future<void> login(String email, String password) async {
    final session = await _ref.read(authRepositoryProvider).loginAdmin(email: email, password: password);
    state = session;
  }

  void logout() {
    _ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionController, Session?>((ref) => SessionController(ref));
