import '../api/api_client.dart';
import '../models/admin.dart';
import '../models/common.dart';
import '../models/reference_data.dart';

class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  Future<AdminStats> stats() async {
    final res = await _client.dio.get('/admin/stats');
    return AdminStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AdminVerificationDocument>> verificationDocuments({String? status}) async {
    final res = await _client.dio.get('/admin/verification-documents', queryParameters: {if (status != null) 'status': status});
    return (res.data as List<dynamic>)
        .map((e) => AdminVerificationDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminVerificationDocument> reviewDocument(String id, {required bool approve, String? rejectReason}) async {
    final res = await _client.dio.patch('/admin/verification-documents/$id', data: {
      'status': approve ? 'APPROVED' : 'REJECTED',
      if (!approve && rejectReason != null) 'rejectReason': rejectReason,
    });
    return AdminVerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AdminComplaint>> complaints({String? status}) async {
    final res = await _client.dio.get('/admin/complaints', queryParameters: {if (status != null) 'status': status});
    return (res.data as List<dynamic>).map((e) => AdminComplaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminComplaint> resolveComplaint(String id, ComplaintStatus status) async {
    final res = await _client.dio.patch('/admin/complaints/$id', data: {'status': complaintStatusToJson(status)});
    return AdminComplaint.fromJson(res.data as Map<String, dynamic>);
  }

  /// Поиск/фильтр/пагинация (задача 026, п.2/п.10) — таблица компаний в
  /// админке, а не весь список целиком (на пилоте уже сотни строк).
  Future<AdminSearchPage<AdminCompanyRow>> searchCompanies({String? q, bool? verified, bool? blocked, int page = 1, int pageSize = 50}) async {
    final res = await _client.dio.get('/admin/companies', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (verified != null) 'verified': verified,
      if (blocked != null) 'blocked': blocked,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    return AdminSearchPage(
      items: (data['items'] as List<dynamic>).map((e) => AdminCompanyRow.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  Future<AdminCompanyDetail> companyDetail(String id) async {
    final res = await _client.dio.get('/admin/companies/$id');
    return AdminCompanyDetail.fromJson(res.data as Map<String, dynamic>);
  }

  /// `reason` обязателен на бэкенде (задача 026, п.5) — любое изменение
  /// «Проверена» видно в логе карточки. `force` — поставить «Проверена» без
  /// одобренных документов («проверил лично»).
  Future<void> setCompanyVerified(String id, bool isVerified, {required String reason, bool force = false}) async {
    await _client.dio.patch('/admin/companies/$id/verify', data: {'isVerified': isVerified, 'reason': reason, 'force': force});
  }

  Future<String> resetCompanyPassword(String companyId) async {
    final res = await _client.dio.post('/admin/companies/$companyId/reset-password');
    return (res.data as Map<String, dynamic>)['tempPassword'] as String;
  }

  Future<void> blockCompany(String companyId, {required String reason}) async {
    await _client.dio.post('/admin/companies/$companyId/block', data: {'reason': reason});
  }

  Future<void> unblockCompany(String companyId, {required String reason}) async {
    await _client.dio.post('/admin/companies/$companyId/unblock', data: {'reason': reason});
  }

  Future<AdminSearchPage<AdminDriverRow>> searchDrivers({String? q, bool? verified, bool? blocked, int page = 1, int pageSize = 50}) async {
    final res = await _client.dio.get('/admin/drivers', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (verified != null) 'verified': verified,
      if (blocked != null) 'blocked': blocked,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    return AdminSearchPage(
      items: (data['items'] as List<dynamic>).map((e) => AdminDriverRow.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  Future<AdminDriverDetail> driverDetail(String id) async {
    final res = await _client.dio.get('/admin/drivers/$id');
    return AdminDriverDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setDriverVerified(String id, bool isVerified, {required String reason, bool force = false}) async {
    await _client.dio.patch('/admin/drivers/$id/verify', data: {'isVerified': isVerified, 'reason': reason, 'force': force});
  }

  Future<void> blockUser(String userId, {required String reason}) async {
    await _client.dio.post('/admin/users/$userId/block', data: {'reason': reason});
  }

  Future<void> unblockUser(String userId, {required String reason}) async {
    await _client.dio.post('/admin/users/$userId/unblock', data: {'reason': reason});
  }

  Future<void> revokeSessions(String userId) async {
    await _client.dio.post('/admin/users/$userId/revoke-sessions');
  }

  Future<BodyType> createBodyType(String code, I18nText name) async {
    final res = await _client.dio.post('/admin/reference/body-types', data: {'code': code, 'name': name.toJson()});
    return BodyType.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Permit> createPermit(String code, I18nText name) async {
    final res = await _client.dio.post('/admin/reference/permits', data: {'code': code, 'name': name.toJson()});
    return Permit.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LoadingPoint> createPoint(String cityId, I18nText name) async {
    final res = await _client.dio.post('/admin/reference/points', data: {'cityId': cityId, 'name': name.toJson()});
    return LoadingPoint.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setPointActive(String id, bool isActive) async {
    await _client.dio.patch('/admin/reference/points/$id/active', data: {'isActive': isActive});
  }

  Future<List<AdminPendingCity>> pendingCities() async {
    final res = await _client.dio.get('/admin/cities/pending');
    return (res.data as List<dynamic>).map((e) => AdminPendingCity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveCity(String id, I18nText name) async {
    await _client.dio.patch('/admin/cities/$id/moderate', data: {'action': 'APPROVE', 'name': name.toJson()});
  }

  Future<void> mergeCity(String id, String mergeIntoCityId) async {
    await _client.dio
        .patch('/admin/cities/$id/moderate', data: {'action': 'MERGE', 'mergeIntoCityId': mergeIntoCityId});
  }

  Future<void> rejectCity(String id, {String? rejectReason}) async {
    await _client.dio.patch('/admin/cities/$id/moderate', data: {
      'action': 'REJECT',
      if (rejectReason != null) 'rejectReason': rejectReason,
    });
  }
}
