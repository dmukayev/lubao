import '../api/api_client.dart';
import '../models/common.dart';
import '../models/user.dart';

class CompanyRepository {
  CompanyRepository(this._client);

  final ApiClient _client;

  Future<Company> me() async {
    final res = await _client.dio.get('/companies/me');
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  /// Сменить пароль, уже находясь в аккаунте (отдельно от «Забыли пароль» —
  /// AuthRepository.resetPassword, для разлогиненных).
  Future<void> setPassword(String password) async {
    await _client.dio.post('/companies/me/password', data: {'password': password});
  }

  Future<List<CompanyMember>> members() async {
    final res = await _client.dio.get('/companies/me/members');
    return (res.data as List<dynamic>).map((e) => CompanyMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Пригласить сотрудника по ссылке (задача 025, «Путь Б» из 022) —
  /// только владелец. Возвращает токен, чтобы показать ссылку с кнопками
  /// «Скопировать» / «Поделиться» сразу, не дожидаясь письма.
  Future<String> createInvite({required String email, required CompanyMemberRole role}) async {
    final res = await _client.dio.post('/companies/me/invites', data: {
      'email': email,
      'role': role == CompanyMemberRole.owner ? 'OWNER' : 'LOGIST',
    });
    return (res.data as Map<String, dynamic>)['token'] as String;
  }
}
