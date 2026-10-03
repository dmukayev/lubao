import '../api/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<void> requestDriverCode({required String phone}) async {
    await _client.dio.post('/auth/driver/request-code', data: {'phone': phone});
  }

  /// null, если код неверный/истёк — иначе сессия (с driver==null, если это
  /// ещё не зарегистрированный водитель и анкету нужно донаполнить).
  Future<Session> verifyDriverCode({required String phone, required String code}) async {
    final res = await _client.dio.post('/auth/driver/verify-code', data: {'phone': phone, 'code': code});
    final session = Session.fromJson(res.data as Map<String, dynamic>);
    _client.setCurrentUserId(session.user.id);
    return session;
  }

  Future<Session> loginCompany({required String email, required String password}) async {
    final res = await _client.dio.post('/auth/dev-login/company', data: {'email': email, 'password': password});
    final session = Session.fromJson(res.data as Map<String, dynamic>);
    _client.setCurrentUserId(session.user.id);
    return session;
  }

  Future<Session> loginAdmin({required String email, required String password}) async {
    final res = await _client.dio.post('/auth/dev-login/admin', data: {'email': email, 'password': password});
    final session = Session.fromJson(res.data as Map<String, dynamic>);
    _client.setCurrentUserId(session.user.id);
    return session;
  }

  void logout() => _client.setCurrentUserId(null);
}
