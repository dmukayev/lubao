import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/admin.dart';
import '../models/common.dart';
import '../utils/date_only.dart';
import '../models/reference_data.dart';

/// Бэкенд отвечает 409 `BLACKLIST_MATCH` (задача 032, п.2), когда среди
/// идентификаторов владельца есть активная блокировка — обычная кнопка
/// «Подтвердить» больше не может это молча проигнорировать, UI должен
/// показать находки и спросить явное подтверждение прежде чем повторить
/// вызов с `force: true`.
class BlacklistMatchException implements Exception {
  BlacklistMatchException(this.blocks);

  final List<AdminBlacklistBlock> blocks;
}

class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  /// Разрез сводки по городам (040, п.9).
  Future<List<CityStatsRow>> statsByCity() async {
    final res = await _client.dio.get('/admin/stats/by-city');
    return (res.data as List<dynamic>).map((e) => CityStatsRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminStats> stats({String period = 'today'}) async {
    final res = await _client.dio.get('/admin/stats', queryParameters: {'period': period});
    return AdminStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminAttention> attention() async {
    final res = await _client.dio.get('/admin/attention');
    return AdminAttention.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Отозвать проверку» машины (044 п.6) — с причиной; техпаспорт снова в очереди.
  Future<void> revokeVehicleVerification(String vehicleId, {required String reason}) async {
    await _client.dio.post('/admin/vehicles/$vehicleId/revoke-verification', data: {'reason': reason});
  }

  /// «Похоже на парсинг» → «Всё в порядке» (043 п.11): скрыть на 7 дней.
  Future<void> dismissSuspiciousContacts(String userId) async {
    await _client.dio.post('/admin/suspicious-contacts/$userId/dismiss');
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

  /// Ручной чёрный список (043 п.4).
  Future<List<AdminBlockedIdentifier>> blacklist({bool activeOnly = true}) async {
    final res = await _client.dio.get('/admin/blacklist', queryParameters: {'active': activeOnly ? 'true' : 'false'});
    return (res.data as List).cast<Map<String, dynamic>>().map(AdminBlockedIdentifier.fromJson).toList();
  }

  Future<void> addToBlacklist({required String type, required String value, required String reason}) async {
    await _client.dio.post('/admin/blacklist', data: {'type': type, 'value': value, 'reason': reason});
  }

  Future<void> liftBlacklist(String id, {required String reason}) async {
    await _client.dio.post('/admin/blacklist/$id/lift', data: {'reason': reason});
  }

  /// Ручная правка курса (042 п.4): автообновление НБ РК её не перезапишет.
  Future<void> setExchangeRate(String currency, double rateToKzt, {required String reason}) async {
    await _client.dio.put('/admin/exchange-rates', data: {'currency': currency, 'rateToKzt': rateToKzt, 'reason': reason});
  }

  /// Каналы кода входа (042 п.3): порядок, вкл/выкл и есть ли ключи.
  Future<List<AdminLoginCodeChannel>> loginCodeChannels() async {
    final res = await _client.dio.get('/admin/login-code-channels');
    return (res.data as List)
        .cast<Map<String, dynamic>>()
        .map((m) => AdminLoginCodeChannel(id: m['id'] as String, enabled: m['enabled'] as bool, configured: m['configured'] as bool))
        .toList();
  }

  Future<void> setLoginCodeChannels(List<AdminLoginCodeChannel> channels) {
    return setSetting('loginCodeChannels', jsonEncode([for (final c in channels) {'id': c.id, 'enabled': c.enabled}]));
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

  /// Та же пара «расшифровать + журнал», что у [revealIdentifier], но для
  /// распознанного ИИН/номера прав ДО одобрения документа (задача 032,
  /// п.4) — в блоке «Распознано» показана маска, полное значение только
  /// по этому запросу (вызывается перед правкой поля, чтобы не
  /// подставлять маску в поле редактирования).
  Future<String?> revealRecognizedField(String documentId, String field) async {
    final res = await _client.dio.post('/admin/verification-documents/$documentId/recognition/$field/reveal');
    return (res.data as Map<String, dynamic>)['value'] as String?;
  }

  /// «Распознать заново» (задача 032, п.7) — для `SKIPPED`/`FAILED`, когда
  /// контейнер был временно недоступен все 3 попытки или документ
  /// почему-то нечитаем; ставит новую задачу в очередь распознавания.
  Future<void> retryRecognition(String documentId) async {
    await _client.dio.post('/admin/verification-documents/$documentId/recognition/retry');
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
      if (readyDate != null) 'readyDate': ymd(readyDate),
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

  /// Спор об отмене (046 п.5): `resolution` — CANCEL/RESUME, `guilty` — DRIVER/COMPANY или null (без вины).
  Future<void> resolveDispute(String id, {required String resolution, String? guilty, required String reason}) async {
    await _client.dio.post('/admin/deals/$id/resolve-dispute', data: {
      'resolution': resolution,
      if (guilty != null) 'guilty': guilty,
      'reason': reason,
    });
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
    try {
      await _client.dio.patch('/admin/companies/$id/verify', data: {
        'isVerified': isVerified,
        'reason': reason,
        'force': force,
        if (crossChecks != null) 'crossChecks': crossChecks,
      });
    } on DioException catch (e) {
      throw _translateVerifyError(e);
    }
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
    try {
      await _client.dio.patch('/admin/drivers/$id/verify', data: {
        'isVerified': isVerified,
        'reason': reason,
        'force': force,
        if (crossChecks != null) 'crossChecks': crossChecks,
      });
    } on DioException catch (e) {
      throw _translateVerifyError(e);
    }
  }

  /// `BLACKLIST_MATCH` (см. [BlacklistMatchException]) — разворачиваем в
  /// типизированное исключение, чтобы экран мог показать находки, а не
  /// общее сообщение «не все документы одобрены»; всё остальное — как есть.
  Exception _translateVerifyError(DioException e) {
    final data = e.response?.data;
    if (e.response?.statusCode == 409 && data is Map<String, dynamic> && data['code'] == 'BLACKLIST_MATCH') {
      final blocks = (data['blocks'] as List<dynamic>? ?? []).map((b) => AdminBlacklistBlock.fromJson(b as Map<String, dynamic>)).toList();
      return BlacklistMatchException(blocks);
    }
    return e;
  }

  /// Общая панель редактирования (задача 028, п.18/19).
  /// Задача 032, п.6 — тягач и прицеп правятся раздельными группами полей
  /// (`tractorVehicle`/`trailerVehicle`), не одной общей `vehicle` — иначе
  /// легко перепутать местами, какая машина чья.
  Future<void> updateDriver(
    String id, {
    String? fullName,
    String? phone,
    String? homeCityId,
    bool? anyCountry,
    List<String>? countryIds,
    List<String>? permitIds,
    String? trailerBodyTypeId,
    double? trailerCapacityTons,
    double? trailerLengthM,
    String? tractorPlateNumber,
    String? tractorBrand,
    required String reason,
  }) async {
    final hasTrailerChange = trailerBodyTypeId != null || trailerCapacityTons != null || trailerLengthM != null;
    final hasTractorChange = tractorPlateNumber != null || tractorBrand != null;
    await _client.dio.patch('/admin/drivers/$id', data: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (homeCityId != null) 'homeCityId': homeCityId,
      if (anyCountry != null) 'anyCountry': anyCountry,
      if (countryIds != null) 'countryIds': countryIds,
      if (permitIds != null) 'permitIds': permitIds,
      if (hasTrailerChange)
        'trailerVehicle': {
          if (trailerBodyTypeId != null) 'bodyTypeId': trailerBodyTypeId,
          if (trailerCapacityTons != null) 'capacityTons': trailerCapacityTons,
          if (trailerLengthM != null) 'lengthM': trailerLengthM,
        },
      if (hasTractorChange)
        'tractorVehicle': {
          if (tractorPlateNumber != null) 'plateNumber': tractorPlateNumber,
          if (tractorBrand != null) 'brand': tractorBrand,
        },
      'reason': reason,
    });
  }

  /// `identifierTypes` — галочки «заблокировать также по…» (032 п.11 / 038):
  /// null — все подтверждённые идентификаторы, [] — только аккаунт.
  Future<void> blockUser(String userId, {required String reason, List<String>? identifierTypes}) async {
    await _client.dio.post('/admin/users/$userId/block', data: {
      'reason': reason,
      if (identifierTypes != null) 'identifierTypes': identifierTypes,
    });
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

  Future<LoadingPoint> createPoint(
    String cityId,
    I18nText name, {
    PointKind kind = PointKind.city,
    double? lat,
    double? lng,
    int? radiusM,
  }) async {
    final res = await _client.dio.post('/admin/reference/points', data: {
      'cityId': cityId,
      'name': name.toJson(),
      'kind': kind == PointKind.terminal ? 'TERMINAL' : 'CITY',
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusM != null) 'radiusM': radiusM,
    });
    return LoadingPoint.fromJson(res.data as Map<String, dynamic>);
  }

  /// Шаблоны размеров кузова (задача 033, п.11) — правятся без релиза.
  Future<void> createBodySizePreset({
    required String code,
    required I18nText name,
    List<String>? bodyTypeIds,
    double? innerLengthM,
    double? innerWidthM,
    double? innerHeightM,
    double? volumeM3,
    int? palletsEuro,
    int? palletsStandard,
  }) async {
    await _client.dio.post('/admin/reference/body-size-presets', data: {
      'code': code,
      'name': name.toJson(),
      if (bodyTypeIds != null) 'bodyTypeIds': bodyTypeIds,
      if (innerLengthM != null) 'innerLengthM': innerLengthM,
      if (innerWidthM != null) 'innerWidthM': innerWidthM,
      if (innerHeightM != null) 'innerHeightM': innerHeightM,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (palletsEuro != null) 'palletsEuro': palletsEuro,
      if (palletsStandard != null) 'palletsStandard': palletsStandard,
    });
  }

  Future<void> updateBodySizePreset(
    String id, {
    I18nText? name,
    List<String>? bodyTypeIds,
    double? innerLengthM,
    double? innerWidthM,
    double? innerHeightM,
    double? volumeM3,
    int? palletsEuro,
    int? palletsStandard,
    bool? isActive,
    int? sortOrder,
    required String reason,
  }) async {
    await _client.dio.patch('/admin/reference/body-size-presets/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (bodyTypeIds != null) 'bodyTypeIds': bodyTypeIds,
      if (innerLengthM != null) 'innerLengthM': innerLengthM,
      if (innerWidthM != null) 'innerWidthM': innerWidthM,
      if (innerHeightM != null) 'innerHeightM': innerHeightM,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (palletsEuro != null) 'palletsEuro': palletsEuro,
      if (palletsStandard != null) 'palletsStandard': palletsStandard,
      if (isActive != null) 'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'reason': reason,
    });
  }

  /// 048: профиль и поля типа кузова; ошибки структуры — 400 INVALID_BODY_FIELDS со списком.
  Future<void> updateBodyTypeProfile(String id, {required String profile, required List<dynamic> fields, required String reason}) async {
    await _client.dio.patch('/admin/reference/body-types/$id/profile', data: {'profile': profile, 'fields': fields, 'reason': reason});
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
  Future<void> updatePoint(
    String id, {
    I18nText? name,
    String? cityId,
    double? lat,
    double? lng,
    bool? isActive,
    PointKind? kind,
    int? radiusM,
    required String reason,
  }) async {
    await _client.dio.patch('/admin/reference/points/$id', data: {
      if (kind != null) 'kind': kind == PointKind.terminal ? 'TERMINAL' : 'CITY',
      if (radiusM != null) 'radiusM': radiusM,
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

/// Канал кода входа в админке: без ключей (`configured=false`) — серый.
class AdminLoginCodeChannel {
  const AdminLoginCodeChannel({required this.id, required this.enabled, required this.configured});

  final String id;
  final bool enabled;
  final bool configured;

  AdminLoginCodeChannel copyWith({bool? enabled}) => AdminLoginCodeChannel(id: id, enabled: enabled ?? this.enabled, configured: configured);
}

/// Запись чёрного списка (043 п.4): значение — только маской.
class AdminBlockedIdentifier {
  const AdminBlockedIdentifier({
    required this.id,
    required this.type,
    required this.valueMasked,
    required this.reason,
    required this.createdAt,
    this.blockedByName,
    this.liftedAt,
    this.liftReason,
  });

  final String id;
  final String type;
  final String valueMasked;
  final String reason;
  final DateTime createdAt;
  final String? blockedByName;
  final DateTime? liftedAt;
  final String? liftReason;

  factory AdminBlockedIdentifier.fromJson(Map<String, dynamic> json) => AdminBlockedIdentifier(
        id: json['id'] as String,
        type: json['type'] as String,
        valueMasked: json['valueMasked'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        blockedByName: json['blockedByName'] as String?,
        liftedAt: json['liftedAt'] == null ? null : DateTime.parse(json['liftedAt'] as String),
        liftReason: json['liftReason'] as String?,
      );
}
