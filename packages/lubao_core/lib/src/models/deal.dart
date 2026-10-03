import 'common.dart';
import 'cargo.dart';

class Deal {
  const Deal({
    required this.id,
    required this.responseId,
    required this.cargoId,
    required this.driverId,
    required this.driverName,
    required this.companyId,
    required this.companyName,
    required this.status,
    this.cancelReason,
    this.cancelledByRole,
    this.confirmedAt,
    this.loadedAt,
    this.inTransitAt,
    this.deliveredAt,
    required this.createdAt,
    this.cargo,
    this.driverLocation,
  });

  final String id;
  final String responseId;
  final String cargoId;
  final String driverId;
  final String driverName;
  final String companyId;
  final String companyName;
  final DealStatus status;
  final String? cancelReason;
  final UserRole? cancelledByRole;
  final DateTime? confirmedAt;
  final DateTime? loadedAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final Cargo? cargo;
  final DriverLocation? driverLocation;

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
        id: json['id'] as String,
        responseId: json['responseId'] as String,
        cargoId: json['cargoId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String? ?? '',
        status: dealStatusFromJson(json['status'] as String),
        cancelReason: json['cancelReason'] as String?,
        cancelledByRole: json['cancelledByRole'] == null ? null : userRoleFromJson(json['cancelledByRole'] as String),
        confirmedAt: json['confirmedAt'] == null ? null : DateTime.parse(json['confirmedAt'] as String),
        loadedAt: json['loadedAt'] == null ? null : DateTime.parse(json['loadedAt'] as String),
        inTransitAt: json['inTransitAt'] == null ? null : DateTime.parse(json['inTransitAt'] as String),
        deliveredAt: json['deliveredAt'] == null ? null : DateTime.parse(json['deliveredAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        cargo: json['cargo'] == null ? null : Cargo.fromJson(json['cargo'] as Map<String, dynamic>),
        driverLocation: json['driverLocation'] == null
            ? null
            : DriverLocation.fromJson(json['driverLocation'] as Map<String, dynamic>),
      );

  static const List<DealStatus> driverProgression = [
    DealStatus.selected,
    DealStatus.confirmedByDriver,
    DealStatus.loaded,
    DealStatus.inTransit,
    DealStatus.delivered,
  ];

  DealStatus? get nextStatus {
    final idx = driverProgression.indexOf(status);
    if (idx < 0 || idx + 1 >= driverProgression.length) return null;
    return driverProgression[idx + 1];
  }

  bool get isCancellable => status != DealStatus.delivered && status != DealStatus.cancelled;
}
