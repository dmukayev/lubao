import '../api/api_client.dart';
import '../models/user.dart';

class CompanyRepository {
  CompanyRepository(this._client);

  final ApiClient _client;

  Future<Company> me() async {
    final res = await _client.dio.get('/companies/me');
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  /// Самостоятельная регистрация компании владельцем (задача 022, «Путь А»)
  /// — сразу после входа по коду на email, когда company == null.
  Future<(Company, CompanyMember)> register({
    required String ownerName,
    required String companyName,
    String? companyNameRu,
    required String countryId,
  }) async {
    final res = await _client.dio.post('/companies/register', data: {
      'ownerName': ownerName,
      'companyName': companyName,
      if (companyNameRu != null) 'companyNameRu': companyNameRu,
      'countryId': countryId,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      Company.fromJson(data['company'] as Map<String, dynamic>),
      CompanyMember.fromJson(data['companyMember'] as Map<String, dynamic>),
    );
  }

  Future<List<CompanyMember>> members() async {
    final res = await _client.dio.get('/companies/me/members');
    return (res.data as List<dynamic>).map((e) => CompanyMember.fromJson(e as Map<String, dynamic>)).toList();
  }
}
