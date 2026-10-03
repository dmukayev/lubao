/// Строка списка «Кто будет на Хоргосе» — водитель, сейчас находящийся на
/// активной точке, со стороны логиста.
class ArrivalListing {
  const ArrivalListing({
    required this.arrivalId,
    required this.driverId,
    required this.driverName,
    this.phone,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
    required this.arrivedAt,
    this.bodyTypeId,
    this.capacityTons,
    required this.anyCountry,
    required this.directionCountryIds,
  });

  final String arrivalId;
  final String driverId;
  final String driverName;
  final String? phone;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;
  final DateTime arrivedAt;
  final String? bodyTypeId;
  final double? capacityTons;
  final bool anyCountry;
  final List<String> directionCountryIds;

  factory ArrivalListing.fromJson(Map<String, dynamic> json) => ArrivalListing(
        arrivalId: json['arrivalId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        phone: json['phone'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        arrivedAt: DateTime.parse(json['arrivedAt'] as String),
        bodyTypeId: json['bodyTypeId'] as String?,
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        anyCountry: json['anyCountry'] as bool? ?? false,
        directionCountryIds:
            (json['directionCountryIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}

class Arrival {
  const Arrival({
    required this.id,
    required this.pointId,
    required this.arrivedAt,
    this.expectedDepartureAt,
    required this.status,
    required this.logistsCount,
  });

  final String id;
  final String pointId;
  final DateTime arrivedAt;
  final DateTime? expectedDepartureAt;
  final String status;
  final int logistsCount;

  factory Arrival.fromJson(Map<String, dynamic> json) => Arrival(
        id: json['id'] as String,
        pointId: json['pointId'] as String,
        arrivedAt: DateTime.parse(json['arrivedAt'] as String),
        expectedDepartureAt:
            json['expectedDepartureAt'] == null ? null : DateTime.parse(json['expectedDepartureAt'] as String),
        status: json['status'] as String,
        logistsCount: json['logistsCount'] as int? ?? 0,
      );
}
