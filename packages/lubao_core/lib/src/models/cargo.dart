import '../utils/date_only.dart';
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
    this.palletCount,
    this.photoUrls = const [],
    required this.price,
    required this.currency,
    required this.readyDate,
    this.description,
    required this.status,
    required this.publishedAt,
    required this.expiresAt,
    this.contactUserId,
    this.contactName,
    this.hasContactPhone = false,
    this.contactWechatId,
    this.isWhatsappBlocked = false,
    this.closeOutcome,
    this.closedAt,
    this.allowPartial = false,
    this.pickupRank,
    this.feedSection,
    this.myResponseStatus,
    this.responsesCount = 0,
    this.activeDeal,
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

  /// Паллеты (задача 033) — вместо/вместе с объёмом.
  final int? palletCount;
  final List<String> photoUrls;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String? description;
  final CargoStatus status;
  final DateTime publishedAt;
  final DateTime expiresAt;

  /// Конкретный логист, опубликовавший груз (decisions.md «Компания:
  /// проверка, роли, контакты», задача 012) — водитель звонит/пишет ему,
  /// не «компании».
  final String? contactUserId;
  final String? contactName;
  /// Номер логиста не приходит в карточке (043 п.11) — только по нажатию
  /// «Позвонить»/WhatsApp через `CargoRepository.revealContact`.
  final bool hasContactPhone;
  final String? contactWechatId;

  /// WhatsApp заблокирован в Китае — показываем чат Lubao вместо кнопки,
  /// которая всё равно не дойдёт (задача 017, п.5в).
  final bool isWhatsappBlocked;
  final String? closeOutcome;
  final DateTime? closedAt;

  /// «Можно догрузом» (040, п.6) — груз не на всю машину.
  final bool allowPartial;

  /// Только в ленте водителя: 0 — грузится в городе водителя, 1 — в той же
  /// области или ≤200 км, 2 — остальные (сервер считает, 040 п.5).
  final int? pickupRank;
  final CargoFeedSection? feedSection;

  /// Лента водителя (045 п.2): его отклик на этот груз и сколько других
  /// водителей уже откликнулись.
  final ResponseStatus? myResponseStatus;
  final int responsesCount;

  /// Список грузов логиста (044 п.3): сделка по грузу — водитель и статус.
  final CargoActiveDeal? activeDeal;

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
        palletCount: json['palletCount'] as int?,
        photoUrls: (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        price: (json['price'] as num).toDouble(),
        currency: currencyFromJson(json['currency'] as String),
        readyDate: DateTime.parse(json['readyDate'] as String),
        description: json['description'] as String?,
        status: cargoStatusFromJson(json['status'] as String),
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        contactUserId: json['contactUserId'] as String?,
        contactName: json['contactName'] as String?,
        hasContactPhone: json['hasContactPhone'] as bool? ?? false,
        contactWechatId: json['contactWechatId'] as String?,
        isWhatsappBlocked: json['isWhatsappBlocked'] as bool? ?? false,
        closeOutcome: json['closeOutcome'] as String?,
        closedAt: json['closedAt'] == null ? null : DateTime.parse(json['closedAt'] as String),
        allowPartial: json['allowPartial'] as bool? ?? false,
        pickupRank: json['pickupRank'] as int?,
        myResponseStatus: json['myResponseStatus'] == null ? null : responseStatusFromJson(json['myResponseStatus'] as String),
        responsesCount: json['responsesCount'] as int? ?? 0,
        activeDeal: json['activeDeal'] == null ? null : CargoActiveDeal.fromJson(json['activeDeal'] as Map<String, dynamic>),
        feedSection: switch (json['feedSection']) {
          'home' => CargoFeedSection.home,
          'selected' => CargoFeedSection.selected,
          'other' => CargoFeedSection.other,
          _ => null,
        },
      );
}

/// Страница ленты водителя (040): порядок и отсев — на сервере.
class CargoFeedPage {
  const CargoFeedPage({required this.items, required this.total, required this.offset, this.originCityId});

  final List<Cargo> items;
  final int total;
  final int offset;

  /// Город, от которого сервер считал «рядом» (город анонса или домашний).
  final String? originCityId;

  bool get hasMore => offset + items.length < total;

  factory CargoFeedPage.fromJson(Map<String, dynamic> json) => CargoFeedPage(
        items: (json['items'] as List<dynamic>).map((e) => Cargo.fromJson(e as Map<String, dynamic>)).toList(),
        total: json['total'] as int? ?? 0,
        offset: json['offset'] as int? ?? 0,
        originCityId: json['originCityId'] as String?,
      );
}

/// Подсказка «Помещается к текущему: 8 т + 10 т из 20 т» (040, п.6).
class PartialHint {
  const PartialHint({required this.fits, this.reason, required this.committedWeightKg, this.cargoWeightKg, this.capacityKg});

  final bool fits;

  /// `NEXT_TRIP` — другое окно дат, `FULL` — не помещается.
  final String? reason;
  final double committedWeightKg;
  final double? cargoWeightKg;
  final double? capacityKg;

  factory PartialHint.fromJson(Map<String, dynamic> json) => PartialHint(
        fits: json['fits'] as bool? ?? false,
        reason: json['reason'] as String?,
        committedWeightKg: (json['committedWeightKg'] as num?)?.toDouble() ?? 0,
        cargoWeightKg: (json['cargoWeightKg'] as num?)?.toDouble(),
        capacityKg: (json['capacityKg'] as num?)?.toDouble(),
      );
}

/// Кандидат на «Нашёл в Lubao» при закрытии груза (задача 017, п.6).
class CargoCloseCandidate {
  const CargoCloseCandidate({required this.driverId, required this.driverName});

  final String driverId;
  final String driverName;

  factory CargoCloseCandidate.fromJson(Map<String, dynamic> json) =>
      CargoCloseCandidate(driverId: json['driverId'] as String, driverName: json['driverName'] as String);
}

class CreateCargoInput {
  const CreateCargoInput({
    required this.pointId,
    this.allowPartial = false,
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    this.weightKg,
    this.volumeM3,
    this.palletCount,
    this.photoUrls = const [],
    required this.price,
    required this.currency,
    required this.readyDate,
    this.description,
  });

  /// Город погрузки — обязателен (040, п.7).
  final String pointId;
  final bool allowPartial;
  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final double? weightKg;
  final double? volumeM3;
  final int? palletCount;
  final List<String> photoUrls;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String? description;

  Map<String, dynamic> toJson() => {
        'pointId': pointId,
        'allowPartial': allowPartial,
        'destinationCountryId': destinationCountryId,
        if (destinationCityId != null) 'destinationCityId': destinationCityId,
        'bodyTypeId': bodyTypeId,
        if (weightKg != null) 'weightKg': weightKg,
        if (volumeM3 != null) 'volumeM3': volumeM3,
        if (palletCount != null) 'palletCount': palletCount,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'price': price,
        'currency': currencyToJson(currency),
        'readyDate': ymd(readyDate),
        if (description != null) 'description': description,
      };
}

/// Секции ленты внутри одного «города погрузки»: домой → выбранные страны
/// → остальное (порядок считает сервер).
enum CargoFeedSection { home, selected, other }

class CargoActiveDeal {
  const CargoActiveDeal({required this.id, required this.status, required this.driverName});
  final String id;
  final DealStatus status;
  final String driverName;

  factory CargoActiveDeal.fromJson(Map<String, dynamic> json) =>
      CargoActiveDeal(id: json['id'] as String, status: dealStatusFromJson(json['status'] as String), driverName: json['driverName'] as String);
}

