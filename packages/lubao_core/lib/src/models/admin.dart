class AdminStats {
  const AdminStats({
    required this.drivers,
    required this.companies,
    required this.cargosPublished,
    required this.dealsActive,
    required this.dealsDelivered,
    required this.pendingDocs,
    required this.openComplaints,
  });

  final int drivers;
  final int companies;
  final int cargosPublished;
  final int dealsActive;
  final int dealsDelivered;
  final int pendingDocs;
  final int openComplaints;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        drivers: json['drivers'] as int,
        companies: json['companies'] as int,
        cargosPublished: json['cargosPublished'] as int,
        dealsActive: json['dealsActive'] as int,
        dealsDelivered: json['dealsDelivered'] as int,
        pendingDocs: json['pendingDocs'] as int,
        openComplaints: json['openComplaints'] as int,
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

class AdminComplaint {
  const AdminComplaint({
    required this.id,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterName;
  final String targetType;
  final String targetId;
  final String reason;
  final String? description;
  final ComplaintStatus status;
  final DateTime createdAt;

  factory AdminComplaint.fromJson(Map<String, dynamic> json) => AdminComplaint(
        id: json['id'] as String,
        reporterName: json['reporterName'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        reason: json['reason'] as String,
        description: json['description'] as String?,
        status: complaintStatusFromJson(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class AdminCompanySummary {
  const AdminCompanySummary({
    required this.id,
    required this.name,
    required this.countryId,
    this.city,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String name;
  final String countryId;
  final String? city;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  factory AdminCompanySummary.fromJson(Map<String, dynamic> json) => AdminCompanySummary(
        id: json['id'] as String,
        name: json['name'] as String,
        countryId: json['countryId'] as String,
        city: json['city'] as String?,
        isVerified: json['isVerified'] as bool,
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
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

class AdminDriverSummary {
  const AdminDriverSummary({
    required this.id,
    required this.fullName,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String fullName;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  factory AdminDriverSummary.fromJson(Map<String, dynamic> json) => AdminDriverSummary(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        isVerified: json['isVerified'] as bool,
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        ratingCount: json['ratingCount'] as int,
      );
}
