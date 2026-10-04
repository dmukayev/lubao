import '../api/api_client.dart';
import '../api/device_info.dart';
import '../models/session_device.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<void> requestDriverCode({required String phone}) async {
    await _client.dio.post('/auth/phone/request-code', data: {'phone': phone});
  }

  /// null, если код неверный/истёк — иначе сессия (с driver==null, если это
  /// ещё не зарегистрированный водитель и анкету нужно донаполнить).
  Future<Session> verifyDriverCode({required String phone, required String code}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/phone/verify', data: {
      'phone': phone,
      'code': code,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  Future<void> requestEmailCode({required String email}) async {
    await _client.dio.post('/auth/email/request', data: {'email': email});
  }

  /// Вход логиста без пароля (задачи 006, 022): код на email, как у
  /// водителя по SMS. company == null, если это новый пользователь —
  /// регистрация компании продолжается через CompaniesRepository.register.
  Future<Session> verifyEmailCode({required String email, required String code}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/email/verify', data: {
      'email': email,
      'code': code,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  /// Пароль — альтернатива коду (решение 2026-10-04): работает только у
  /// компаний, которые сами его задали (`CompanyRepository.setPassword`).
  Future<Session> loginCompanyPassword({required String email, required String password}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/email/login', data: {
      'email': email,
      'password': password,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  Future<Session> loginAdmin({required String email, required String password}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/admin/login', data: {
      'email': email,
      'password': password,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  /// Восстановление сессии при запуске приложения — если в secure storage
  /// есть валидный access/refresh токен, возвращает текущий профиль без
  /// повторного ввода логина/кода.
  Future<Session?> restore() async {
    final access = await _client.tokenStorage.readAccess();
    if (access == null) return null;
    try {
      final res = await _client.dio.get('/auth/me');
      return Session.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _client.tokenStorage.readRefresh();
    if (refreshToken != null) {
      try {
        await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // лучший вариант — локальный логаут всё равно происходит
      }
    }
    await _client.logoutLocally();
  }

  Future<List<DeviceSession>> listSessions() async {
    final res = await _client.dio.get('/auth/sessions');
    return (res.data as List).map((e) => DeviceSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> revokeSession(String id) async {
    await _client.dio.delete('/auth/sessions/$id');
  }

  Future<void> revokeAllOthers() async {
    await _client.dio.delete('/auth/sessions', queryParameters: {'except': 'current'});
  }

  Future<Session> _sessionFromTokenResponse(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await _client.tokenStorage.save(accessToken, refreshToken);
    return Session.fromJson(data);
  }
}
