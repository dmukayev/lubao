import 'common.dart';

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
  });

  final String id;
  final String countryId;
  final String? regionId;
  final String? code;
  final I18nText name;
  final bool isCapital;
  final CityStatus cityStatus;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        countryId: json['countryId'] as String,
        regionId: json['regionId'] as String?,
        code: json['code'] as String?,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
        isCapital: json['isCapital'] as bool? ?? false,
        cityStatus: cityStatusFromJson(json['cityStatus'] as String? ?? 'APPROVED'),
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

class BodyType {
  const BodyType({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final I18nText name;

  factory BodyType.fromJson(Map<String, dynamic> json) => BodyType(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
      );
}

class Permit {
  const Permit({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final I18nText name;

  factory Permit.fromJson(Map<String, dynamic> json) => Permit(
        id: json['id'] as String,
        code: json['code'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
      );
}

class LoadingPoint {
  const LoadingPoint({required this.id, required this.name, required this.isActive});

  final String id;
  final I18nText name;
  final bool isActive;

  factory LoadingPoint.fromJson(Map<String, dynamic> json) => LoadingPoint(
        id: json['id'] as String,
        name: I18nText.fromJson(json['name'] as Map<String, dynamic>),
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
    required this.permits,
    required this.points,
    this.exchangeRates = const [],
    this.defaultPointCityId,
  });

  final List<Country> countries;
  final List<Region> regions;
  final List<City> cities;
  final List<BodyType> bodyTypes;
  final List<Permit> permits;
  final List<LoadingPoint> points;
  final List<ExchangeRate> exchangeRates;

  /// Точка загрузки по умолчанию (задача 015, `app_settings`) — пока
  /// активна только одна точка, выбор города не показываем, но id уже
  /// пробрасываем для будущего (задача 008 — несколько терминалов).
  final String? defaultPointCityId;

  Country countryById(String id) => countries.firstWhere((c) => c.id == id, orElse: () => countries.first);
  City? cityById(String? id) => id == null ? null : cities.where((c) => c.id == id).firstOrNull;
  BodyType bodyTypeById(String id) => bodyTypes.firstWhere((b) => b.id == id, orElse: () => bodyTypes.first);
  LoadingPoint pointById(String id) => points.firstWhere((p) => p.id == id, orElse: () => points.first);
  List<Region> regionsOf(String countryId) => regions.where((r) => r.countryId == countryId).toList();

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
