import 'common.dart';

/// Координата с сервера: число, а на случай Prisma-Decimal — строка с числом.
double? _coordinate(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class Country {
  const Country({required this.id, required this.code, required this.name, required this.isCisMember});

  final String id;
  final String code;
  final I18nText name;
  final bool isCisMember;

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isCisMember: json['isCisMember'] as bool? ?? false,
      );
}

class City {
  const City({
    required this.id,
    required this.countryId,
    this.regionId,
    this.code,
    required this.name,
    required this.isCapital,
    this.cityStatus = CityStatus.approved,
    this.lat,
    this.lng,
  });

  final String id;
  final String countryId;
  final String? regionId;
  final String? code;
  final I18nText name;
  final bool isCapital;
  final CityStatus cityStatus;
  final double? lat;
  final double? lng;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        countryId: json['countryId'] as String,
        regionId: json['regionId'] as String?,
        code: json['code'] as String?,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isCapital: json['isCapital'] as bool? ?? false,
        cityStatus: cityStatusFromJson(json['cityStatus'] as String? ?? 'APPROVED'),
        lat: _coordinate(json['lat']),
        lng: _coordinate(json['lng']),
      );
}

class Region {
  const Region({required this.id, required this.countryId, required this.name, this.code});

  final String id;
  final String countryId;
  final I18nText name;
  final String? code;

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        id: json['id'] as String,
        countryId: json['countryId'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        code: json['code'] as String?,
      );
}

/// Объёмные кузова (тент, изотерм, реф) — только у них «м³ · пал.», шаблоны и
/// шаг «Размер кузова» (045 п.6). С 048 — по профилю типа кузова
/// ([BodyType.isVolume]); по коду — запасной путь для старых данных.
const _nonVolumeBodyCodes = {'FLATBED', 'CONTAINER', 'DUMP', 'LOWLOADER', 'CARCARRIER', 'GRAIN', 'TANK'};
bool isVolumeBodyType(String? code) => !_nonVolumeBodyCodes.contains(code);

/// Поле профиля кузова (048): что спрашивать у машины/груза и как проверять.
class BodyField {
  const BodyField({
    required this.key,
    required this.kind,
    required this.label,
    this.unit,
    this.forVehicle = false,
    this.forCargo = false,
    this.required = false,
    this.primary = false,
    this.min,
    this.max,
    this.options = const [],
  });

  final String key;
  /// number | enum | multi | bool
  final String kind;
  final I18nText label;
  final String? unit;
  final bool forVehicle;
  final bool forCargo;
  final bool required;
  final bool primary;
  final double? min;
  final double? max;
  final List<({String code, I18nText label})> options;

  factory BodyField.fromJson(Map<String, dynamic> json) => BodyField(
        key: json['key'] as String,
        kind: json['kind'] as String,
        label: I18nText.fromJson(json['label'] as Map<String, dynamic>? ?? const {}),
        unit: json['unit'] as String?,
        forVehicle: json['forVehicle'] as bool? ?? false,
        forCargo: json['forCargo'] as bool? ?? false,
        required: json['required'] as bool? ?? false,
        primary: json['primary'] as bool? ?? false,
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        options: [
          for (final o in json['options'] as List<dynamic>? ?? const [])
            (code: (o as Map<String, dynamic>)['code'] as String, label: I18nText.fromJson(o['label'] as Map<String, dynamic>? ?? const {})),
        ],
      );
}

class BodyType {
  const BodyType({
    required this.id,
    required this.code,
    required this.name,
    this.isActive = true,
    this.sortOrder = 0,
    this.profile = 'VOLUME',
    this.fields = const [],
    this.rawFields = const [],
  });

  final String id;
  final String code;
  final I18nText name;
  final bool isActive;
  final int sortOrder;

  /// 048: VOLUME | PLATFORM | CONTAINER | BULK | TANK | CAR_CARRIER.
  final String profile;
  final List<BodyField> fields;

  /// Поля как в справочнике (JSON) — для редактора в админке.
  final List<dynamic> rawFields;

  bool get isVolume => profile == 'VOLUME';
  List<BodyField> get vehicleFields => fields.where((f) => f.forVehicle).toList();
  List<BodyField> get cargoFields => fields.where((f) => f.forCargo).toList();
  List<BodyField> get primaryFields => fields.where((f) => f.forVehicle && f.primary).toList();
  bool get hasCapacity => fields.isEmpty || fields.any((f) => f.key == 'capacityTons');

