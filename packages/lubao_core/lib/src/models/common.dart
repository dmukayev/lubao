class I18nText {
  const I18nText({required this.kk, required this.ru, required this.zh});

  final String kk;
  final String ru;
  final String zh;

  factory I18nText.fromJson(Map<String, dynamic> json) => I18nText(
        kk: json['kk'] as String? ?? '',
        ru: json['ru'] as String? ?? '',
        zh: json['zh'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'kk': kk, 'ru': ru, 'zh': zh};

  String forLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'kk':
        return kk;
      case 'zh':
        return zh;
      case 'ru':
      default:
        return ru;
    }
  }
}

class DriverLocation {
  const DriverLocation({required this.lat, required this.lng, required this.updatedAt});

  final double lat;
  final double lng;
  final DateTime updatedAt;

  factory DriverLocation.fromJson(Map<String, dynamic> json) => DriverLocation(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

enum UserRole { driver, company, admin }

UserRole userRoleFromJson(String value) => UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.driver,
    );

enum CompanyMemberRole { owner, logist }

CompanyMemberRole companyMemberRoleFromJson(String value) => CompanyMemberRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => CompanyMemberRole.logist,
    );

enum Currency { usd, cny, kzt }

Currency currencyFromJson(String value) => Currency.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => Currency.usd,
    );

String currencyToJson(Currency currency) => currency.name.toUpperCase();

String currencySymbol(Currency currency) {
  switch (currency) {
    case Currency.usd:
      return '\$';
    case Currency.cny:
      return '¥';
    case Currency.kzt:
      return '₸';
  }
}

enum CargoStatus { published, archived, expired, cancelled }

CargoStatus cargoStatusFromJson(String value) => CargoStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => CargoStatus.published,
    );

enum ResponseStatus { pending, selected, rejected, cancelled }

ResponseStatus responseStatusFromJson(String value) => ResponseStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => ResponseStatus.pending,
    );

/// NONE — документы не загружены, PENDING — загружены, ждут проверки
/// админом, APPROVED — все обязательные документы одобрены.
enum DriverVerificationStatus { none, pending, approved }

DriverVerificationStatus driverVerificationStatusFromJson(String? value) => DriverVerificationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value?.toUpperCase(),
      orElse: () => DriverVerificationStatus.none,
    );

enum VerificationDocType { selfie, vehiclePassport, trailerPassport, driverLicense }

const _verificationDocTypeJson = {
  VerificationDocType.selfie: 'SELFIE',
  VerificationDocType.vehiclePassport: 'VEHICLE_PASSPORT',
  VerificationDocType.trailerPassport: 'TRAILER_PASSPORT',
  VerificationDocType.driverLicense: 'DRIVER_LICENSE',
};

VerificationDocType verificationDocTypeFromJson(String value) => _verificationDocTypeJson.entries
    .firstWhere((e) => e.value == value, orElse: () => _verificationDocTypeJson.entries.first)
    .key;

String verificationDocTypeToJson(VerificationDocType type) => _verificationDocTypeJson[type]!;

enum VerificationDocStatus { pending, approved, rejected }

VerificationDocStatus verificationDocStatusFromJson(String value) => VerificationDocStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => VerificationDocStatus.pending,
    );

enum DealStatus { selected, confirmedByDriver, loaded, inTransit, delivered, cancelled }

DealStatus dealStatusFromJson(String value) {
  switch (value.toUpperCase()) {
    case 'SELECTED':
      return DealStatus.selected;
    case 'CONFIRMED_BY_DRIVER':
      return DealStatus.confirmedByDriver;
    case 'LOADED':
      return DealStatus.loaded;
    case 'IN_TRANSIT':
      return DealStatus.inTransit;
    case 'DELIVERED':
      return DealStatus.delivered;
    case 'CANCELLED':
      return DealStatus.cancelled;
    default:
      return DealStatus.selected;
  }
}

String dealStatusToJson(DealStatus status) {
  switch (status) {
    case DealStatus.selected:
      return 'SELECTED';
    case DealStatus.confirmedByDriver:
      return 'CONFIRMED_BY_DRIVER';
    case DealStatus.loaded:
      return 'LOADED';
    case DealStatus.inTransit:
      return 'IN_TRANSIT';
    case DealStatus.delivered:
      return 'DELIVERED';
    case DealStatus.cancelled:
      return 'CANCELLED';
  }
}

enum ContactEventType { call, whatsapp }

String contactEventTypeToJson(ContactEventType type) => type.name.toUpperCase();
