import 'common.dart';

class AdminStatsGrowth {
  const AdminStatsGrowth({required this.drivers, required this.companies, required this.cargos, required this.delivered});

  final int drivers;
  final int companies;
  final int cargos;
  final int delivered;

  factory AdminStatsGrowth.fromJson(Map<String, dynamic> json) => AdminStatsGrowth(
        drivers: json['drivers'] as int,
        companies: json['companies'] as int,
        cargos: json['cargos'] as int,
        delivered: json['delivered'] as int,
      );
}

class AdminStats {
  const AdminStats({
    required this.drivers,
    required this.companies,
    required this.cargosPublished,
    required this.dealsActive,
    required this.dealsDelivered,
    required this.pendingDocs,
    required this.openComplaints,
    required this.period,
    required this.growth,
    required this.onSiteToday,
    required this.onSiteWeek,
  });

  final int drivers;
  final int companies;
  final int cargosPublished;
  final int dealsActive;
  final int dealsDelivered;
  final int pendingDocs;
  final int openComplaints;
  final String period;
  final AdminStatsGrowth growth;
  final int onSiteToday;
  final int onSiteWeek;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        drivers: json['drivers'] as int,
        companies: json['companies'] as int,
        cargosPublished: json['cargosPublished'] as int,
        dealsActive: json['dealsActive'] as int,
        dealsDelivered: json['dealsDelivered'] as int,
        pendingDocs: json['pendingDocs'] as int,
        openComplaints: json['openComplaints'] as int,
        period: json['period'] as String? ?? 'today',
        growth: json['growth'] == null
            ? const AdminStatsGrowth(drivers: 0, companies: 0, cargos: 0, delivered: 0)
            : AdminStatsGrowth.fromJson(json['growth'] as Map<String, dynamic>),
        onSiteToday: json['onSiteToday'] as int? ?? 0,
        onSiteWeek: json['onSiteWeek'] as int? ?? 0,
      );
}

enum VerificationStatus { pending, approved, rejected }

VerificationStatus verificationStatusFromJson(String value) => VerificationStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => VerificationStatus.pending,
    );

class AdminVerificationDocument {
  const AdminVerificationDocument({
    required this.id,
    required this.subjectName,
    this.driverId,
    this.companyId,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectReason,
    this.reviewedByName,
    this.reviewedAt,
    required this.createdAt,
  });

