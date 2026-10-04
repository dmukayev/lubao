import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'api_providers.dart';

/// true, пока идёт попытка восстановить сессию из secure storage при
/// старте приложения (см. SessionController._restore) — роутер показывает
/// сплэш, пока это не завершится, чтобы не мигнуть экраном входа.
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

  Future<void> requestDriverCode(String phone) async {
    await _ref.read(authRepositoryProvider).requestDriverCode(phone: phone);
  }

  Future<void> verifyDriverCode(String phone, String code) async {
    final session = await _ref.read(authRepositoryProvider).verifyDriverCode(phone: phone, code: code);
    state = session;
  }

  Future<Session> loginCompany(String email, String password) async {
    final session = await _ref.read(authRepositoryProvider).loginCompany(email: email, password: password);
    state = session;
    return session;
  }

  Future<Session> registerCompany({
    required String email,
    required String password,
    required String ownerName,
    required String companyName,
    String? companyNameRu,
    required String countryId,
  }) async {
    final session = await _ref.read(authRepositoryProvider).registerCompany(
          email: email,
          password: password,
          ownerName: ownerName,
          companyName: companyName,
          companyNameRu: companyNameRu,
          countryId: countryId,
        );
    state = session;
    return session;
  }

  Future<Session> acceptInvite(
    String token, {
    required String password,
    required String name,
    String? phone,
    String? wechat,
  }) async {
    final session = await _ref
        .read(authRepositoryProvider)
        .acceptInvite(token, password: password, name: name, phone: phone, wechat: wechat);
    state = session;
    return session;
  }

  /// Подтверждение email не блокирует вход (задача 025) — только снимает
  /// плашку-напоминание в кабинете после успешного кода.
  Future<void> verifyEmail(String code) async {
    await _ref.read(authRepositoryProvider).verifyEmail(code: code);
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      user: AppUser(
        id: current.user.id,
        role: current.user.role,
        phone: current.user.phone,
        email: current.user.email,
        locale: current.user.locale,
        emailVerifiedAt: DateTime.now(),
      ),
    );
  }

  void updateDriver(Driver driver) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(driver: driver);
  }

  void updateCompany(Company company, CompanyMember companyMember) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(company: company, companyMember: companyMember);
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
