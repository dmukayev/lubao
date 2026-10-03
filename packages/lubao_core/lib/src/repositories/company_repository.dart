import '../api/api_client.dart';
import '../models/user.dart';

class CompanyRepository {
  CompanyRepository(this._client);

  final ApiClient _client;

  Future<Company> me() async {
    final res = await _client.dio.get('/companies/me');
    return Company.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<CompanyMember>> members() async {
    final res = await _client.dio.get('/companies/me/members');
    return (res.data as List<dynamic>).map((e) => CompanyMember.fromJson(e as Map<String, dynamic>)).toList();
  }
}
