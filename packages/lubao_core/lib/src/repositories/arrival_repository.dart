import '../api/api_client.dart';
import '../models/arrival.dart';

class ArrivalRepository {
  ArrivalRepository(this._client);

  final ApiClient _client;

  Future<Arrival?> mine() async {
    final res = await _client.dio.get('/arrivals/me');
    return res.data == null ? null : Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Arrival> checkIn() async {
    final res = await _client.dio.post('/arrivals/checkin');
    return Arrival.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> leave() async {
    await _client.dio.post('/arrivals/leave');
  }

  Future<List<ArrivalListing>> listForCompany({
    String? countryId,
    String? bodyTypeId,
    double? minCapacityTons,
    bool verifiedOnly = false,
  }) async {
    final res = await _client.dio.get('/arrivals', queryParameters: {
      if (countryId != null) 'countryId': countryId,
      if (bodyTypeId != null) 'bodyTypeId': bodyTypeId,
      if (minCapacityTons != null) 'minCapacityTons': minCapacityTons.toString(),
      if (verifiedOnly) 'verifiedOnly': 'true',
    });
    return (res.data as List<dynamic>).map((e) => ArrivalListing.fromJson(e as Map<String, dynamic>)).toList();
  }
}
