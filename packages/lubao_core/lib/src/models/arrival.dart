/// Статус анонса прибытия (задача 015): PLANNED — «буду», ON_SITE — «на
/// месте», COMPLETED/CANCELLED — завершён, EXPIRED — угас по правилу
/// свежести (040). Неизвестное значение с бэкенда не должно падать клиент —
/// фолбэк на `planned`.
enum ArrivalStatus { planned, onSite, completed, cancelled, expired }

ArrivalStatus arrivalStatusFromJson(String value) {
  switch (value) {
    case 'ON_SITE':
      return ArrivalStatus.onSite;
    case 'COMPLETED':
      return ArrivalStatus.completed;
    case 'CANCELLED':
      return ArrivalStatus.cancelled;
    case 'EXPIRED':
      return ArrivalStatus.expired;
    case 'PLANNED':
    default:
      return ArrivalStatus.planned;
  }
}

/// Строка списка «Кто будет на точке» — водитель с активным (PLANNED или
/// ON_SITE) анонсом, со стороны логиста.
class ArrivalListing {
  const ArrivalListing({
    required this.arrivalId,
    required this.driverId,
    required this.driverName,
    this.hasPhone = false,
    this.specs,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
    required this.pointId,
    required this.status,
    required this.plannedAt,
    required this.plannedDay,
    this.arrivedAt,
    this.bodyTypeId,
    this.capacityTons,
    this.volumeM3,
    this.palletsEuro,
    this.committedWeightKg = 0,
    this.activeDealsCount = 0,
    this.committedHasUnknownWeight = false,
    this.committedDestinationCountryId,
    this.committedDestinationCityId,
    this.committedReadyDate,
    this.dealsTotal = 0,
    this.dealsCancelledByDriver = 0,
    required this.anyCountry,
    required this.directionCountryIds,
  });

  final String arrivalId;
  final String driverId;
  final String driverName;
  /// Номер водителя — только по нажатию (043 п.11, `revealDriverContact`).
  final bool hasPhone;

  /// 048: параметры машины по профилю кузова — строка машины у логиста.
  final Map<String, dynamic>? specs;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;
  final String pointId;
  final ArrivalStatus status;
  final DateTime plannedAt;

  /// Календарный день приезда (041, п.5) — без часового пояса.
  final DateTime plannedDay;
  final DateTime? arrivedAt;
  final String? bodyTypeId;
  final double? capacityTons;

  /// Размер кузова связки (задача 033, п.9) — «тент · 20 т · 90 м³ · 33 пал.».
  final double? volumeM3;
  final int? palletsEuro;

  /// Сколько водитель уже везёт по активным сделкам (задача 037, п.7) —
  /// логист видит догруз ДО выбора; 0 — свободен.
  final double committedWeightKg;
  final int activeDealsCount;

  /// Задача 038, п.8 — груз без веса в активной сделке («машина занята»),
  /// назначение и дата погрузки первого активного груза для строки
  /// «Уже везёт: 8 т из 20 т · Алматы · погрузка завтра».
  final bool committedHasUnknownWeight;
  final String? committedDestinationCountryId;
  final String? committedDestinationCityId;
  final DateTime? committedReadyDate;

  /// «Отменил 1 из 15 сделок» (задача 038, п.15) — доля отмен водителем.
  final int dealsTotal;
  final int dealsCancelledByDriver;
  final bool anyCountry;
  final List<String> directionCountryIds;

