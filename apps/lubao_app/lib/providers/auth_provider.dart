import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'api_providers.dart';

class SessionController extends StateNotifier<Session?> {
  SessionController(this._ref) : super(null);

  final Ref _ref;

  Future<void> requestDriverCode(String phone) async {
    await _ref.read(authRepositoryProvider).requestDriverCode(phone: phone);
  }

  Future<void> verifyDriverCode(String phone, String code) async {
    final session = await _ref.read(authRepositoryProvider).verifyDriverCode(phone: phone, code: code);
    state = session;
  }

  Future<void> loginCompany(String email, String password) async {
    final session = await _ref.read(authRepositoryProvider).loginCompany(email: email, password: password);
    state = session;
  }

  void updateDriver(Driver driver) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(driver: driver);
  }

  void logout() {
    _ref.read(authRepositoryProvider).logout();
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionController, Session?>((ref) => SessionController(ref));