  factory BodyType.fromJson(Map<String, dynamic> json) => BodyType(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
        profile: json['profile'] as String? ?? 'VOLUME',
        fields: [for (final f in json['fields'] as List<dynamic>? ?? const []) BodyField.fromJson(f as Map<String, dynamic>)],
        rawFields: json['fields'] as List<dynamic>? ?? const [],
      );
}

class Permit {
  const Permit({required this.id, required this.code, required this.name, this.isActive = true, this.sortOrder = 0});

  final String id;
  final String code;
  final I18nText name;
  final bool isActive;
  final int sortOrder;

  factory Permit.fromJson(Map<String, dynamic> json) => Permit(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

/// Вид точки погрузки (задача 040): обычный город или терминал с геозоной.
enum PointKind { city, terminal }

class LoadingPoint {
  const LoadingPoint({
    required this.id,
    required this.cityId,
    required this.name,
    required this.isActive,
    this.lat,
    this.lng,
    this.kind = PointKind.city,
    this.radiusM,
  });

  final String id;
  final String cityId;
  final I18nText name;
  final bool isActive;
  final double? lat;
  final double? lng;
  final PointKind kind;

  /// Радиус геозоны, м — только у терминала.
  final int? radiusM;

  factory LoadingPoint.fromJson(Map<String, dynamic> json) => LoadingPoint(
        id: json['id'] as String,
        cityId: json['cityId'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isActive: json['isActive'] as bool? ?? true,
        lat: _coordinate(json['lat']),
        lng: _coordinate(json['lng']),
        kind: json['kind'] == 'TERMINAL' ? PointKind.terminal : PointKind.city,
        radiusM: json['radiusM'] as int?,
      );
}

/// Шаблон размера кузова (задача 033) — выбирается одним касанием при
/// добавлении прицепа/одиночки вместо измерения рулеткой.
class BodySizePreset {
  const BodySizePreset({
    required this.id,
    required this.code,
    required this.name,
    this.bodyTypeIds = const [],
    this.innerLengthM,
    this.innerWidthM,
    this.innerHeightM,
    this.volumeM3,
    this.palletsEuro,
    this.palletsStandard,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String code;
  final I18nText name;
  final List<String> bodyTypeIds;
  final double? innerLengthM;
  final double? innerWidthM;
  final double? innerHeightM;
  final double? volumeM3;
  final int? palletsEuro;
  final int? palletsStandard;
  final int sortOrder;
  final bool isActive;

  factory BodySizePreset.fromJson(Map<String, dynamic> json) => BodySizePreset(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        bodyTypeIds: (json['bodyTypeIds'] as List<dynamic>? ?? []).cast<String>(),
        innerLengthM: (json['innerLengthM'] as num?)?.toDouble(),
        innerWidthM: (json['innerWidthM'] as num?)?.toDouble(),
        innerHeightM: (json['innerHeightM'] as num?)?.toDouble(),
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        palletsEuro: json['palletsEuro'] as int?,
        palletsStandard: json['palletsStandard'] as int?,
        sortOrder: json['sortOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );
}

class ExchangeRate {
  const ExchangeRate({required this.currency, required this.rateToKzt});

  final Currency currency;
  final double rateToKzt;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) => ExchangeRate(
        currency: currencyFromJson(json['currency'] as String),
        rateToKzt: (json['rateToKzt'] as num).toDouble(),
      );
}

/// Один пункт комбинированного автодополнения «страна + город».
/// [cityId] == null означает выбор всей страны без конкретного города.
class CountryCityOption {
  const CountryCityOption({required this.label, required this.countryId, this.cityId, this.isAddCityAction = false});

  final String label;
  final String countryId;
  final String? cityId;

  /// true — это не город, а синтетический пункт «Нет моего города»
  /// (последний в списке автодополнения, см. задачу 021).
  final bool isAddCityAction;
}

class ReferenceData {
  const ReferenceData({
    required this.countries,
    this.regions = const [],
    required this.cities,
    required this.bodyTypes,
    this.bodySizePresets = const [],
    required this.permits,
    required this.points,
    this.exchangeRates = const [],
    this.defaultPointCityId,
    this.supportWhatsapp,
    this.supportWechat,
    this.supportEmail,
  });

  final List<Country> countries;
  final List<Region> regions;
  final List<City> cities;
  final List<BodyType> bodyTypes;
  final List<BodySizePreset> bodySizePresets;
  final List<Permit> permits;
  final List<LoadingPoint> points;
  final List<ExchangeRate> exchangeRates;

  /// Точка загрузки по умолчанию (задача 015, `app_settings`) — пока
  /// активна только одна точка, выбор города не показываем, но id уже
  /// пробрасываем для будущего (задача 008 — несколько терминалов).
  final String? defaultPointCityId;

  /// Контакты поддержки (задача 025, `app_settings`) — запасной путь, если
  /// письмо с кодом сброса пароля не дошло (qq.com/163.com ненадёжны).
  /// `null`, пока админ не заполнил — экран поддержки тогда это не показывает.
  final String? supportWhatsapp;
  final String? supportWechat;
  final String? supportEmail;

  Country countryById(String id) => countries.firstWhere((c) => c.id == id, orElse: () => countries.first);
  City? cityById(String? id) => id == null ? null : cities.where((c) => c.id == id).firstOrNull;
  BodyType bodyTypeById(String id) => bodyTypes.firstWhere((b) => b.id == id, orElse: () => bodyTypes.first);
  /// Город погрузки по id; `null` — точку выключили в справочнике (не
  /// подставлять «первую попавшуюся», когда точек десятки — 040).
  LoadingPoint? pointOrNull(String id) => points.where((p) => p.id == id).firstOrNull;
  List<Region> regionsOf(String countryId) => regions.where((r) => r.countryId == countryId).toList();

  /// Активные шаблоны размера для типа кузова (задача 033) — шаблон с
  /// пустым bodyTypeIds подходит к любому типу.
  List<BodySizePreset> sizePresetsForBodyType(String? bodyTypeId) => bodySizePresets
      .where((p) => p.isActive && (p.bodyTypeIds.isEmpty || (bodyTypeId != null && p.bodyTypeIds.contains(bodyTypeId))))
      .toList();

  BodySizePreset? sizePresetById(String? id) => id == null ? null : bodySizePresets.where((p) => p.id == id).firstOrNull;

  /// Пересчёт суммы в тенге по последнему известному курсу. `null`, если
  /// курса для этой валюты ещё нет (тогда пересчёт просто не показываем).
  double? convertToKzt(double amount, Currency currency) {
    if (currency == Currency.kzt) return amount;
    final rate = exchangeRates.where((r) => r.currency == currency).firstOrNull;
    return rate == null ? null : amount * rate.rateToKzt;
  }

  /// Пересчёт в доллары через кросс-курс ₸ (для грузов в CNY/KZT).
  double? convertToUsd(double amount, Currency currency) {
    if (currency == Currency.usd) return amount;
    final kzt = convertToKzt(amount, currency);
    final usdRate = exchangeRates.where((r) => r.currency == Currency.usd).firstOrNull;
    if (kzt == null || usdRate == null || usdRate.rateToKzt == 0) return null;
    return kzt / usdRate.rateToKzt;
  }
  List<City> citiesOf(String countryId) => cities.where((c) => c.countryId == countryId).toList();

  /// Список для автодополнения «страна + город» в одном поле.
  /// Города показываются как «Город, Страна»; если [includeCountryOnly],
  /// в списке также будет пункт «Страна (вся страна)» без привязки к городу.
  List<CountryCityOption> countryCityOptions(String languageCode, {String wholeCountrySuffix = '', bool includeCountryOnly = true}) {
    final options = <CountryCityOption>[];
    for (final country in countries) {
      final countryName = country.name.forLanguageCode(languageCode);
      if (includeCountryOnly) {
        options.add(CountryCityOption(
          label: wholeCountrySuffix.isEmpty ? countryName : '$countryName ($wholeCountrySuffix)',
          countryId: country.id,
        ));
      }
      for (final city in citiesOf(country.id)) {
        options.add(CountryCityOption(
          label: '${city.name.forLanguageCode(languageCode)}, $countryName',
          countryId: country.id,
          cityId: city.id,
        ));
      }
    }
    return options;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
