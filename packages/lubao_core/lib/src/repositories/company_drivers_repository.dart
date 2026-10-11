import '../api/api_client.dart';
import '../models/company_driver.dart';

/// 058 п.6: «Мои водители» (логист) и «Компании, где я в списке» (водитель).
class CompanyDriversRepository {
  CompanyDriversRepository(this._client);

  final ApiClient _client;

  Future<List<CompanyDriverEntry>> mine() async {
    final res = await _client.dio.get('/company-drivers');
    return (res.data as List<dynamic>).map((e) => CompanyDriverEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// «Создать водителя» → ссылка компании для отправки водителю. 061 п.1: ответ
  /// одинаковый на любой номер — есть ли человек в Lubao, не узнать.
  Future<String> create({required String name, required String phone}) async {
    final res = await _client.dio.post('/company-drivers', data: {'name': name, 'phone': phone});
    return (res.data as Map<String, dynamic>)['url'] as String? ?? '';
  }

  Future<void> setSaved(String driverId, bool saved) async {
    if (saved) {
      await _client.dio.post('/company-drivers/$driverId/save');
    } else {
      await _client.dio.delete('/company-drivers/$driverId/save');
    }
  }

  Future<List<DriverCompanyEntry>> myCompanies() async {
    final res = await _client.dio.get('/drivers/me/companies');
    return (res.data as List<dynamic>).map((e) => DriverCompanyEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> accept(String companyId) => _client.dio.post('/drivers/me/companies/$companyId/accept');
  Future<void> decline(String companyId) => _client.dio.post('/drivers/me/companies/$companyId/decline');
  Future<void> leave(String companyId) => _client.dio.post('/drivers/me/companies/$companyId/leave');
}
