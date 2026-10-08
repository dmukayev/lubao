import '../api/api_client.dart';
import '../models/admin.dart';
import '../models/common.dart';
import '../models/user.dart';

class DriverSetupInput {
  const DriverSetupInput({
    required this.fullName,
    required this.homeCityId,
    required this.anyCountry,
    required this.directionCountryIds,
    required this.permitIds,
    this.directionRegionIds = const [],
    this.bodyTypeId,
    this.plateNumber,
    this.capacityTons,
  });

  final String fullName;
  final String homeCityId;
  final bool anyCountry;
  final List<String> directionCountryIds;
  final List<String> permitIds;

  /// Области внутри выбранных стран (045 п.7); у страны без областей — вся страна.
  final List<String> directionRegionIds;

  /// Кузов и тоннаж — предпочтение из регистрации (045 п.5), машины — в гараже.
  final String? bodyTypeId;
  final String? plateNumber;
  final double? capacityTons;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'homeCityId': homeCityId,
        'anyCountry': anyCountry,
        'directionCountryIds': directionCountryIds,
        'permitIds': permitIds,
        'directionRegionIds': directionRegionIds,
        if (bodyTypeId != null) 'bodyTypeId': bodyTypeId,
        if (plateNumber != null) 'plateNumber': plateNumber,
        if (capacityTons != null) 'capacityTons': capacityTons,
      };
}

class DriverRepository {
  DriverRepository(this._client);

  final ApiClient _client;

  Future<Driver> me() async {
    final res = await _client.dio.get('/drivers/me');
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Driver> updateProfile(DriverSetupInput input) async {
    final res = await _client.dio.patch('/drivers/me', data: input.toJson());
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Да, это я» — ФИО из одобренных прав в профиль (045 п.10).
  Future<Driver> acceptLicenseName() async {
    final res = await _client.dio.post('/drivers/me/accept-license-name');
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateLocation({required double lat, required double lng}) async {
    await _client.dio.patch('/drivers/me/location', data: {'lat': lat, 'lng': lng});
  }

  Future<List<VerificationDocument>> verificationDocuments() async {
    final res = await _client.dio.get('/drivers/me/verification-documents');
    return (res.data as List<dynamic>).map((e) => VerificationDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VerificationDocument> submitVerificationDocument({
    required VerificationDocType type,
    required String fileUrl,
    String? vehicleId,
  }) async {
    final res = await _client.dio.post('/drivers/me/verification-documents', data: {
      'type': verificationDocTypeToJson(type),
      'fileUrl': fileUrl,
      if (vehicleId != null) 'vehicleId': vehicleId,
    });
    return VerificationDocument.fromJson(res.data as Map<String, dynamic>);
  }

  /// Блок «Распознано» под документом на проверке (задача 031, п.25,
  /// макет 22) — только значения/уверенность, без сверки с чёрным списком
  /// (это знание админа о других владельцах, не для самопроверки).
  /// Переиспользует модель админки — поля match/engineVersion/durationMs
  /// просто остаются null, бэкенд их для этого эндпоинта не присылает.
  Future<AdminDocumentRecognition> documentRecognition(String documentId) async {
    final res = await _client.dio.get('/drivers/me/verification-documents/$documentId/recognition');
    return AdminDocumentRecognition.fromJson(res.data as Map<String, dynamic>);
  }

  // -- Гараж (задача 031, этап B, макет 26) --------------------------------

  Future<List<GarageVehicle>> vehicles() async {
    final res = await _client.dio.get('/drivers/me/vehicles');
    return (res.data as List<dynamic>).map((e) => GarageVehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GarageVehicle> addVehicle({
    required VehicleKind kind,
    String? bodyTypeId,
    String? plateNumber,
    String? vin,
    String? brand,
    double? capacityTons,
    double? lengthM,
    String? sizePresetId,
    double? innerLengthM,
    double? innerWidthM,
    double? innerHeightM,
    String? documentFileUrl,
  }) async {
    final res = await _client.dio.post('/drivers/me/vehicles', data: {
      'kind': vehicleKindToJson(kind),
      // 032 п.12 (038) — техпаспорт в том же запросе: машина и документ
      // создаются на сервере одной транзакцией.
      if (documentFileUrl != null) 'documentFileUrl': documentFileUrl,
      if (bodyTypeId != null) 'bodyTypeId': bodyTypeId,
      if (plateNumber != null) 'plateNumber': plateNumber,
      if (vin != null) 'vin': vin,
      if (brand != null) 'brand': brand,
      if (capacityTons != null) 'capacityTons': capacityTons,
      if (lengthM != null) 'lengthM': lengthM,
      if (sizePresetId != null) 'sizePresetId': sizePresetId,
      if (innerLengthM != null) 'innerLengthM': innerLengthM,
      if (innerWidthM != null) 'innerWidthM': innerWidthM,
      if (innerHeightM != null) 'innerHeightM': innerHeightM,
    });
    return GarageVehicle.fromJson(res.data as Map<String, dynamic>);
  }

  /// Размер кузова существующей машины (задача 033, п.5) — шаблон ИЛИ
  /// «свой размер» (все три габарита); сервер копирует/считает сам.
  Future<GarageVehicle> setVehicleSize(
    String id, {
    String? sizePresetId,
    double? innerLengthM,
    double? innerWidthM,
    double? innerHeightM,
  }) async {
    final res = await _client.dio.patch('/drivers/me/vehicles/$id/size', data: {
      if (sizePresetId != null) 'sizePresetId': sizePresetId,
      if (innerLengthM != null) 'innerLengthM': innerLengthM,
      if (innerWidthM != null) 'innerWidthM': innerWidthM,
      if (innerHeightM != null) 'innerHeightM': innerHeightM,
    });
    return GarageVehicle.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> archiveVehicle(String id) async {
    await _client.dio.post('/drivers/me/vehicles/$id/archive');
  }
}
