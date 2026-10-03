import '../api/api_client.dart';
import '../models/reference_data.dart';

class ReferenceDataRepository {
  ReferenceDataRepository(this._client);

  final ApiClient _client;

  Future<ReferenceData> fetch() async {
    final res = await _client.dio.get('/reference-data');
    final data = res.data as Map<String, dynamic>;
    return ReferenceData(
      countries: (data['countries'] as List<dynamic>)
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList(),
      cities: (data['cities'] as List<dynamic>).map((e) => City.fromJson(e as Map<String, dynamic>)).toList(),
      bodyTypes:
          (data['bodyTypes'] as List<dynamic>).map((e) => BodyType.fromJson(e as Map<String, dynamic>)).toList(),
      permits: (data['permits'] as List<dynamic>).map((e) => Permit.fromJson(e as Map<String, dynamic>)).toList(),
      points:
          (data['points'] as List<dynamic>).map((e) => LoadingPoint.fromJson(e as Map<String, dynamic>)).toList(),
      exchangeRates: (data['exchangeRates'] as List<dynamic>?)
              ?.map((e) => ExchangeRate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
