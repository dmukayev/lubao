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
    this.cancelReasonCode,
    this.cancelledByRole,
    this.confirmedAt,
    this.loadedAt,
    this.inTransitAt,
    this.deliveredAt,
    required this.createdAt,
    this.cargo,
    this.driverLocation,
    this.vehiclesVerified = true,
    this.driverDocsOpenedAt,
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

  /// Код причины отмены (038, п.15) — для статистики, текст остаётся в cancelReason.
  final String? cancelReasonCode;
  final UserRole? cancelledByRole;
  final DateTime? confirmedAt;
  final DateTime? loadedAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final Cargo? cargo;
  final DriverLocation? driverLocation;

  /// 044 п.5: машины рейса проверены; нет — плашка «Машина ещё на проверке».
  final bool vehiclesVerified;

  /// 044 п.4: когда логист последний раз открыл документы водителя.
  final DateTime? driverDocsOpenedAt;

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
        cancelReasonCode: json['cancelReasonCode'] as String?,
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
        vehiclesVerified: json['vehiclesVerified'] as bool? ?? true,
        driverDocsOpenedAt: json['driverDocsOpenedAt'] == null ? null : DateTime.parse(json['driverDocsOpenedAt'] as String),
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

/// Документ в пакете водителя (044 п.1): id для превью и статус проверки.
class DriverDocRef {
  const DriverDocRef({required this.id, required this.status});
  final String id;
  final String status;

  static DriverDocRef? fromJson(dynamic json) =>
      json == null ? null : DriverDocRef(id: (json as Map<String, dynamic>)['id'] as String, status: json['status'] as String);
}

class DriverDocsVehicle {
  const DriverDocsVehicle({required this.id, required this.kind, this.plateNumber, this.vin, this.brand, required this.isVerified, this.passport, this.photoFront, this.photoSide});
  final String id;
  final VehicleKind kind;
  final String? plateNumber;
  final String? vin;
  final String? brand;
  final bool isVerified;
  final DriverDocRef? passport;
  final DriverDocRef? photoFront;
  final DriverDocRef? photoSide;

  factory DriverDocsVehicle.fromJson(Map<String, dynamic> json) => DriverDocsVehicle(
        id: json['id'] as String,
        kind: vehicleKindFromJson(json['kind'] as String),
        plateNumber: json['plateNumber'] as String?,
        vin: json['vin'] as String?,
        brand: json['brand'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        passport: DriverDocRef.fromJson(json['passport']),
        photoFront: DriverDocRef.fromJson(json['photoFront']),
        photoSide: DriverDocRef.fromJson(json['photoSide']),
      );
}

/// Пакет документов водителя логисту по обоюдной сделке (044 п.1).
class DriverDocumentsPackage {
  const DriverDocumentsPackage({
    required this.dealId,
    required this.fullName,
    this.iin,
    this.selfie,
    this.licenseNumber,
    this.licenseExpiry,
    this.license,
    required this.vehicles,
  });
  final String dealId;
  final String fullName;
  final String? iin;
  final DriverDocRef? selfie;
  final String? licenseNumber;
  final String? licenseExpiry;
  final DriverDocRef? license;
  final List<DriverDocsVehicle> vehicles;

  factory DriverDocumentsPackage.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>;
    final license = json['license'] as Map<String, dynamic>? ?? const {};
    return DriverDocumentsPackage(
      dealId: json['dealId'] as String,
      fullName: driver['fullName'] as String,
      iin: driver['iin'] as String?,
      selfie: DriverDocRef.fromJson(json['selfie']),
      licenseNumber: license['number'] as String?,
      licenseExpiry: license['expiryDate'] as String?,
      license: DriverDocRef.fromJson(license['document']),
      vehicles: [for (final v in json['vehicles'] as List<dynamic>? ?? const []) DriverDocsVehicle.fromJson(v as Map<String, dynamic>)],
    );
  }
}

/// Кто и когда открывал документы (044 п.4) — водителю.
class DriverDocsAccess {
  const DriverDocsAccess({required this.at, required this.downloaded, this.by});
  final DateTime at;
  final bool downloaded;
  final String? by;

  factory DriverDocsAccess.fromJson(Map<String, dynamic> json) => DriverDocsAccess(
        at: DateTime.parse(json['at'] as String),
        downloaded: json['action'] == 'DRIVER_DOCS_DOWNLOADED',
        by: json['by'] as String?,
      );
}

