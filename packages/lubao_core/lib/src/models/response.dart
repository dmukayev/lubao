import 'common.dart';

/// 058 п.5: ответ водителя на встречную цену логиста.
enum CounterStatus { pending, accepted, declined }

/// 058 п.5: торг по отклику — своя цена водителя (в валюте груза) с
/// комментарием и один встречный ход логиста.
class ResponseOffer {
  const ResponseOffer({this.proposedPrice, this.proposedComment, this.counterPrice, this.counterStatus});

  final double? proposedPrice;
  final String? proposedComment;
  final double? counterPrice;
  final CounterStatus? counterStatus;

  static const none = ResponseOffer();

  bool get hasDriverPrice => proposedPrice != null;
  bool get counterPending => counterStatus == CounterStatus.pending && counterPrice != null;
  bool get canCounter => proposedPrice != null && counterPrice == null;

  factory ResponseOffer.fromJson(Map<String, dynamic> json) => ResponseOffer(
        proposedPrice: (json['proposedPrice'] as num?)?.toDouble(),
        proposedComment: json['proposedComment'] as String?,
        counterPrice: (json['counterPrice'] as num?)?.toDouble(),
        counterStatus: switch (json['counterStatus']) {
          'PENDING' => CounterStatus.pending,
          'ACCEPTED' => CounterStatus.accepted,
          'DECLINED' => CounterStatus.declined,
          _ => null,
        },
      );
}

class CargoResponse {
  const CargoResponse({
    required this.id,
    required this.cargoId,
    required this.driverId,
    required this.driverName,
    this.isNew = false,
    this.onSiteAtPoint = false,
    this.avatarVersion,
    this.message,
    required this.status,
    required this.createdAt,
    this.capacityTons,
    this.bodyTypeId,
    this.specs,
    this.volumeM3,
    this.palletsEuro,
    this.committedWeightKg = 0,
    this.activeDealsCount = 0,
    this.committedHasUnknownWeight = false,
    this.committedDestinationCountryId,
    this.committedDestinationCityId,
    this.committedReadyDate,
    this.dealId,
    this.dealStatus,
    this.cancelStats,
    this.offer = ResponseOffer.none,
  });

  /// 058 п.5: своя цена водителя / встречная логиста.
  final ResponseOffer offer;
  final String id;
  final String cargoId;
  final String driverId;
  final String driverName;

  /// 056 п.5: этот сотрудник ещё не открывал отклик (точка «новый»).
  final bool isNew;

  /// Водитель на месте в городе погрузки — такие наверху.
  final bool onSiteAtPoint;
  final String? avatarVersion;
  final String? message;
  final ResponseStatus status;
  final DateTime createdAt;

  /// «Уже везёт…» (задача 038, п.8/9) — сводка активных сделок водителя по
  /// его текущей связке; логист видит занятость до выбора, клиент мягко
  /// предупреждает, если груз не помещается.
  final double? capacityTons;

  /// Кузов связки (или из регистрации) — миниатюра у логиста (045 п.4).
  final String? bodyTypeId;

  /// 048: параметры машины по профилю кузова — строка машины у логиста.
  final Map<String, dynamic>? specs;

  /// Объём/паллеты связки водителя (033 п.9 / 038 п.14).
  final double? volumeM3;
  final int? palletsEuro;
  final double committedWeightKg;
  final int activeDealsCount;
  final bool committedHasUnknownWeight;
  final String? committedDestinationCountryId;
  final String? committedDestinationCityId;
  final DateTime? committedReadyDate;

  /// Сделка по этому отклику (если выбран) — статус и переход в неё.
  final String? dealId;
  final DealStatus? dealStatus;

  /// 046 п.3: отмены водителя в карточке отклика.
  final CancelStats? cancelStats;

  factory CargoResponse.fromJson(Map<String, dynamic> json) => CargoResponse(
        offer: ResponseOffer.fromJson(json),
        id: json['id'] as String,
        cargoId: json['cargoId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        isNew: json['isNew'] as bool? ?? false,
        onSiteAtPoint: json['onSiteAtPoint'] as bool? ?? false,
        avatarVersion: json['avatarVersion'] as String?,
        message: json['message'] as String?,
        status: responseStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        bodyTypeId: json['bodyTypeId'] as String?,
        specs: json['specs'] as Map<String, dynamic>?,
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        palletsEuro: json['palletsEuro'] as int?,
        committedWeightKg: (json['committedWeightKg'] as num?)?.toDouble() ?? 0,
        activeDealsCount: json['activeDealsCount'] as int? ?? 0,
        committedHasUnknownWeight: json['committedHasUnknownWeight'] as bool? ?? false,
        committedDestinationCountryId: json['committedDestinationCountryId'] as String?,
        committedDestinationCityId: json['committedDestinationCityId'] as String?,
        committedReadyDate: json['committedReadyDate'] == null ? null : DateTime.parse(json['committedReadyDate'] as String),
        dealId: json['dealId'] as String?,
        dealStatus: json['dealStatus'] == null ? null : dealStatusFromJson(json['dealStatus'] as String),
        cancelStats: CancelStats.fromJson(json['cancelStats']),
      );
}


/// Мой отклик на груз (041) — для карточки водителя.
class MyCargoResponse {
  const MyCargoResponse({required this.id, required this.status, this.offer = ResponseOffer.none});

