import 'common.dart';

class AppUser {
  const AppUser({required this.id, required this.role, this.phone, this.email, required this.locale});

  final String id;
  final UserRole role;
  final String? phone;
  final String? email;
  final String locale;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: userRoleFromJson(json['role'] as String),
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        locale: json['locale'] as String? ?? 'ru',
      );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.bodyTypeId,
    this.plateNumber,
    this.brand,
    this.capacityTons,
  });

  final String id;
  final String bodyTypeId;
  final String? plateNumber;
  final String? brand;
  final double? capacityTons;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        bodyTypeId: json['bodyTypeId'] as String,
        plateNumber: json['plateNumber'] as String?,
        brand: json['brand'] as String?,
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
      );
}

class VerificationDocument {
  const VerificationDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectReason,
    required this.createdAt,
  });

  final String id;
  final VerificationDocType type;
  final String fileUrl;
  final VerificationDocStatus status;
  final String? rejectReason;
  final DateTime createdAt;

  factory VerificationDocument.fromJson(Map<String, dynamic> json) => VerificationDocument(
        id: json['id'] as String,
        type: verificationDocTypeFromJson(json['type'] as String),
        fileUrl: json['fileUrl'] as String,
        status: verificationDocStatusFromJson(json['status'] as String),
        rejectReason: json['rejectReason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Driver {
  const Driver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.homeCityId,
    required this.anyCountry,
    required this.isVerified,
    this.verificationStatus = DriverVerificationStatus.none,
    required this.ratingAvg,
    required this.ratingCount,
    required this.directionCountryIds,
    required this.permitIds,
    this.vehicle,
    this.location,
  });

  final String id;
  final String userId;
  final String fullName;
  final String homeCityId;
  final bool anyCountry;
  final bool isVerified;
  final DriverVerificationStatus verificationStatus;
  final double ratingAvg;
  final int ratingCount;
  final List<String> directionCountryIds;
  final List<String> permitIds;
  final Vehicle? vehicle;
  final DriverLocation? location;

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        userId: json['userId'] as String,
        fullName: json['fullName'] as String,
        homeCityId: json['homeCityId'] as String,
        anyCountry: json['anyCountry'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        verificationStatus: driverVerificationStatusFromJson(json['verificationStatus'] as String?),
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        directionCountryIds: (json['directionCountryIds'] as List<dynamic>? ?? []).cast<String>(),
        permitIds: (json['permitIds'] as List<dynamic>? ?? []).cast<String>(),
        vehicle: json['vehicle'] == null ? null : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
        location: json['location'] == null ? null : DriverLocation.fromJson(json['location'] as Map<String, dynamic>),
      );
}

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.countryId,
    this.city,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String name;
  final String countryId;
  final String? city;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        countryId: json['countryId'] as String,
        city: json['city'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
      );
}

class CompanyMember {
  const CompanyMember({required this.id, required this.companyId, required this.userId, required this.role});

  final String id;
  final String companyId;
  final String userId;
  final CompanyMemberRole role;

  factory CompanyMember.fromJson(Map<String, dynamic> json) => CompanyMember(
        id: json['id'] as String,
        companyId: json['companyId'] as String,
        userId: json['userId'] as String,
        role: companyMemberRoleFromJson(json['role'] as String),
      );
}

class Session {
  const Session({required this.user, this.driver, this.company, this.companyMember});

  final AppUser user;
  final Driver? driver;
  final Company? company;
  final CompanyMember? companyMember;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        driver: json['driver'] == null ? null : Driver.fromJson(json['driver'] as Map<String, dynamic>),
        company: json['company'] == null ? null : Company.fromJson(json['company'] as Map<String, dynamic>),
        companyMember: json['companyMember'] == null
            ? null
            : CompanyMember.fromJson(json['companyMember'] as Map<String, dynamic>),
      );

  Session copyWith({Driver? driver}) =>
      Session(user: user, driver: driver ?? this.driver, company: company, companyMember: companyMember);
}
