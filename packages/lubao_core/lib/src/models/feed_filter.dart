import 'dart:convert';

import 'common.dart';

/// 059 п.3: сортировка ленты.
enum FeedSort { standard, priceAsc, priceDesc, perKm, ready, distanceAsc, distanceDesc, newest }

/// 059 п.2: дата погрузки.
enum FeedReady { any, today, threeDays, week }

const _sortCodes = {
  FeedSort.standard: 'default',
  FeedSort.priceAsc: 'price_asc',
  FeedSort.priceDesc: 'price_desc',
  FeedSort.perKm: 'per_km',
  FeedSort.ready: 'ready',
  FeedSort.distanceAsc: 'distance_asc',
  FeedSort.distanceDesc: 'distance_desc',
  FeedSort.newest: 'new',
};
const _readyCodes = {FeedReady.any: 'any', FeedReady.today: 'today', FeedReady.threeDays: '3d', FeedReady.week: 'week'};

/// 059: фильтр и сортировка ленты водителя. Запоминается на устройстве
/// (вместе с чипом «куда»; всё активное видно строкой над лентой с ✕).
class FeedFilter {
  const FeedFilter({
    this.fromCountryId,
    this.fromCityId,
    this.toCountryId,
    this.toCityId,
    this.toHome = false,
    this.bodyTypeIds = const [],
    this.weightMinT,
    this.weightMaxT,
    this.priceMin,
    this.priceMax,
    this.priceCurrency = Currency.usd,
    this.perKmMin,
    this.ready = FeedReady.any,
    this.withAdvance = false,
    this.sort = FeedSort.standard,
    this.showOtherCities = false,
  });

  static const empty = FeedFilter();

  final String? fromCountryId;
  final String? fromCityId;
  final String? toCountryId;
  final String? toCityId;
  final bool toHome;
  final List<String> bodyTypeIds;
  final double? weightMinT;
  final double? weightMaxT;
  final double? priceMin;
  final double? priceMax;
  final Currency priceCurrency;
  final int? perKmMin;
  final FeedReady ready;
  final bool withAdvance;
  final FeedSort sort;
  final bool showOtherCities;

  /// Фильтры шторки (без чипа «куда», сортировки и «других городов»).
  bool get hasSheetFilters =>
      fromCountryId != null || fromCityId != null || bodyTypeIds.isNotEmpty || weightMinT != null || weightMaxT != null || priceMin != null || priceMax != null || perKmMin != null || ready != FeedReady.any || withAdvance;

  bool get hasDestination => toHome || toCountryId != null || toCityId != null;

  FeedFilter copyWith({
    Object? fromCountryId = _keep,
    Object? fromCityId = _keep,
    Object? toCountryId = _keep,
    Object? toCityId = _keep,
    bool? toHome,
    List<String>? bodyTypeIds,
    Object? weightMinT = _keep,
    Object? weightMaxT = _keep,
    Object? priceMin = _keep,
    Object? priceMax = _keep,
    Currency? priceCurrency,
    Object? perKmMin = _keep,
    FeedReady? ready,
    bool? withAdvance,
    FeedSort? sort,
    bool? showOtherCities,
  }) =>
      FeedFilter(
        fromCountryId: fromCountryId == _keep ? this.fromCountryId : fromCountryId as String?,
        fromCityId: fromCityId == _keep ? this.fromCityId : fromCityId as String?,
        toCountryId: toCountryId == _keep ? this.toCountryId : toCountryId as String?,
        toCityId: toCityId == _keep ? this.toCityId : toCityId as String?,
        toHome: toHome ?? this.toHome,
        bodyTypeIds: bodyTypeIds ?? this.bodyTypeIds,
        weightMinT: weightMinT == _keep ? this.weightMinT : weightMinT as double?,
        weightMaxT: weightMaxT == _keep ? this.weightMaxT : weightMaxT as double?,
        priceMin: priceMin == _keep ? this.priceMin : priceMin as double?,
        priceMax: priceMax == _keep ? this.priceMax : priceMax as double?,
        priceCurrency: priceCurrency ?? this.priceCurrency,
        perKmMin: perKmMin == _keep ? this.perKmMin : perKmMin as int?,
        ready: ready ?? this.ready,
        withAdvance: withAdvance ?? this.withAdvance,
        sort: sort ?? this.sort,
        showOtherCities: showOtherCities ?? this.showOtherCities,
      );

