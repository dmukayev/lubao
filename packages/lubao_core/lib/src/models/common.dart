class I18nText {
  const I18nText({required this.kk, required this.ru, required this.zh, this.en = ''});

  final String kk;
  final String ru;
  final String zh;

  /// Английский — с задачи 013 полноценная локаль интерфейса.
  /// `forLanguageCode('en')` отдаёт `en`, если он заполнен в справочнике,
  /// иначе падает в `ru` (нет перевода → решение 2026-10-04, п. «Языки»).
  final String en;

  factory I18nText.fromJson(Map<String, dynamic> json) => I18nText(
        kk: json['kk'] as String? ?? '',
        ru: json['ru'] as String? ?? '',
        zh: json['zh'] as String? ?? '',
        en: json['en'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'kk': kk, 'ru': ru, 'zh': zh, if (en.isNotEmpty) 'en': en};

  String forLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'kk':
        return kk;
      case 'zh':
        return zh;
      case 'en':
        return en.isNotEmpty ? en : ru;
      case 'ru':
      default:
        return ru;
    }
  }

  /// Все непустые варианты названия (kk/ru/zh/en) — для поиска без
  /// привязки к языку интерфейса (задача 021).
  Iterable<String> get allVariants => [kk, ru, zh, en].where((s) => s.isNotEmpty);
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

/// 058 п.4: + RUB, UZS (рейсы в Россию и Узбекистан).
enum Currency { usd, cny, kzt, rub, uzs }

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
    case Currency.rub:
      return '₽';
    case Currency.uzs:
      return 'сум';
  }
}

String _groupDigits(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// Цена везде одинаково: «$10 300», «¥7 000», «₸850 000», «1 250 000 ₽»,
/// «95 000 000 сум» (058 п.4: рубль и сум — знаком после суммы).
String formatCurrencyAmount(double amount, Currency currency) {
  final n = _groupDigits(amount.round());
  return switch (currency) {
    Currency.rub || Currency.uzs => '$n ${currencySymbol(currency)}',
    _ => '${currencySymbol(currency)}$n',
  };
}

/// 058 п.1: форма оплаты груза.
enum PaymentForm { cash, card, cashless }

PaymentForm? paymentFormFromJson(String? value) =>
    value == null ? null : PaymentForm.values.where((e) => e.name.toUpperCase() == value.toUpperCase()).firstOrNull;

/// 058 п.8а: тип компании — метка.
enum CompanyKind { shipper, forwarder, carrier }

CompanyKind companyKindFromJson(String? value) =>
    CompanyKind.values.where((e) => e.name.toUpperCase() == value?.toUpperCase()).firstOrNull ?? CompanyKind.forwarder;

/// Эмодзи-флаг по коду страны («KZ» → 🇰🇿); не код — пусто.
String flagEmoji(String? code) {
  if (code == null || !RegExp(r'^[A-Za-z]{2}$').hasMatch(code)) return '';
  return String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 65));
}

enum CargoStatus { published, inDeal, archived, expired, cancelled }

/// Сравнение без «_»: серверное IN_DEAL ↔ клиентское inDeal.
String _enumKey(String value) => value.replaceAll('_', '').toUpperCase();

CargoStatus cargoStatusFromJson(String value) => CargoStatus.values.firstWhere(
      (e) => _enumKey(e.name) == _enumKey(value),
      orElse: () => CargoStatus.published,
    );

/// `invited` — логист пригласил, водитель ещё не согласился (задача 041).
enum ResponseStatus { invited, pending, selected, rejected, cancelled }

ResponseStatus responseStatusFromJson(String value) => ResponseStatus.values.firstWhere(
      (e) => _enumKey(e.name) == _enumKey(value),
      orElse: () => ResponseStatus.pending,
    );

/// NONE — документы не загружены, PENDING — загружены, ждут проверки
/// админом, APPROVED — все обязательные документы одобрены.
enum DriverVerificationStatus { none, pending, approved }

DriverVerificationStatus driverVerificationStatusFromJson(String? value) => DriverVerificationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value?.toUpperCase(),
      orElse: () => DriverVerificationStatus.none,
    );

