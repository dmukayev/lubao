import 'common.dart';

class CargoResponse {
  const CargoResponse({
    required this.id,
    required this.cargoId,
    required this.driverId,
    required this.driverName,
    this.message,
    required this.status,
    required this.createdAt,
    this.capacityTons,
    this.bodyTypeId,
    this.volumeM3,
    this.palletsEuro,
    this.committedWeightKg = 0,
    this.activeDealsCount = 0,
    this.committedHasUnknownWeight = false,
    this.committedDestinationCountryId,
    this.committedDestinationCityId,
    this.committedReadyDate,
    this.dealId,
    this.dealStatus,
  });

  final String id;
  final String cargoId;
  final String driverId;
  final String driverName;
  final String? message;
  final ResponseStatus status;
  final DateTime createdAt;

  /// «Уже везёт…» (задача 038, п.8/9) — сводка активных сделок водителя по
  /// его текущей связке; логист видит занятость до выбора, клиент мягко
  /// предупреждает, если груз не помещается.
  final double? capacityTons;

  /// Кузов связки (или из регистрации) — миниатюра у логиста (045 п.4).
  final String? bodyTypeId;

  /// Объём/паллеты связки водителя (033 п.9 / 038 п.14).
  final double? volumeM3;
  final int? palletsEuro;
  final double committedWeightKg;
  final int activeDealsCount;
  final bool committedHasUnknownWeight;
  final String? committedDestinationCountryId;
  final String? committedDestinationCityId;
  final DateTime? committedReadyDate;

  /// Сделка по этому отклику (если выбран) — статус и переход в неё.
  final String? dealId;
  final DealStatus? dealStatus;

  factory CargoResponse.fromJson(Map<String, dynamic> json) => CargoResponse(
        id: json['id'] as String,
        cargoId: json['cargoId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        message: json['message'] as String?,
        status: responseStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        bodyTypeId: json['bodyTypeId'] as String?,
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        palletsEuro: json['palletsEuro'] as int?,
        committedWeightKg: (json['committedWeightKg'] as num?)?.toDouble() ?? 0,
        activeDealsCount: json['activeDealsCount'] as int? ?? 0,
        committedHasUnknownWeight: json['committedHasUnknownWeight'] as bool? ?? false,
        committedDestinationCountryId: json['committedDestinationCountryId'] as String?,
        committedDestinationCityId: json['committedDestinationCityId'] as String?,
        committedReadyDate: json['committedReadyDate'] == null ? null : DateTime.parse(json['committedReadyDate'] as String),
        dealId: json['dealId'] as String?,
        dealStatus: json['dealStatus'] == null ? null : dealStatusFromJson(json['dealStatus'] as String),
      );
}


/// Мой отклик на груз (041) — для карточки водителя.
class MyCargoResponse {
  const MyCargoResponse({required this.id, required this.status});

  final String id;
  final ResponseStatus status;

  factory MyCargoResponse.fromJson(Map<String, dynamic> json) =>
      MyCargoResponse(id: json['id'] as String, status: responseStatusFromJson(json['status'] as String));
}


/// Строка «Моих откликов» (041, п.9): статус отклика + краткая сводка груза.
class MyResponseEntry {
  const MyResponseEntry({
    required this.id,
    required this.cargoId,
    required this.status,
    required this.cargoStatus,
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    required this.price,
    required this.currency,
    required this.readyDate,
  });

  final String id;
  final String cargoId;
  final ResponseStatus status;
  final CargoStatus cargoStatus;
  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final double price;
  final Currency currency;
  final DateTime readyDate;

  factory MyResponseEntry.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>;
    return MyResponseEntry(
      id: json['id'] as String,
      cargoId: json['cargoId'] as String,
      status: responseStatusFromJson(json['status'] as String),
      cargoStatus: cargoStatusFromJson(cargo['status'] as String),
      destinationCountryId: cargo['destinationCountryId'] as String,
      destinationCityId: cargo['destinationCityId'] as String?,
      bodyTypeId: cargo['bodyTypeId'] as String,
      price: (cargo['price'] as num).toDouble(),
      currency: currencyFromJson(cargo['currency'] as String),
      readyDate: DateTime.parse(cargo['readyDate'] as String),
    );
  }
}