  final String id;
  final ResponseStatus status;
  final ResponseOffer offer;

  factory MyCargoResponse.fromJson(Map<String, dynamic> json) =>
      MyCargoResponse(id: json['id'] as String, status: responseStatusFromJson(json['status'] as String), offer: ResponseOffer.fromJson(json));
}


/// 056 п.1: почему отклик закрыт — для «Истории рейсов».
enum ResponseCloseReason { withdrawn, inviteExpired, cargoArchived, cargoClosed, takenByOther, rejectedByLogist, dealCancelled, accountDeleted }

ResponseCloseReason? responseCloseReasonFromJson(String? value) => switch (value) {
      'WITHDRAWN' => ResponseCloseReason.withdrawn,
      'INVITE_EXPIRED' => ResponseCloseReason.inviteExpired,
      'CARGO_ARCHIVED' => ResponseCloseReason.cargoArchived,
      'CARGO_CLOSED' => ResponseCloseReason.cargoClosed,
      'TAKEN_BY_OTHER' => ResponseCloseReason.takenByOther,
      'REJECTED_BY_LOGIST' => ResponseCloseReason.rejectedByLogist,
      'DEAL_CANCELLED' => ResponseCloseReason.dealCancelled,
      'ACCOUNT_DELETED' => ResponseCloseReason.accountDeleted,
      _ => null,
    };

/// Строка «Моих откликов» (041, п.9): статус отклика + краткая сводка груза.
/// 056 п.6: из неё строятся «Мои рейсы» и «История рейсов».
class MyResponseEntry {
  const MyResponseEntry({
    required this.id,
    required this.cargoId,
    required this.status,
    required this.cargoStatus,
    required this.destinationCountryId,
    this.destinationCityId,
    required this.bodyTypeId,
    required this.price,
    required this.currency,
    required this.readyDate,
    this.pointId,
    this.categoryId,
    this.weightKg,
    this.volumeM3,
    this.advanceAmount,
    this.paymentForm,
    this.paymentDelayDays,
    this.offer = ResponseOffer.none,
    this.companyName = '',
    this.closeReason,
    this.inviteExpiresAt,
    this.dealId,
    this.dealStatus,
    this.updatedAt,
  });

  /// 058: объём и условия оплаты груза — в карточке рейса.
  final double? volumeM3;
  final double? advanceAmount;
  final PaymentForm? paymentForm;
  final int? paymentDelayDays;
  final ResponseOffer offer;
  final String id;
  final String cargoId;
  final ResponseStatus status;
  final CargoStatus cargoStatus;
  final String destinationCountryId;
  final String? destinationCityId;
  final String bodyTypeId;
  final double price;
  final Currency currency;
  final DateTime readyDate;
  final String? pointId;
  final String? categoryId;
  final double? weightKg;
  final String companyName;
  final ResponseCloseReason? closeReason;

  /// «Вас пригласили — осталось 18 ч».
  final DateTime? inviteExpiresAt;
  final String? dealId;
  final DealStatus? dealStatus;
  final DateTime? updatedAt;

  factory MyResponseEntry.fromJson(Map<String, dynamic> json) {
    final cargo = json['cargo'] as Map<String, dynamic>;
    return MyResponseEntry(
      id: json['id'] as String,
      cargoId: json['cargoId'] as String,
      status: responseStatusFromJson(json['status'] as String),
      cargoStatus: cargoStatusFromJson(cargo['status'] as String),
      destinationCountryId: cargo['destinationCountryId'] as String,
      destinationCityId: cargo['destinationCityId'] as String?,
      bodyTypeId: cargo['bodyTypeId'] as String,
      price: (cargo['price'] as num).toDouble(),
      currency: currencyFromJson(cargo['currency'] as String),
      readyDate: DateTime.parse(cargo['readyDate'] as String),
      pointId: cargo['pointId'] as String?,
      categoryId: cargo['categoryId'] as String?,
      weightKg: (cargo['weightKg'] as num?)?.toDouble(),
      volumeM3: (cargo['volumeM3'] as num?)?.toDouble(),
      advanceAmount: (cargo['advanceAmount'] as num?)?.toDouble(),
      paymentForm: paymentFormFromJson(cargo['paymentForm'] as String?),
      paymentDelayDays: cargo['paymentDelayDays'] as int?,
      offer: ResponseOffer.fromJson(json),
      companyName: cargo['companyName'] as String? ?? '',
      closeReason: responseCloseReasonFromJson(json['closeReason'] as String?),
      inviteExpiresAt: json['inviteExpiresAt'] == null ? null : DateTime.parse(json['inviteExpiresAt'] as String),
      dealId: json['dealId'] as String?,
      dealStatus: json['dealStatus'] == null ? null : dealStatusFromJson(json['dealStatus'] as String),
      updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
    );
  }
}