enum VerificationDocType { selfie, vehiclePassport, trailerPassport, driverLicense, companyRegistration, vehiclePhotoFront, vehiclePhotoSide }

const _verificationDocTypeJson = {
  VerificationDocType.selfie: 'SELFIE',
  VerificationDocType.vehiclePassport: 'VEHICLE_PASSPORT',
  VerificationDocType.trailerPassport: 'TRAILER_PASSPORT',
  VerificationDocType.driverLicense: 'DRIVER_LICENSE',
  /// Единственный документ, подтверждающий компанию (задача 012, п.5).
  VerificationDocType.companyRegistration: 'COMPANY_REGISTRATION',
  /// Фото машины спереди с госномером и сбоку (044 п.7) — не проверяются.
  VerificationDocType.vehiclePhotoFront: 'VEHICLE_PHOTO_FRONT',
  VerificationDocType.vehiclePhotoSide: 'VEHICLE_PHOTO_SIDE',
};

VerificationDocType verificationDocTypeFromJson(String value) => _verificationDocTypeJson.entries
    .firstWhere((e) => e.value == value, orElse: () => _verificationDocTypeJson.entries.first)
    .key;

String verificationDocTypeToJson(VerificationDocType type) => _verificationDocTypeJson[type]!;

/// Гараж водителя (задача 031, этап A/B) — тягач, прицеп или одиночка
/// (кузов на шасси, без отдельного прицепа).
enum VehicleKind { tractor, trailer, rigid }

VehicleKind vehicleKindFromJson(String value) => VehicleKind.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => VehicleKind.rigid,
    );

String vehicleKindToJson(VehicleKind kind) => kind.name.toUpperCase();

enum VerificationDocStatus { pending, approved, rejected }

VerificationDocStatus verificationDocStatusFromJson(String value) => VerificationDocStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => VerificationDocStatus.pending,
    );

/// 046: `cancelRequested` — после «В пути» одна сторона просит отмену и
/// ждёт ответа второй; `disputed` — вторая оспорила, решает админ.
enum DealStatus { selected, confirmedByDriver, loaded, inTransit, delivered, cancelled, cancelRequested, disputed }

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
    case 'CANCEL_REQUESTED':
      return DealStatus.cancelRequested;
    case 'DISPUTED':
      return DealStatus.disputed;
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
    case DealStatus.cancelRequested:
      return 'CANCEL_REQUESTED';
    case DealStatus.disputed:
      return 'DISPUTED';
  }
}

/// PENDING — предложен водителем/логистом через «Нет моего города» и ждёт
/// модерации админом; APPROVED — в справочнике официально; REJECTED —
/// админ отклонил (но запись не удаляется, пока на неё кто-то ссылается).
enum CityStatus { pending, approved, rejected }

CityStatus cityStatusFromJson(String value) => CityStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => CityStatus.approved,
    );

enum ContactEventType { call, whatsapp }

String contactEventTypeToJson(ContactEventType type) => type.name.toUpperCase();

/// Причины отмены сделки (046 п.1) — коды API; тексты в ARB.
const cancelReasonCodes = [
  'VEHICLE_BREAKDOWN',
  'CARGO_NOT_READY',
  'OTHER_PARTY_UNRESPONSIVE',
  'TERMS_CHANGED',
  'TOOK_OTHER_CARGO',
  'OTHER',
];

/// «Отменил 1 из 15 · после загрузки 1» (046 п.3).
class CancelStats {
  const CancelStats({this.total = 0, this.cancelled = 0, this.afterLoad = 0, this.selfFault = 0});
  final int total;
  final int cancelled;
  final int afterLoad;
  final int selfFault;

  static CancelStats? fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return CancelStats(
      total: json['total'] as int? ?? 0,
      cancelled: json['cancelled'] as int? ?? 0,
      afterLoad: json['afterLoad'] as int? ?? 0,
      selfFault: json['selfFault'] as int? ?? 0,
    );
  }
}
