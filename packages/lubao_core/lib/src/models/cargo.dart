import 'common.dart';

class Cargo {
  const Cargo({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyIsVerified = false,
    this.companyRatingAvg = 0,
    this.companyRatingCount = 0,
    this.companyCompletedDeals = 0,
    required this.pointId,
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    this.weightKg,
    this.volumeM3,
    this.photoUrls = const [],
    required this.price,
    required this.currency,
    required this.readyDate,
    this.description,
    required this.status,
    required this.publishedAt,
    required this.expiresAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final bool companyIsVerified;
  final double companyRatingAvg;
  final int companyRatingCount;
  final int companyCompletedDeals;
  final String pointId;
  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final double? weightKg;
  final double? volumeM3;
  final List<String> photoUrls;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String? description;
  final CargoStatus status;
  final DateTime publishedAt;
  final DateTime expiresAt;

  factory Cargo.fromJson(Map<String, dynamic> json) => Cargo(
        id: json['id'] as String,
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String? ?? '',
        companyIsVerified: json['companyIsVerified'] as bool? ?? false,
        companyRatingAvg: (json['companyRatingAvg'] as num?)?.toDouble() ?? 0,
        companyRatingCount: json['companyRatingCount'] as int? ?? 0,
        companyCompletedDeals: json['companyCompletedDeals'] as int? ?? 0,
        pointId: json['pointId'] as String,
        destinationCountryId: json['destinationCountryId'] as String,
        destinationCityId: json['destinationCityId'] as String?,
        bodyTypeId: json['bodyTypeId'] as String,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        price: (json['price'] as num).toDouble(),
        currency: currencyFromJson(json['currency'] as String),
        readyDate: DateTime.parse(json['readyDate'] as String),
        description: json['description'] as String?,
        status: cargoStatusFromJson(json['status'] as String),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

}

class CreateCargoInput {
  const CreateCargoInput({
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    this.weightKg,
    this.volumeM3,
    this.photoUrls = const [],
    required this.price,
    required this.currency,
    required this.readyDate,
    this.description,
  });

  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final double? weightKg;
  final double? volumeM3;
  final List<String> photoUrls;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String? description;

  Map<String, dynamic> toJson() => {
        'destinationCountryId': destinationCountryId,
        if (destinationCityId != null) 'destinationCityId': destinationCityId,
        'bodyTypeId': bodyTypeId,
        if (weightKg != null) 'weightKg': weightKg,
        if (volumeM3 != null) 'volumeM3': volumeM3,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'price': price,
        'currency': currencyToJson(currency),
        'readyDate': readyDate.toIso8601String(),
        if (description != null) 'description': description,
      };
}

/// Три сортировочные секции ленты: домой -> выбранные страны -> остальное.
enum CargoFeedSection { home, selected, other }

class CargoFeedItem {
  const CargoFeedItem({required this.cargo, required this.section});

  final Cargo cargo;
  final CargoFeedSection section;
}

List<CargoFeedItem> sortCargoFeed({
  required List<Cargo> cargos,
  required String? driverHomeCountryId,
  required Set<String> driverDirectionCountryIds,
  required bool anyCountry,
}) {
  CargoFeedSection sectionFor(Cargo c) {
    if (driverHomeCountryId != null && c.destinationCountryId == driverHomeCountryId) {
      return CargoFeedSection.home;
    }
    if (anyCountry || driverDirectionCountryIds.contains(c.destinationCountryId)) {
      return CargoFeedSection.selected;
    }
    return CargoFeedSection.other;
  }

  final items = cargos.map((c) => CargoFeedItem(cargo: c, section: sectionFor(c))).toList();
  items.sort((a, b) => a.section.index.compareTo(b.section.index));
  return items;
}
