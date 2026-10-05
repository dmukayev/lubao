import 'common.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.phone,
    this.email,
    required this.locale,
    this.emailVerifiedAt,
  });

  final String id;
  final UserRole role;
  final String? phone;
  final String? email;
  final String locale;

  /// Подтверждение email не блокирует вход (задача 025, п. 7) — только
  /// показывает плашку-напоминание в кабинете.
  final DateTime? emailVerifiedAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        role: userRoleFromJson(json['role'] as String),
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        locale: json['locale'] as String? ?? 'ru',
        emailVerifiedAt: json['emailVerifiedAt'] == null ? null : DateTime.parse(json['emailVerifiedAt'] as String),
      );
}

class CompanyInviteInfo {
  const CompanyInviteInfo({required this.companyName, required this.role, required this.email});

  final String companyName;
  final CompanyMemberRole role;
  final String email;

  factory CompanyInviteInfo.fromJson(Map<String, dynamic> json) => CompanyInviteInfo(
        companyName: json['companyName'] as String,
        role: companyMemberRoleFromJson(json['role'] as String),
        email: json['email'] as String,
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

/// Запись гаража (задача 031, этап B, макет 26) — тягач или прицеп по
/// отдельности, со своей проверкой. Не путать с [Vehicle] — старой
/// объединённой формой, которую `Driver.vehicle` отдаёт для обратной
/// совместимости, пока эту модель использует только экран «Мой гараж».
class GarageVehicle {
  const GarageVehicle({
    required this.id,
    required this.kind,
    this.bodyTypeId,
    this.plateNumber,
    this.vin,
    this.brand,
    this.capacityTons,
    this.lengthM,
    this.sizePresetId,
    this.innerLengthM,
    this.innerWidthM,
    this.innerHeightM,
    this.volumeM3,
    this.palletsEuro,
    required this.isOwner,
    required this.isVerified,
    required this.isArchived,
    required this.createdAt,
  });

  final String id;
  final VehicleKind kind;
  final String? bodyTypeId;
  final String? plateNumber;
  final String? vin;
  final String? brand;
  final double? capacityTons;
  final double? lengthM;
  /// Размер кузова (задача 033) — шаблон или «свой размер».
  final String? sizePresetId;
  final double? innerLengthM;
  final double? innerWidthM;
  final double? innerHeightM;
  final double? volumeM3;
  final int? palletsEuro;
  final bool isOwner;
  final bool isVerified;
  final bool isArchived;
  final DateTime createdAt;

  factory GarageVehicle.fromJson(Map<String, dynamic> json) => GarageVehicle(
        id: json['id'] as String,
        kind: vehicleKindFromJson(json['kind'] as String),
        bodyTypeId: json['bodyTypeId'] as String?,
        plateNumber: json['plateNumber'] as String?,
        vin: json['vin'] as String?,
        brand: json['brand'] as String?,
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        lengthM: (json['lengthM'] as num?)?.toDouble(),
        sizePresetId: json['sizePresetId'] as String?,
        innerLengthM: (json['innerLengthM'] as num?)?.toDouble(),
        innerWidthM: (json['innerWidthM'] as num?)?.toDouble(),
        innerHeightM: (json['innerHeightM'] as num?)?.toDouble(),
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        palletsEuro: json['palletsEuro'] as int?,
        isOwner: json['isOwner'] as bool? ?? true,
        isVerified: json['isVerified'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
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
    this.nameRu,
    required this.countryId,
    this.city,
    this.legalAddress,
    this.taxId,
    required this.isVerified,
    this.wecomWebhookUrl,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String name;
  final String? nameRu;
  final String countryId;
  final String? city;
  final String? legalAddress;
  /// Рег. номер — 统一社会信用代码 (КНР) или БИН (Казахстан), задача 012.
  final String? taxId;
  final bool isVerified;
  /// Вебхук группового бота WeCom (задача 011, п.2) — заполняет владелец в
  /// профиле компании.
  final String? wecomWebhookUrl;
  final double ratingAvg;
  final int ratingCount;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as String,
        name: json['name'] as String,
        nameRu: json['nameRu'] as String?,
        countryId: json['countryId'] as String,
        city: json['city'] as String?,
        legalAddress: json['legalAddress'] as String?,
        taxId: json['taxId'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        wecomWebhookUrl: json['wecomWebhookUrl'] as String?,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
      );
}

class CompanyMember {
  const CompanyMember({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    this.fullName,
    this.contactPhone,
    this.wechatId,
  });

  final String id;
  final String companyId;
  final String userId;
  final CompanyMemberRole role;
  /// «Мой профиль» (задача 012) — водитель видит это, не общий телефон
  /// компании. null, пока сотрудник не заполнил профиль.
  final String? fullName;
  final String? contactPhone;
  final String? wechatId;

  factory CompanyMember.fromJson(Map<String, dynamic> json) => CompanyMember(
        id: json['id'] as String,
        companyId: json['companyId'] as String,
        userId: json['userId'] as String,
        role: companyMemberRoleFromJson(json['role'] as String),
        fullName: json['fullName'] as String?,
        contactPhone: json['contactPhone'] as String?,
        wechatId: json['wechatId'] as String?,
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

  Session copyWith({AppUser? user, Driver? driver, Company? company, CompanyMember? companyMember}) => Session(
        user: user ?? this.user,
        driver: driver ?? this.driver,
        company: company ?? this.company,
        companyMember: companyMember ?? this.companyMember,
      );
}