  /// Чип «куда»: один выбор (страна, город или «домой»).
  FeedFilter withDestination({bool home = false, String? countryId, String? cityId}) =>
      copyWith(toHome: home, toCountryId: countryId, toCityId: cityId);

  /// «Сбросить» в шторке — всё, кроме чипа «куда» и сортировки.
  FeedFilter resetSheet() => FeedFilter(toHome: toHome, toCountryId: toCountryId, toCityId: toCityId, sort: sort, showOtherCities: showOtherCities);

  Map<String, dynamic> toQuery() => {
        if (fromCityId != null) 'fromCityId': fromCityId else if (fromCountryId != null) 'fromCountryId': fromCountryId,
        if (toHome) 'toHome': 'true',
        if (toCityId != null) 'toCityId': toCityId else if (toCountryId != null) 'toCountryId': toCountryId,
        if (bodyTypeIds.isNotEmpty) 'bodyTypeIds': bodyTypeIds.join(','),
        if (weightMinT != null) 'weightMinT': weightMinT,
        if (weightMaxT != null) 'weightMaxT': weightMaxT,
        if (priceMin != null) 'priceMin': priceMin,
        if (priceMax != null) 'priceMax': priceMax,
        if (priceMin != null || priceMax != null) 'priceCurrency': currencyToJson(priceCurrency),
        if (perKmMin != null) 'perKmMin': perKmMin,
        if (ready != FeedReady.any) 'ready': _readyCodes[ready],
        if (withAdvance) 'withAdvance': 'true',
        if (sort != FeedSort.standard) 'sort': _sortCodes[sort],
        if (showOtherCities) 'showOtherCities': 'true',
      };

  String toJsonString() => jsonEncode({
        'fromCountryId': fromCountryId,
        'fromCityId': fromCityId,
        'toCountryId': toCountryId,
        'toCityId': toCityId,
        'toHome': toHome,
        'bodyTypeIds': bodyTypeIds,
        'weightMinT': weightMinT,
        'weightMaxT': weightMaxT,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'priceCurrency': currencyToJson(priceCurrency),
        'perKmMin': perKmMin,
        'ready': ready.name,
        'withAdvance': withAdvance,
        'sort': sort.name,
      });

  static FeedFilter fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      double? d(Object? v) => (v as num?)?.toDouble();
      return FeedFilter(
        fromCountryId: j['fromCountryId'] as String?,
        fromCityId: j['fromCityId'] as String?,
        toCountryId: j['toCountryId'] as String?,
        toCityId: j['toCityId'] as String?,
        toHome: j['toHome'] as bool? ?? false,
        bodyTypeIds: (j['bodyTypeIds'] as List<dynamic>? ?? const []).cast<String>(),
        weightMinT: d(j['weightMinT']),
        weightMaxT: d(j['weightMaxT']),
        priceMin: d(j['priceMin']),
        priceMax: d(j['priceMax']),
        priceCurrency: currencyFromJson(j['priceCurrency'] as String? ?? 'USD'),
        perKmMin: (j['perKmMin'] as num?)?.toInt(),
        ready: FeedReady.values.where((e) => e.name == j['ready']).firstOrNull ?? FeedReady.any,
        withAdvance: j['withAdvance'] as bool? ?? false,
        sort: FeedSort.values.where((e) => e.name == j['sort']).firstOrNull ?? FeedSort.standard,
      );
    } catch (_) {
      return empty;
    }
  }
}

const _keep = Object();