  final String id;
  final String subjectName;
  final String? driverId;
  final String? companyId;
  final String type;
  final String fileUrl;
  final VerificationStatus status;
  final String? rejectReason;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  factory AdminVerificationDocument.fromJson(Map<String, dynamic> json) => AdminVerificationDocument(
        id: json['id'] as String,
        subjectName: json['subjectName'] as String,
        driverId: json['driverId'] as String?,
        companyId: json['companyId'] as String?,
        type: json['type'] as String,
        fileUrl: json['fileUrl'] as String,
        status: verificationStatusFromJson(json['status'] as String),
        rejectReason: json['rejectReason'] as String?,
        reviewedByName: json['reviewedByName'] as String?,
        reviewedAt: json['reviewedAt'] == null ? null : DateTime.parse(json['reviewedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Документ в карточке водителя/компании (задача 026, п.3/4) — тот же набор
/// полей, что у [AdminVerificationDocument], но без subjectName/companyId/
/// driverId (они избыточны внутри уже открытой карточки конкретного
/// субъекта).
class AdminCardDocument {
  const AdminCardDocument({
    required this.id,
    required this.type,
    required this.fileUrl,
    required this.status,
    this.rejectReason,
    this.reviewedByName,
    this.reviewedAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String fileUrl;
  final VerificationStatus status;
  final String? rejectReason;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  factory AdminCardDocument.fromJson(Map<String, dynamic> json) => AdminCardDocument(
        id: json['id'] as String,
        type: json['type'] as String,
        fileUrl: json['fileUrl'] as String,
        status: verificationStatusFromJson(json['status'] as String),
        rejectReason: json['rejectReason'] as String?,
        reviewedByName: json['reviewedByName'] as String?,
        reviewedAt: json['reviewedAt'] == null ? null : DateTime.parse(json['reviewedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum ComplaintStatus { open, inReview, resolved, rejected }

ComplaintStatus complaintStatusFromJson(String value) {
  switch (value.toUpperCase()) {
    case 'OPEN':
      return ComplaintStatus.open;
    case 'IN_REVIEW':
      return ComplaintStatus.inReview;
    case 'RESOLVED':
      return ComplaintStatus.resolved;
    case 'REJECTED':
      return ComplaintStatus.rejected;
    default:
      return ComplaintStatus.open;
  }
}

String complaintStatusToJson(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.open:
      return 'OPEN';
    case ComplaintStatus.inReview:
      return 'IN_REVIEW';
    case ComplaintStatus.resolved:
      return 'RESOLVED';
    case ComplaintStatus.rejected:
      return 'REJECTED';
  }
}

/// Кто реально нарушитель (задача 026, п.7) — чтобы из жалобы перейти на
/// карточку водителя/компании, а не только видеть сырой targetType/targetId.
class AdminComplaintTarget {
  const AdminComplaintTarget({required this.type, required this.id, required this.title, this.driverId, this.companyId});

  final String type;
  final String id;
  final String title;
  final String? driverId;
  final String? companyId;

  factory AdminComplaintTarget.fromJson(Map<String, dynamic> json) => AdminComplaintTarget(
        type: json['type'] as String,
        id: json['id'] as String,
        title: json['title'] as String,
        driverId: json['driverId'] as String?,
        companyId: json['companyId'] as String?,
      );
}

class AdminComplaint {
  const AdminComplaint({
    required this.id,
    required this.reporterUserId,
    required this.reporterName,
    this.reporter,
    required this.targetType,
    required this.targetId,
    this.target,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterUserId;
  final String reporterName;
  final AdminComplaintTarget? reporter;
  final String targetType;
  final String targetId;
  final AdminComplaintTarget? target;
  final String reason;
  final String? description;
  final ComplaintStatus status;
  final DateTime createdAt;

  factory AdminComplaint.fromJson(Map<String, dynamic> json) => AdminComplaint(
        id: json['id'] as String,
        reporterUserId: json['reporterUserId'] as String,
        reporterName: json['reporterName'] as String,
        reporter: json['reporter'] == null ? null : AdminComplaintTarget.fromJson(json['reporter'] as Map<String, dynamic>),
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        target: json['target'] == null ? null : AdminComplaintTarget.fromJson(json['target'] as Map<String, dynamic>),
        reason: json['reason'] as String,
        description: json['description'] as String?,
        status: complaintStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Строка списка водителей в админке (задача 026, п.1) — поиск/фильтр/
/// пагинация, без тяжёлых вложенных данных карточки.
class AdminDriverRow {
  const AdminDriverRow({
    required this.id,
    required this.fullName,
    this.phone,
    required this.homeCityName,
    this.vehicleBodyTypeName,
    this.vehicleCapacityTons,
    required this.isVerified,
    required this.pendingDocsCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedDeals,
    required this.isBlocked,
    required this.registeredAt,
    this.lastArrivalStatus,
    this.lastArrivalAt,
  });

  final String id;
  final String fullName;
  final String? phone;
  final I18nText homeCityName;
  final I18nText? vehicleBodyTypeName;
  final double? vehicleCapacityTons;
  final bool isVerified;
  final int pendingDocsCount;
  final double ratingAvg;
  final int ratingCount;
  final int completedDeals;
  final bool isBlocked;
  final DateTime registeredAt;
  final String? lastArrivalStatus;
  final DateTime? lastArrivalAt;

  factory AdminDriverRow.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final lastArrival = json['lastArrival'] as Map<String, dynamic>?;
    return AdminDriverRow(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String?,
      homeCityName: I18nText.fromJson(json['homeCityName'] as Map<String, dynamic>),
      vehicleBodyTypeName: vehicle == null ? null : I18nText.fromJson(vehicle['bodyTypeName'] as Map<String, dynamic>),
      vehicleCapacityTons: vehicle?['capacityTons'] == null ? null : (vehicle!['capacityTons'] as num).toDouble(),
      isVerified: json['isVerified'] as bool,
      pendingDocsCount: json['pendingDocsCount'] as int,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      completedDeals: json['completedDeals'] as int,
      isBlocked: json['isBlocked'] as bool,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      lastArrivalStatus: lastArrival?['status'] as String?,
      lastArrivalAt: lastArrival?['plannedAt'] == null ? null : DateTime.parse(lastArrival!['plannedAt'] as String),
    );
  }
}

class AdminSearchPage<T> {
  const AdminSearchPage({required this.items, required this.total});

  final List<T> items;
  final int total;
}

class AdminDriverVehicle {
  const AdminDriverVehicle({
    required this.id,
    required this.bodyTypeName,
    this.capacityTons,
    this.lengthM,
    this.plateNumber,
    this.brand,
  });

  final String id;
  final I18nText bodyTypeName;
  final double? capacityTons;
  final double? lengthM;
  final String? plateNumber;
  final String? brand;

  factory AdminDriverVehicle.fromJson(Map<String, dynamic> json) => AdminDriverVehicle(
        id: json['id'] as String,
        bodyTypeName: I18nText.fromJson(json['bodyTypeName'] as Map<String, dynamic>),
        capacityTons: json['capacityTons'] == null ? null : (json['capacityTons'] as num).toDouble(),
        lengthM: json['lengthM'] == null ? null : (json['lengthM'] as num).toDouble(),
        plateNumber: json['plateNumber'] as String?,
        brand: json['brand'] as String?,
      );
}

class AdminAuditLogEntry {
  const AdminAuditLogEntry({
    required this.id,
    required this.action,
    this.entityType,
    this.entityId,
    this.actorName,
    this.metadata,
    required this.createdAt,
  });

  final String id;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? actorName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  factory AdminAuditLogEntry.fromJson(Map<String, dynamic> json) => AdminAuditLogEntry(
        id: json['id'] as String,
        action: json['action'] as String,
        entityType: json['entityType'] as String?,
        entityId: json['entityId'] as String?,
        actorName: json['actorName'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminReviewEntry {
  const AdminReviewEntry({required this.id, required this.rating, this.comment, required this.dealId, required this.createdAt});

  final String id;
  final int rating;
  final String? comment;
  final String dealId;
  final DateTime createdAt;

  factory AdminReviewEntry.fromJson(Map<String, dynamic> json) => AdminReviewEntry(
        id: json['id'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        dealId: json['dealId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminDriverDealEntry {
  const AdminDriverDealEntry({required this.id, required this.status, required this.companyId, required this.companyName, required this.createdAt});

  final String id;
  final DealStatus status;
  final String companyId;
  final String companyName;
  final DateTime createdAt;

  factory AdminDriverDealEntry.fromJson(Map<String, dynamic> json) => AdminDriverDealEntry(
        id: json['id'] as String,
        status: dealStatusFromJson(json['status'] as String),
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminSessionEntry {
  const AdminSessionEntry({required this.id, this.deviceName, this.platform, required this.lastUsedAt, required this.createdAt});

  final String id;
  final String? deviceName;
  final String? platform;
  final DateTime lastUsedAt;
  final DateTime createdAt;

  factory AdminSessionEntry.fromJson(Map<String, dynamic> json) => AdminSessionEntry(
        id: json['id'] as String,
        deviceName: json['deviceName'] as String?,
        platform: json['platform'] as String?,
        lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminDriverStats {
  const AdminDriverStats({
    required this.dealsByStatus,
    required this.cancellations,
    required this.ratingAvg,
    required this.ratingCount,
    required this.reviews,
    required this.calls,
    required this.whatsapp,
    required this.complaintsAgainst,
    required this.complaintsBy,
  });

  final Map<String, int> dealsByStatus;
  final int cancellations;
  final double ratingAvg;
  final int ratingCount;
  final List<AdminReviewEntry> reviews;
  final int calls;
  final int whatsapp;
  final int complaintsAgainst;
  final int complaintsBy;

  factory AdminDriverStats.fromJson(Map<String, dynamic> json) => AdminDriverStats(
        dealsByStatus: (json['dealsByStatus'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
        cancellations: json['cancellations'] as int,
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
        reviews: (json['reviews'] as List<dynamic>).map((e) => AdminReviewEntry.fromJson(e as Map<String, dynamic>)).toList(),
        calls: json['calls'] as int,
        whatsapp: json['whatsapp'] as int,
        complaintsAgainst: json['complaintsAgainst'] as int,
        complaintsBy: json['complaintsBy'] as int,
      );
}

class AdminDriverDetail {
  const AdminDriverDetail({
    required this.id,
    required this.fullName,
    required this.isVerified,
    required this.userId,
    this.phone,
    required this.locale,
    required this.registeredAt,
    required this.isBlocked,
    required this.lastLoginAt,
    required this.homeCityName,
    required this.anyCountry,
    required this.directionNames,
    required this.permitNames,
    required this.vehicles,
    required this.documents,
    required this.stats,
    required this.deals,
    required this.sessions,
    required this.auditLog,
  });

  final String id;
  final String fullName;
  final bool isVerified;
  final String userId;
  final String? phone;
  final String locale;
  final DateTime registeredAt;
  final bool isBlocked;
  final DateTime lastLoginAt;
  final I18nText homeCityName;
  final bool anyCountry;
  final List<I18nText> directionNames;
  final List<I18nText> permitNames;
  final List<AdminDriverVehicle> vehicles;
  final List<AdminCardDocument> documents;
  final AdminDriverStats stats;
  final List<AdminDriverDealEntry> deals;
  final List<AdminSessionEntry> sessions;
  final List<AdminAuditLogEntry> auditLog;

  factory AdminDriverDetail.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AdminDriverDetail(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      isVerified: json['isVerified'] as bool,
      userId: user['id'] as String,
      phone: user['phone'] as String?,
      locale: user['locale'] as String,
      registeredAt: DateTime.parse(user['createdAt'] as String),
      isBlocked: user['isBlocked'] as bool,
      lastLoginAt: DateTime.parse(user['lastLoginAt'] as String),
      homeCityName: I18nText.fromJson(json['homeCityName'] as Map<String, dynamic>),
      anyCountry: json['anyCountry'] as bool,
      directionNames: (json['directions'] as List<dynamic>)
          .map((e) => I18nText.fromJson((e as Map<String, dynamic>)['name'] as Map<String, dynamic>))
          .toList(),
      permitNames: (json['permits'] as List<dynamic>)
          .map((e) => I18nText.fromJson((e as Map<String, dynamic>)['name'] as Map<String, dynamic>))
          .toList(),
      vehicles: (json['vehicles'] as List<dynamic>).map((e) => AdminDriverVehicle.fromJson(e as Map<String, dynamic>)).toList(),
      documents: (json['documents'] as List<dynamic>).map((e) => AdminCardDocument.fromJson(e as Map<String, dynamic>)).toList(),
      stats: AdminDriverStats.fromJson(json['stats'] as Map<String, dynamic>),
      deals: (json['deals'] as List<dynamic>).map((e) => AdminDriverDealEntry.fromJson(e as Map<String, dynamic>)).toList(),
      sessions: (json['sessions'] as List<dynamic>).map((e) => AdminSessionEntry.fromJson(e as Map<String, dynamic>)).toList(),
      auditLog: (json['auditLog'] as List<dynamic>).map((e) => AdminAuditLogEntry.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Строка списка компаний (задача 026, п.2).
class AdminCompanyRow {
  const AdminCompanyRow({
    required this.id,
    required this.name,
    this.nameRu,
    required this.countryId,
    this.ownerName,
    this.ownerEmail,
    required this.employeeCount,
    required this.activeCargoCount,
    required this.dealCount,
    required this.isVerified,
    required this.pendingDocsCount,
    required this.isBlocked,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String name;
  final String? nameRu;
  final String countryId;
  final String? ownerName;
  final String? ownerEmail;
  final int employeeCount;
  final int activeCargoCount;
  final int dealCount;
  final bool isVerified;
  final int pendingDocsCount;
  final bool isBlocked;
  final double ratingAvg;
  final int ratingCount;

  factory AdminCompanyRow.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return AdminCompanyRow(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['nameRu'] as String?,
      countryId: json['countryId'] as String,
      ownerName: owner?['name'] as String?,
      ownerEmail: owner?['email'] as String?,
      employeeCount: json['employeeCount'] as int,
      activeCargoCount: json['activeCargoCount'] as int,
      dealCount: json['dealCount'] as int,
      isVerified: json['isVerified'] as bool,
      pendingDocsCount: json['pendingDocsCount'] as int,
      isBlocked: json['isBlocked'] as bool,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
    );
  }
}

class AdminEmployeeEntry {
  const AdminEmployeeEntry({required this.userId, this.name, this.email, required this.role, required this.isBlocked, this.lastLoginAt});

  final String userId;
  final String? name;
  final String? email;
  final String role;
  final bool isBlocked;
  final DateTime? lastLoginAt;

  factory AdminEmployeeEntry.fromJson(Map<String, dynamic> json) => AdminEmployeeEntry(
        userId: json['userId'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String,
        isBlocked: json['isBlocked'] as bool,
        lastLoginAt: json['lastLoginAt'] == null ? null : DateTime.parse(json['lastLoginAt'] as String),
      );
}

class AdminInviteEntry {
  const AdminInviteEntry({required this.email, required this.role, required this.expiresAt, this.usedAt});

  final String email;
  final String role;
  final DateTime expiresAt;
  final DateTime? usedAt;

  factory AdminInviteEntry.fromJson(Map<String, dynamic> json) => AdminInviteEntry(
        email: json['email'] as String,
        role: json['role'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        usedAt: json['usedAt'] == null ? null : DateTime.parse(json['usedAt'] as String),
      );
}

class AdminCargoEntry {
  const AdminCargoEntry({
    required this.id,
    required this.pointName,
    required this.destinationCountryName,
    required this.price,
    required this.currency,
    required this.status,
    required this.responseCount,
    required this.createdAt,
  });

  final String id;
  final I18nText pointName;
  final I18nText destinationCountryName;
  final double price;
  final String currency;
  final String status;
  final int responseCount;
  final DateTime createdAt;

  factory AdminCargoEntry.fromJson(Map<String, dynamic> json) => AdminCargoEntry(
        id: json['id'] as String,
        pointName: I18nText.fromJson(json['pointName'] as Map<String, dynamic>),
        destinationCountryName: I18nText.fromJson(json['destinationCountryName'] as Map<String, dynamic>),
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        responseCount: json['responseCount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminCompanyDealEntry {
  const AdminCompanyDealEntry({required this.id, required this.status, required this.driverId, required this.driverName, required this.createdAt});

  final String id;
  final DealStatus status;
  final String driverId;
  final String driverName;
  final DateTime createdAt;

  factory AdminCompanyDealEntry.fromJson(Map<String, dynamic> json) => AdminCompanyDealEntry(
        id: json['id'] as String,
        status: dealStatusFromJson(json['status'] as String),
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminCompanyDetail {
  const AdminCompanyDetail({
    required this.id,
    required this.name,
    this.nameRu,
    required this.countryName,
    this.city,
    this.legalAddress,
    this.taxId,
    required this.isVerified,
    required this.isBlocked,
    required this.ratingAvg,
    required this.ratingCount,
    required this.documents,
    required this.employees,
    required this.invites,
    required this.cargos,
    required this.deals,
    required this.reviews,
    required this.complaintsAgainst,
    required this.auditLog,
  });

  final String id;
  final String name;
  final String? nameRu;
  final I18nText countryName;
  final String? city;
  final String? legalAddress;
  final String? taxId;
  final bool isVerified;
  final bool isBlocked;
  final double ratingAvg;
  final int ratingCount;
  final List<AdminCardDocument> documents;
  final List<AdminEmployeeEntry> employees;
  final List<AdminInviteEntry> invites;
  final List<AdminCargoEntry> cargos;
  final List<AdminCompanyDealEntry> deals;
  final List<AdminReviewEntry> reviews;
  final int complaintsAgainst;
  final List<AdminAuditLogEntry> auditLog;

  factory AdminCompanyDetail.fromJson(Map<String, dynamic> json) => AdminCompanyDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        nameRu: json['nameRu'] as String?,
        countryName: I18nText.fromJson(json['countryName'] as Map<String, dynamic>),
        city: json['city'] as String?,
        legalAddress: json['legalAddress'] as String?,
        taxId: json['taxId'] as String?,
        isVerified: json['isVerified'] as bool,
        isBlocked: json['isBlocked'] as bool,
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
        documents: (json['documents'] as List<dynamic>).map((e) => AdminCardDocument.fromJson(e as Map<String, dynamic>)).toList(),
        employees: (json['employees'] as List<dynamic>).map((e) => AdminEmployeeEntry.fromJson(e as Map<String, dynamic>)).toList(),
        invites: (json['invites'] as List<dynamic>).map((e) => AdminInviteEntry.fromJson(e as Map<String, dynamic>)).toList(),
        cargos: (json['cargos'] as List<dynamic>).map((e) => AdminCargoEntry.fromJson(e as Map<String, dynamic>)).toList(),
        deals: (json['deals'] as List<dynamic>).map((e) => AdminCompanyDealEntry.fromJson(e as Map<String, dynamic>)).toList(),
        reviews: (json['reviews'] as List<dynamic>).map((e) => AdminReviewEntry.fromJson(e as Map<String, dynamic>)).toList(),
        complaintsAgainst: json['complaintsAgainst'] as int,
        auditLog: (json['auditLog'] as List<dynamic>).map((e) => AdminAuditLogEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Город, предложенный водителем/логистом через «Нет моего города»
/// (задача 021) и ждущий подтверждения/объединения/отклонения админом.
class AdminPendingCity {
  const AdminPendingCity({
    required this.id,
    required this.name,
    this.regionName,
    this.submittedByLabel,
    required this.createdAt,
  });

  final String id;

  /// Пока не подтверждён — заполнен только `ru` (как ввёл пользователь).
  final String name;
  final String? regionName;
  final String? submittedByLabel;
  final DateTime createdAt;

  factory AdminPendingCity.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    final region = json['region'] as Map<String, dynamic>?;
    final submittedBy = json['submittedBy'] as Map<String, dynamic>?;
    final regionName = region == null ? null : (region['name'] as Map<String, dynamic>);
    return AdminPendingCity(
      id: json['id'] as String,
      name: (name['ru'] as String?) ?? (name['kk'] as String?) ?? (name['zh'] as String?) ?? '',
      regionName: regionName == null ? null : (regionName['ru'] as String? ?? ''),
      submittedByLabel: submittedBy == null ? null : (submittedBy['phone'] as String? ?? submittedBy['email'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Блок «Требует внимания» на сводке (задача 028, п.4).
class AdminAttention {
  const AdminAttention({
    required this.pendingVerificationCount,
    required this.pendingVerificationOldestAgeHours,
    required this.openComplaints,
    required this.staleDeals,
    required this.unverifiedCompanies,
    required this.pendingCities,
  });

  final int pendingVerificationCount;
  final int pendingVerificationOldestAgeHours;
  final int openComplaints;
  final int staleDeals;
  final int unverifiedCompanies;
  final int pendingCities;

  factory AdminAttention.fromJson(Map<String, dynamic> json) {
    final pv = json['pendingVerification'] as Map<String, dynamic>;
    return AdminAttention(
      pendingVerificationCount: pv['count'] as int,
      pendingVerificationOldestAgeHours: pv['oldestAgeHours'] as int,
      openComplaints: json['openComplaints'] as int,
      staleDeals: json['staleDeals'] as int,
      unverifiedCompanies: json['unverifiedCompanies'] as int,
      pendingCities: json['pendingCities'] as int,
    );
  }
}

/// Строка «Последних событий» (задача 028, п.5) — смешанная лента
/// audit_log + регистраций + новых грузов + смен статуса сделок.
class AdminEvent {
  const AdminEvent({required this.type, required this.title, required this.entityId, required this.createdAt});

  final String type;
  final String title;
  final String entityId;
  final DateTime createdAt;

  factory AdminEvent.fromJson(Map<String, dynamic> json) => AdminEvent(
        type: json['type'] as String,
        title: json['title'] as String,
        entityId: json['entityId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminSearchHit {
  const AdminSearchHit({required this.id, required this.title});

  final String id;
  final String title;

  factory AdminSearchHit.fromJson(Map<String, dynamic> json) => AdminSearchHit(
        id: json['id'] as String,
        title: json['title'] is String ? json['title'] as String : (json['title'] as Map<String, dynamic>).values.whereType<String>().firstWhere((s) => s.isNotEmpty, orElse: () => ''),
      );
}

/// Глобальный поиск (задача 028, п.6) — результаты сгруппированы по типу.
class AdminSearchResults {
  const AdminSearchResults({required this.drivers, required this.companies, required this.cargos, required this.deals});

  final List<AdminSearchHit> drivers;
  final List<AdminSearchHit> companies;
  final List<AdminSearchHit> cargos;
  final List<AdminSearchHit> deals;

  bool get isEmpty => drivers.isEmpty && companies.isEmpty && cargos.isEmpty && deals.isEmpty;

  factory AdminSearchResults.fromJson(Map<String, dynamic> json) => AdminSearchResults(
        drivers: (json['drivers'] as List<dynamic>).map((e) => AdminSearchHit.fromJson(e as Map<String, dynamic>)).toList(),
        companies: (json['companies'] as List<dynamic>).map((e) => AdminSearchHit.fromJson(e as Map<String, dynamic>)).toList(),
        cargos: (json['cargos'] as List<dynamic>).map((e) => AdminSearchHit.fromJson(e as Map<String, dynamic>)).toList(),
        deals: (json['deals'] as List<dynamic>).map((e) => AdminSearchHit.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Строка списка грузов в админке (задача 028, п.14).
class AdminCargoRow {
  const AdminCargoRow({
    required this.id,
    required this.pointName,
    required this.destinationCountryName,
    this.destinationCityName,
    required this.bodyTypeName,
    this.weightKg,
    required this.price,
    required this.currency,
    required this.companyId,
    required this.companyName,
    required this.responseCount,
    required this.status,
    required this.publishedAt,
  });

  final String id;
  final I18nText pointName;
  final I18nText destinationCountryName;
  final I18nText? destinationCityName;
  final I18nText bodyTypeName;
  final double? weightKg;
  final double price;
  final String currency;
  final String companyId;
  final String companyName;
  final int responseCount;
  final String status;
  final DateTime publishedAt;

  factory AdminCargoRow.fromJson(Map<String, dynamic> json) => AdminCargoRow(
        id: json['id'] as String,
        pointName: I18nText.fromJson(json['pointName'] as Map<String, dynamic>),
        destinationCountryName: I18nText.fromJson(json['destinationCountryName'] as Map<String, dynamic>),
        destinationCityName: json['destinationCityName'] == null ? null : I18nText.fromJson(json['destinationCityName'] as Map<String, dynamic>),
        bodyTypeName: I18nText.fromJson(json['bodyTypeName'] as Map<String, dynamic>),
        weightKg: json['weightKg'] == null ? null : (json['weightKg'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String,
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String,
        responseCount: json['responseCount'] as int,
        status: json['status'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
      );
}

/// Строка списка сделок в админке (задача 028, п.16).
class AdminDealRow {
  const AdminDealRow({
    required this.id,
    required this.pointName,
    required this.destinationCountryName,
    required this.driverId,
    required this.driverName,
    required this.companyId,
    required this.companyName,
    required this.price,
    required this.currency,
    required this.status,
    required this.staleDays,
    required this.createdAt,
  });

  final String id;
  final I18nText pointName;
  final I18nText destinationCountryName;
  final String driverId;
  final String driverName;
  final String companyId;
  final String companyName;
  final double price;
  final String currency;
  final String status;
  final int staleDays;
  final DateTime createdAt;

  factory AdminDealRow.fromJson(Map<String, dynamic> json) => AdminDealRow(
        id: json['id'] as String,
        pointName: I18nText.fromJson(json['pointName'] as Map<String, dynamic>),
        destinationCountryName: I18nText.fromJson(json['destinationCountryName'] as Map<String, dynamic>),
        driverId: json['driverId'] as String,
        driverName: json['driverName'] as String,
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
        staleDays: json['staleDays'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
