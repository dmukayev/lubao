/// 058 п.6: строка «Моих водителей» у логиста. `driverId` пуст — заведён
/// компанией и ещё не входил; `pending` — ждёт входа / «Принять» (видно
/// только имя).
class CompanyDriverEntry {
  const CompanyDriverEntry({
    this.rowId,
    this.driverId,
    required this.name,
    this.pending = false,
    this.saved = false,
    this.createdByCompany = false,
    this.fromDeals = false,
    this.isVerified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.avatarVersion,
    this.lastSeenAt,
    this.searching = false,
    this.onSite = false,
  });

  final String? rowId;
  final String? driverId;
  final String name;
  final bool pending;
  final bool saved;
  final bool createdByCompany;
  final bool fromDeals;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;
  final String? avatarVersion;
  final DateTime? lastSeenAt;
  final bool searching;
  final bool onSite;

  factory CompanyDriverEntry.fromJson(Map<String, dynamic> json) => CompanyDriverEntry(
        rowId: json['rowId'] as String?,
        driverId: json['driverId'] as String?,
        name: json['name'] as String? ?? '',
        pending: json['status'] == 'PENDING',
        saved: json['saved'] as bool? ?? false,
        createdByCompany: json['createdByCompany'] as bool? ?? false,
        fromDeals: json['fromDeals'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        avatarVersion: json['avatarVersion'] as String?,
        lastSeenAt: json['lastSeenAt'] == null ? null : DateTime.parse(json['lastSeenAt'] as String),
        searching: json['searching'] as bool? ?? false,
        onSite: json['onSite'] as bool? ?? false,
      );
}

/// 058 п.6: «Компании, где я в списке» у водителя; `pending` — приглашение
/// «Компания X добавила вас» ждёт «Принять» / «Отказаться».
class DriverCompanyEntry {
  const DriverCompanyEntry({required this.companyId, required this.companyName, this.pending = false});

  final String companyId;
  final String companyName;
  final bool pending;

  factory DriverCompanyEntry.fromJson(Map<String, dynamic> json) => DriverCompanyEntry(
        companyId: json['companyId'] as String,
        companyName: json['companyName'] as String? ?? '',
        pending: json['status'] == 'PENDING',
      );
}

/// Результат «Создать водителя».
enum CreateDriverResult { created, invitedExisting, alreadyInList }

CreateDriverResult createDriverResultFromJson(String? value) => switch (value) {
      'INVITED_EXISTING' => CreateDriverResult.invitedExisting,
      'ALREADY_IN_LIST' => CreateDriverResult.alreadyInList,
      _ => CreateDriverResult.created,
    };
