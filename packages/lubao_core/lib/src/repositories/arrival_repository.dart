import '../api/api_client.dart';
import '../models/arrival.dart';
import '../utils/date_only.dart';

class ArrivalRepository {
  ArrivalRepository(this._client);

  final ApiClient _client;

  /// Мои активные анонсы (040: их может быть несколько).
  Future<MyArrivals> mine() async {
    final res = await _client.dio.get('/arrivals/me');
    // Бэкенд всегда отдаёт объект-обёртку `{ arrival: ... | null, arrivals: [...] }`
    // (задача 027) — но на пустое тело без Content-Type (старые/прокси-ответы)
    // Dio кладёт в res.data пустую строку, а не null, так что проверка типа
    // всё равно нужна как защита от этого случая.
    final data = res.data;
    if (data is! Map<String, dynamic>) return const MyArrivals(current: null, all: []);
    final arrival = data['arrival'];
    final all = (data['arrivals'] as List<dynamic>?)?.map((e) => Arrival.fromJson(e as Map<String, dynamic>)).toList() ?? const <Arrival>[];
    return MyArrivals(current: arrival is Map<String, dynamic> ? Arrival.fromJson(arrival) : null, all: all);
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
    String? arrivalId,
    required String pointId,
    required DateTime plannedAt,
    bool anyCountry = false,
    List<String> countryIds = const [],
    int waitDays = 2,
    String? tractorId,
    String? trailerId,
  }) async {
    final res = await _client.dio.post('/arrivals', data: {
      if (arrivalId != null) 'arrivalId': arrivalId,
      'pointId': pointId,
      'plannedAt': plannedAt.toUtc().toIso8601String(),
      // День — календарная дата как её выбрал водитель, без часового пояса.
      'plannedDay': ymd(plannedAt),
      'anyCountry': anyCountry,
      'countryIds': countryIds,
      'waitDays': waitDays,
      if (tractorId != null) 'tractorId': tractorId,
      if (trailerId != null) 'trailerId': trailerId,
    });
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Arrival> repeat() async {
    // Календарный «сегодня» — по часам устройства водителя (041, п.13).
    final res = await _client.dio.post('/arrivals/repeat', data: {'today': ymd(DateTime.now())});
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Я на месте» — для конкретного анонса; без `arrivalId` сервер берёт
  /// ближайший на сегодня.
  Future<Arrival> checkIn({String? arrivalId, String? pointId}) async {
    final res = await _client.dio.post('/arrivals/checkin', data: {
      'today': ymd(DateTime.now()),
      if (arrivalId != null) 'arrivalId': arrivalId,
      if (pointId != null) 'pointId': pointId,
    });
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Да, ещё ищу груз» на вопрос «Ещё ищете груз?» (правило свежести, 040).
  Future<Arrival> stillLooking({String? arrivalId}) async {
    final res = await _client.dio.post('/arrivals/still-looking', data: {if (arrivalId != null) 'arrivalId': arrivalId});
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> cancel({String? arrivalId}) async {
    await _client.dio.post('/arrivals/cancel', data: {if (arrivalId != null) 'arrivalId': arrivalId});
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
      if (date != null) 'date': ymd(date),
      'today': ymd(DateTime.now()),
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
      'from': ymd(DateTime.now()),
      if (pointId != null) 'pointId': pointId,
    });
    return (res.data as List<dynamic>).map((e) => ArrivalSummaryDay.fromJson(e as Map<String, dynamic>)).toList();
  }
}
