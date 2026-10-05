import '../api/api_client.dart';
import '../models/admin.dart';
import '../models/common.dart';
import '../models/reference_data.dart';

class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  Future<AdminStats> stats({String period = 'today'}) async {
    final res = await _client.dio.get('/admin/stats', queryParameters: {'period': period});
    return AdminStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminAttention> attention() async {
    final res = await _client.dio.get('/admin/attention');
    return AdminAttention.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AdminEvent>> recentEvents({int limit = 10}) async {
    final res = await _client.dio.get('/admin/events/recent', queryParameters: {'limit': limit});
    return (res.data as List<dynamic>).map((e) => AdminEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminAuditLogEntry>> auditLog({String? actorUserId, String? entityType, DateTime? since, int limit = 100}) async {
    final res = await _client.dio.get('/admin/audit', queryParameters: {
      if (actorUserId != null) 'actorUserId': actorUserId,
      if (entityType != null) 'entityType': entityType,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      'limit': limit,
    });
    return (res.data as List<dynamic>).map((e) => AdminAuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, String>> settings() async {
    final res = await _client.dio.get('/admin/settings');
    return (res.data as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
  }

  Future<void> setSetting(String key, String value, {String? reason}) async {
    await _client.dio.patch('/admin/settings/$key', data: {'value': value, if (reason != null) 'reason': reason});
  }

  /// «Настройки → Перевод» (задача 010, п.8).
  Future<AdminTranslationStats> translationStats() async {
    final res = await _client.dio.get('/admin/translation-stats');
    return AdminTranslationStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminSearchResults> search(String q) async {
    final res = await _client.dio.get('/admin/search', queryParameters: {'q': q});
    return AdminSearchResults.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminSearchPage<AdminCargoRow>> searchCargos({
    String? q,
    String? status,
    String? companyId,
    String? destinationCountryId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _client.dio.get('/admin/cargos', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null) 'status': status,
      if (companyId != null) 'companyId': companyId,
      if (destinationCountryId != null) 'destinationCountryId': destinationCountryId,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    return AdminSearchPage(
      items: (data['items'] as List<dynamic>).map((e) => AdminCargoRow.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  Future<AdminSearchPage<AdminDealRow>> searchDeals({
    String? q,
    String? status,
    bool? stale,
    String? driverId,
    String? companyId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _client.dio.get('/admin/deals', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null) 'status': status,
      if (stale != null) 'stale': stale,
      if (driverId != null) 'driverId': driverId,
      if (companyId != null) 'companyId': companyId,
      'page': page,
      'pageSize': pageSize,
    });
    final data = res.data as Map<String, dynamic>;
    return AdminSearchPage(
      items: (data['items'] as List<dynamic>).map((e) => AdminDealRow.fromJson(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int,
    );
  }

  Future<List<AdminVerificationQueueItem>> verificationQueue(String type) async {
    final res = await _client.dio.get('/admin/verification/queue', queryParameters: {'type': type});
    return (res.data as List<dynamic>).map((e) => AdminVerificationQueueItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminVerificationDriverProfile> verificationDriverProfile(String id) async {
    final res = await _client.dio.get('/admin/verification/drivers/$id');
    return AdminVerificationDriverProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminVerificationCompanyProfile> verificationCompanyProfile(String id) async {
    final res = await _client.dio.get('/admin/verification/companies/$id');
    return AdminVerificationCompanyProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> returnDriverForRework(
    String id, {
    required List<VerificationReworkDecision> decisions,
    String? note,
    Map<String, bool?>? crossChecks,
  }) async {
    await _client.dio.post('/admin/verification/drivers/$id/return', data: {
      'decisions': decisions.map((d) => d.toJson()).toList(),
      if (note != null) 'note': note,
      if (crossChecks != null) 'crossChecks': crossChecks,
    });
  }

  Future<void> returnCompanyForRework(
    String id, {
    required List<VerificationReworkDecision> decisions,
    String? note,
    Map<String, bool?>? crossChecks,
  }) async {
    await _client.dio.post('/admin/verification/companies/$id/return', data: {
      'decisions': decisions.map((d) => d.toJson()).toList(),
      if (note != null) 'note': note,
      if (crossChecks != null) 'crossChecks': crossChecks,
    });
  }

  Future<AdminVerificationDocument> reviewDocument(
    String id, {
    required bool approve,
    String? rejectReason,
    Map<String, String>? confirmedFields,
  }) async {
    final res = await _client.dio.patch('/admin/verification-documents/$id', data: {
      'status': approve ? 'APPROVED' : 'REJECTED',
      if (!approve && rejectReason != null) 'rejectReason': rejectReason,
      if (confirmedFields != null && confirmedFields.isNotEmpty) 'confirmedFields': confirmedFields,
    });
    return AdminVerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }

  /// Блок «Распознано» (задача 031, п.22) — отдельный запрос при открытии
  /// документа на проверке, не часть общего профиля (checkMatches бьёт в
  /// базу на каждое поле — считать его для всей истории документов не нужно).
  Future<AdminDocumentRecognition> documentRecognition(String documentId) async {
    final res = await _client.dio.get('/admin/verification-documents/$documentId/recognition');
    return AdminDocumentRecognition.fromJson(res.data as Map<String, dynamic>);
  }

  /// Полное значение идентификатора по кнопке «Показать» (п.16/24) —
  /// каждый вызов пишется в audit_log на бэкенде.
  Future<String?> revealIdentifier(String identifierId) async {
    final res = await _client.dio.post('/admin/identifiers/$identifierId/reveal');
    return (res.data as Map<String, dynamic>)['value'] as String?;
  }

  Future<AdminCargoDetail> cargoDetail(String id) async {
    final res = await _client.dio.get('/admin/cargos/$id');
    return AdminCargoDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateCargo(
    String id, {
    String? destinationCountryId,
    String? destinationCityId,
    String? bodyTypeId,
    double? weightKg,
    double? volumeM3,
    List<String>? photoUrls,
    double? price,
    String? currency,
    DateTime? readyDate,
    String? description,
    required String reason,
  }) async {
    await _client.dio.patch('/admin/cargos/$id', data: {
      if (destinationCountryId != null) 'destinationCountryId': destinationCountryId,
      if (destinationCityId != null) 'destinationCityId': destinationCityId,
      if (bodyTypeId != null) 'bodyTypeId': bodyTypeId,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (photoUrls != null) 'photoUrls': photoUrls,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (readyDate != null) 'readyDate': readyDate.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      'reason': reason,
    });
  }

  Future<void> unpublishCargo(String id, {required String reason}) async {
    await _client.dio.post('/admin/cargos/$id/unpublish', data: {'reason': reason});
  }

  Future<AdminDealDetail> dealDetail(String id) async {
    final res = await _client.dio.get('/admin/deals/$id');
    return AdminDealDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AdminChatMessage>> dealChat(String id) async {
    final res = await _client.dio.get('/admin/deals/$id/chat');
    return (res.data as List<dynamic>).map((e) => AdminChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> advanceDealStatus(String id, {required String status, required String reason}) async {
    await _client.dio.patch('/admin/deals/$id/status', data: {'status': status, 'reason': reason});
  }

  Future<void> cancelDeal(String id, {required String reason}) async {
    await _client.dio.post('/admin/deals/$id/cancel', data: {'reason': reason});
  }

  /// `tab` — NEW/IN_REVIEW/CLOSED (задача 028, п.24a; раньше запрашивали
  /// только `status=OPEN`, и жалоба пропадала из вида после «В работе»).
  Future<List<AdminComplaint>> complaints({String? tab, bool mine = false}) async {
    final res = await _client.dio.get('/admin/complaints', queryParameters: {
      if (tab != null) 'tab': tab,
      if (mine) 'mine': 'true',
    });
    return (res.data as List<dynamic>).map((e) => AdminComplaint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({int newCount, int inReviewCount, int closedCount})> complaintCounts() async {
    final res = await _client.dio.get('/admin/complaints/counts');
    final data = res.data as Map<String, dynamic>;
    return (newCount: data['newCount'] as int, inReviewCount: data['inReviewCount'] as int, closedCount: data['closedCount'] as int);
  }

  Future<AdminComplaintDetail> complaintDetail(String id) async {
    final res = await _client.dio.get('/admin/complaints/$id');
    return AdminComplaintDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> assignComplaint(String id) async {
    await _client.dio.post('/admin/complaints/$id/assign');
  }

  Future<void> unassignComplaint(String id) async {
    await _client.dio.post('/admin/complaints/$id/unassign');
  }

  /// Решение по жалобе (п.24d) — один из 4 вариантов, ответ автору всегда
  /// обязателен.
  Future<void> resolveComplaint(String id, {required String resolution, required String resolutionNote}) async {
    await _client.dio.patch('/admin/complaints/$id', data: {'resolution': resolution, 'resolutionNote': resolutionNote});
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
  Future<void> setCompanyVerified(
    String id,
    bool isVerified, {
    required String reason,
    bool force = false,
    Map<String, bool?>? crossChecks,
  }) async {
    await _client.dio.patch('/admin/companies/$id/verify', data: {
      'isVerified': isVerified,
      'reason': reason,
      'force': force,
      if (crossChecks != null) 'crossChecks': crossChecks,
    });
  }

  /// Общая панель редактирования (задача 028, п.18/20).
  Future<void> updateCompany(
    String id, {
    String? name,
    String? nameRu,
    String? countryId,
    String? city,
    String? legalAddress,
    String? taxId,
    required String reason,
  }) async {
    await _client.dio.patch('/admin/companies/$id', data: {
      if (name != null) 'name': name,
      if (nameRu != null) 'nameRu': nameRu,
      if (countryId != null) 'countryId': countryId,
      if (city != null) 'city': city,
      if (legalAddress != null) 'legalAddress': legalAddress,
      if (taxId != null) 'taxId': taxId,
      'reason': reason,
    });
  }

  /// «Передать владение» (п.20) — тот же вызов, роль нового владельца OWNER.
  Future<void> setMemberRole(String companyId, String userId, String role, {required String reason}) async {
    await _client.dio.patch('/admin/companies/$companyId/members/$userId/role', data: {'role': role, 'reason': reason});
  }

  Future<void> removeMember(String companyId, String userId, {required String reason}) async {
    await _client.dio.delete('/admin/companies/$companyId/members/$userId', data: {'reason': reason});
  }

  Future<void> changeMemberEmail(String companyId, String userId, String email, {required String reason}) async {
    await _client.dio.patch('/admin/companies/$companyId/members/$userId/email', data: {'email': email, 'reason': reason});
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

  Future<AdminSearchPage<AdminDriverRow>> searchDrivers({
    String? q,
    bool? verified,
    bool? blocked,
    String? onSite,
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _client.dio.get('/admin/drivers', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (verified != null) 'verified': verified,
      if (blocked != null) 'blocked': blocked,
      if (onSite != null) 'onSite': onSite,
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

  Future<void> setDriverVerified(
    String id,
    bool isVerified, {
    required String reason,
    bool force = false,
    Map<String, bool?>? crossChecks,
  }) async {
    await _client.dio.patch('/admin/drivers/$id/verify', data: {
      'isVerified': isVerified,
      'reason': reason,
      'force': force,
      if (crossChecks != null) 'crossChecks': crossChecks,
    });
  }

  /// Общая панель редактирования (задача 028, п.18/19).
  Future<void> updateDriver(
    String id, {
    String? fullName,
    String? phone,
    String? homeCityId,
    bool? anyCountry,
    List<String>? countryIds,
    List<String>? permitIds,
    String? vehicleBodyTypeId,
    double? vehicleCapacityTons,
    double? vehicleLengthM,
    String? vehiclePlateNumber,
    String? vehicleBrand,
    required String reason,
  }) async {
    final hasVehicleChange = vehicleBodyTypeId != null || vehicleCapacityTons != null || vehicleLengthM != null || vehiclePlateNumber != null || vehicleBrand != null;
    await _client.dio.patch('/admin/drivers/$id', data: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (homeCityId != null) 'homeCityId': homeCityId,
      if (anyCountry != null) 'anyCountry': anyCountry,
      if (countryIds != null) 'countryIds': countryIds,
      if (permitIds != null) 'permitIds': permitIds,
      if (hasVehicleChange)
        'vehicle': {
          if (vehicleBodyTypeId != null) 'bodyTypeId': vehicleBodyTypeId,
          if (vehicleCapacityTons != null) 'capacityTons': vehicleCapacityTons,
          if (vehicleLengthM != null) 'lengthM': vehicleLengthM,
          if (vehiclePlateNumber != null) 'plateNumber': vehiclePlateNumber,
          if (vehicleBrand != null) 'brand': vehicleBrand,
        },
      'reason': reason,
    });
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

  Future<void> updateBodyType(String id, {I18nText? name, bool? isActive, int? sortOrder, required String reason}) async {
    await _client.dio.patch('/admin/reference/body-types/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (isActive != null) 'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'reason': reason,
    });
  }

  Future<void> updatePermit(String id, {I18nText? name, bool? isActive, int? sortOrder, required String reason}) async {
    await _client.dio.patch('/admin/reference/permits/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (isActive != null) 'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'reason': reason,
    });
  }

  /// Общая правка точки — названия, город, координаты, включить/выключить
  /// (задача 028, п.21); заменяет узкий `setPointActive` без следа в журнале.
  Future<void> updatePoint(String id, {I18nText? name, String? cityId, double? lat, double? lng, bool? isActive, required String reason}) async {
    await _client.dio.patch('/admin/reference/points/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (cityId != null) 'cityId': cityId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (isActive != null) 'isActive': isActive,
      'reason': reason,
    });
  }

  /// Правка уже APPROVED города — область и координаты (нужны «Близко к
  /// дому», задача 016); отдельно от `moderateCity`, который только для
  /// очереди PENDING.
  Future<void> updateCity(String id, {I18nText? name, String? regionId, double? lat, double? lng, required String reason}) async {
    await _client.dio.patch('/admin/cities/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (regionId != null) 'regionId': regionId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'reason': reason,
    });
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