  factory ArrivalListing.fromJson(Map<String, dynamic> json) => ArrivalListing(
        arrivalId: json['arrivalId'] as String,
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String? ?? '',
        hasPhone: json['hasPhone'] as bool? ?? false,
        specs: json['specs'] as Map<String, dynamic>?,
        isVerified: json['isVerified'] as bool? ?? false,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        pointId: json['pointId'] as String,
        status: arrivalStatusFromJson(json['status'] as String),
        plannedAt: DateTime.parse(json['plannedAt'] as String),
        plannedDay: DateTime.parse((json['plannedDay'] ?? json['plannedAt']) as String),
        arrivedAt: json['arrivedAt'] == null ? null : DateTime.parse(json['arrivedAt'] as String),
        bodyTypeId: json['bodyTypeId'] as String?,
        capacityTons: (json['capacityTons'] as num?)?.toDouble(),
        volumeM3: (json['volumeM3'] as num?)?.toDouble(),
        palletsEuro: json['palletsEuro'] as int?,
        committedWeightKg: (json['committedWeightKg'] as num?)?.toDouble() ?? 0,
        activeDealsCount: json['activeDealsCount'] as int? ?? 0,
        committedHasUnknownWeight: json['committedHasUnknownWeight'] as bool? ?? false,
        committedDestinationCountryId: json['committedDestinationCountryId'] as String?,
        committedDestinationCityId: json['committedDestinationCityId'] as String?,
        committedReadyDate: json['committedReadyDate'] == null ? null : DateTime.parse(json['committedReadyDate'] as String),
        dealsTotal: json['dealsTotal'] as int? ?? 0,
        dealsCancelledByDriver: json['dealsCancelledByDriver'] as int? ?? 0,
        anyCountry: json['anyCountry'] as bool? ?? false,
        directionCountryIds:
            (json['directionCountryIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}

/// Шаблон последнего завершённого/отменённого анонса — для «Повторить
/// прошлый анонс» (показать точку/страны до нажатия кнопки).
class ArrivalTemplate {
  const ArrivalTemplate({required this.pointId, required this.anyCountry, required this.countryIds});

  final String pointId;
  final bool anyCountry;
  final List<String> countryIds;

  factory ArrivalTemplate.fromJson(Map<String, dynamic> json) => ArrivalTemplate(
        pointId: json['pointId'] as String,
        anyCountry: json['anyCountry'] as bool? ?? false,
        countryIds: (json['countryIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}

/// Что приложению спросить у водителя сейчас (правило свежести, 040).
enum ArrivalQuestion { day, stillLooking }

class Arrival {
  const Arrival({
    required this.id,
    required this.pointId,
    required this.plannedAt,
    required this.plannedDay,
    this.arrivedAt,
    required this.waitDays,
    required this.anyCountry,
    required this.countryIds,
    required this.status,
    required this.viewsCount,
    this.tractorId,
    this.trailerId,
    this.ask,
  });

  final String id;
  final String pointId;
  final DateTime plannedAt;

  /// Календарный день приезда без часового пояса (041, п.5).
  final DateTime plannedDay;
  final DateTime? arrivedAt;
  final int waitDays;
  final bool anyCountry;
  final List<String> countryIds;
  final ArrivalStatus status;
  final int viewsCount;
  /// Связка на эту поездку (задача 031, этап B, п.9).
  final String? tractorId;
  final String? trailerId;

  /// «Доехали?» (в день приезда) / «Ещё ищете груз?» (на месте, 12 ч без
  /// ответа) — сервер уже отправил push, приложение показывает те же кнопки.
  final ArrivalQuestion? ask;

  factory Arrival.fromJson(Map<String, dynamic> json) => Arrival(
        id: json['id'] as String,
        pointId: json['pointId'] as String,
        plannedAt: DateTime.parse(json['plannedAt'] as String),
        plannedDay: DateTime.parse((json['plannedDay'] ?? json['plannedAt']) as String),
        arrivedAt: json['arrivedAt'] == null ? null : DateTime.parse(json['arrivedAt'] as String),
        waitDays: json['waitDays'] as int? ?? 2,
        anyCountry: json['anyCountry'] as bool? ?? false,
        countryIds: (json['countryIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
        status: arrivalStatusFromJson(json['status'] as String),
        viewsCount: json['viewsCount'] as int? ?? 0,
        tractorId: json['tractorId'] as String?,
        trailerId: json['trailerId'] as String?,
        ask: switch (json['ask']) {
          'DAY' => ArrivalQuestion.day,
          'STILL_LOOKING' => ArrivalQuestion.stillLooking,
          _ => null,
        },
      );
}

/// Мои активные анонсы (040: их может быть несколько): `current` — где
/// водитель на месте, иначе ближайший; `all` — все активные, «на месте»
/// первым, остальные по дате.
class MyArrivals {
  const MyArrivals({required this.current, required this.all});

  final Arrival? current;
  final List<Arrival> all;

  /// Остальные анонсы, кроме текущего.
  List<Arrival> get others => all.where((a) => a.id != current?.id).toList();
}

class ArrivalSummaryDay {
  const ArrivalSummaryDay({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory ArrivalSummaryDay.fromJson(Map<String, dynamic> json) =>
      ArrivalSummaryDay(date: DateTime.parse(json['date'] as String), count: json['count'] as int? ?? 0);
}
