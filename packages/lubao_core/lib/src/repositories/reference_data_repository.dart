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
      regions: (data['regions'] as List<dynamic>?)
              ?.map((e) => Region.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cities: (data['cities'] as List<dynamic>).map((e) => City.fromJson(e as Map<String, dynamic>)).toList(),
      bodyTypes:
          (data['bodyTypes'] as List<dynamic>).map((e) => BodyType.fromJson(e as Map<String, dynamic>)).toList(),
      bodySizePresets: (data['bodySizePresets'] as List<dynamic>?)
              ?.map((e) => BodySizePreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      permits: (data['permits'] as List<dynamic>).map((e) => Permit.fromJson(e as Map<String, dynamic>)).toList(),
      points:
          (data['points'] as List<dynamic>).map((e) => LoadingPoint.fromJson(e as Map<String, dynamic>)).toList(),
      exchangeRates: (data['exchangeRates'] as List<dynamic>?)
              ?.map((e) => ExchangeRate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultPointCityId: data['defaultPointCityId'] as String?,
      supportWhatsapp: data['supportWhatsapp'] as String?,
      supportWechat: data['supportWechat'] as String?,
      supportEmail: data['supportEmail'] as String?,
    );
  }

  /// Город не нашёлся в справочнике — отправляем свободный текст + область,
  /// регистрация продолжается сразу с новым City (status=PENDING, см. 021).
  Future<City> submitCity({required String settlementName, required String regionId}) async {
    final res = await _client.dio
        .post('/reference-data/cities', data: {'settlementName': settlementName, 'regionId': regionId});
    return City.fromJson(res.data as Map<String, dynamic>);
  }

  /// Минимальная версия приложения из админки (043 п.8); `null` — не требуем.
  Future<String?> minAppVersion() async {
    final res = await _client.dio.get('/app/min-version');
    return (res.data as Map<String, dynamic>)['minAppVersion'] as String?;
  }
}
