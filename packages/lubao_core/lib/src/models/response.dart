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
  });

  final String id;
  final String cargoId;
  final String driverId;
  final String driverName;
  final String? message;
  final ResponseStatus status;
  final DateTime createdAt;

  factory CargoResponse.fromJson(Map<String, dynamic> json) => CargoResponse(
        id: json['id'] as String,
        cargoId: json['cargoId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        message: json['message'] as String?,
        status: responseStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
