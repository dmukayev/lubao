import '../api/api_client.dart';
import '../models/arrival.dart';

class ArrivalRepository {
  ArrivalRepository(this._client);

  final ApiClient _client;

  Future<Arrival?> mine() async {
    final res = await _client.dio.get('/arrivals/me');
    // Бэкенд всегда отдаёт объект-обёртку `{ arrival: ... | null }` (задача
    // 027) — но на пустое тело без Content-Type (старые/прокси-ответы)
    // Dio кладёт в res.data пустую строку, а не null, так что проверка типа
    // всё равно нужна как защита от этого случая.
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final arrival = data['arrival'];
    return arrival is Map<String, dynamic> ? Arrival.fromJson(arrival) : null;
  }

  Future<ArrivalTemplate?> lastTemplate() async {
    final res = await _client.dio.get('/arrivals/last-template');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final template = data['template'];
    return template is Map<String, dynamic> ? ArrivalTemplate.fromJson(template) : null;
  }

  /// Анонс «буду на точке» (задача 015) — дата/время прибытия, точка,
  /// страны на эту поездку, срок ожидания.
  Future<Arrival> announce({
    required String pointId,
    required DateTime plannedAt,
    bool anyCountry = false,
    List<String> countryIds = const [],
    int waitDays = 2,
  }) async {
    final res = await _client.dio.post('/arrivals', data: {
      'pointId': pointId,
      'plannedAt': plannedAt.toUtc().toIso8601String(),
      'anyCountry': anyCountry,
      'countryIds': countryIds,
      'waitDays': waitDays,
    });
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Arrival> repeat() async {
    final res = await _client.dio.post('/arrivals/repeat');
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Arrival> checkIn() async {
    final res = await _client.dio.post('/arrivals/checkin');
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancel() async {
    await _client.dio.post('/arrivals/cancel');
  }

  Future<List<ArrivalListing>> listForCompany({
    DateTime? date,
    String? pointId,
    String? countryId,
    String? bodyTypeId,
    double? minCapacityTons,
    bool verifiedOnly = false,
  }) async {
    final res = await _client.dio.get('/arrivals', queryParameters: {
      if (date != null) 'date': date.toUtc().toIso8601String(),
      if (pointId != null) 'pointId': pointId,
      if (countryId != null) 'countryId': countryId,
      if (bodyTypeId != null) 'bodyTypeId': bodyTypeId,
      if (minCapacityTons != null) 'minCapacityTons': minCapacityTons.toString(),
      if (verifiedOnly) 'verifiedOnly': 'true',
    });
    return (res.data as List<dynamic>).map((e) => ArrivalListing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ArrivalSummaryDay>> summary({int days = 7, String? pointId}) async {
    final res = await _client.dio.get('/arrivals/summary', queryParameters: {
      'days': days.toString(),
      if (pointId != null) 'pointId': pointId,
    });
    return (res.data as List<dynamic>).map((e) => ArrivalSummaryDay.fromJson(e as Map<String, dynamic>)).toList();
  }
}
