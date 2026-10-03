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

  Future<List<AdminCompanySummary>> companies() async {
    final res = await _client.dio.get('/admin/companies');
    return (res.data as List<dynamic>).map((e) => AdminCompanySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setCompanyVerified(String id, bool isVerified) async {
    await _client.dio.patch('/admin/companies/$id/verify', data: {'isVerified': isVerified});
  }

  Future<List<AdminDriverSummary>> drivers() async {
    final res = await _client.dio.get('/admin/drivers');
    return (res.data as List<dynamic>).map((e) => AdminDriverSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setDriverVerified(String id, bool isVerified) async {
    await _client.dio.patch('/admin/drivers/$id/verify', data: {'isVerified': isVerified});
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
}
