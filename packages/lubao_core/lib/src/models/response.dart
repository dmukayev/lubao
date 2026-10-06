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
    this.committedWeightKg = 0,
    this.activeDealsCount = 0,
    this.committedHasUnknownWeight = false,
    this.committedDestinationCountryId,
    this.committedDestinationCityId,
    this.committedReadyDate,
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
  final double committedWeightKg;
  final int activeDealsCount;
  final bool committedHasUnknownWeight;
  final String? committedDestinationCountryId;
  final String? committedDestinationCityId;
  final DateTime? committedReadyDate;

  factory CargoResponse.fromJson(Map<String, dynamic> json) => CargoResponse(
        id: json['id'] as String,
        cargoId: json['cargoId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        message: json['message'] as String?,
        status: responseStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        committedWeightKg: (json['committedWeightKg'] as num?)?.toDouble() ?? 0,
        activeDealsCount: json['activeDealsCount'] as int? ?? 0,
        committedHasUnknownWeight: json['committedHasUnknownWeight'] as bool? ?? false,
        committedDestinationCountryId: json['committedDestinationCountryId'] as String?,
        committedDestinationCityId: json['committedDestinationCityId'] as String?,
        committedReadyDate: json['committedReadyDate'] == null ? null : DateTime.parse(json['committedReadyDate'] as String),
      );
}
