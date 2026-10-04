import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'api_providers.dart';

final verificationDocumentsProvider = FutureProvider.autoDispose<List<AdminVerificationDocument>>((ref) {
  return ref.watch(adminRepositoryProvider).verificationDocuments(status: 'PENDING');
});

final complaintsProvider = FutureProvider.autoDispose<List<AdminComplaint>>((ref) {
  return ref.watch(adminRepositoryProvider).complaints(status: 'OPEN');
});

/// Параметры поиска/фильтра/пагинации (задача 026) — record, не класс:
/// Riverpod сравнивает family-параметры по равенству, а записи уже имеют
/// value-equality из коробки. `onSite` — только для водителей (плитка
/// «на точке» на сводке, задача 028 п.3), у компаний всегда null.
typedef AdminSearchQuery = ({String q, bool? verified, bool? blocked, String? onSite, int page});

const defaultAdminSearchQuery = (q: '', verified: null, blocked: null, onSite: null, page: 1);

final adminCompaniesSearchProvider =
    FutureProvider.autoDispose.family<AdminSearchPage<AdminCompanyRow>, AdminSearchQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).searchCompanies(
        q: query.q,
        verified: query.verified,
        blocked: query.blocked,
        page: query.page,
      );
});

final adminDriversSearchProvider =
    FutureProvider.autoDispose.family<AdminSearchPage<AdminDriverRow>, AdminSearchQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).searchDrivers(
        q: query.q,
        verified: query.verified,
        blocked: query.blocked,
        onSite: query.onSite,
        page: query.page,
      );
});

final adminDriverDetailProvider = FutureProvider.autoDispose.family<AdminDriverDetail, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).driverDetail(id);
});

final adminCompanyDetailProvider = FutureProvider.autoDispose.family<AdminCompanyDetail, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).companyDetail(id);
});

final pendingCitiesProvider = FutureProvider.autoDispose<List<AdminPendingCity>>((ref) {
  return ref.watch(adminRepositoryProvider).pendingCities();
});

// -- задача 028: сводка-пульт, грузы, сделки --------------------------------

final adminStatsPeriodProvider = StateProvider<String>((ref) => 'today');

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  final period = ref.watch(adminStatsPeriodProvider);
  return ref.watch(adminRepositoryProvider).stats(period: period);
});

final adminAttentionProvider = FutureProvider.autoDispose<AdminAttention>((ref) {
  return ref.watch(adminRepositoryProvider).attention();
});

final adminRecentEventsProvider = FutureProvider.autoDispose<List<AdminEvent>>((ref) {
  return ref.watch(adminRepositoryProvider).recentEvents();
});

final adminGlobalSearchProvider = FutureProvider.autoDispose.family<AdminSearchResults, String>((ref, q) {
  return ref.watch(adminRepositoryProvider).search(q);
});

typedef AdminCargoQuery = ({String q, String? status, String? companyId, String? destinationCountryId, int page});
const defaultAdminCargoQuery = (q: '', status: null, companyId: null, destinationCountryId: null, page: 1);

final adminCargosSearchProvider =
    FutureProvider.autoDispose.family<AdminSearchPage<AdminCargoRow>, AdminCargoQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).searchCargos(
        q: query.q,
        status: query.status,
        companyId: query.companyId,
        destinationCountryId: query.destinationCountryId,
        page: query.page,
      );
});

typedef AdminDealQuery = ({String q, String? status, bool stale, String? driverId, String? companyId, int page});
const defaultAdminDealQuery = (q: '', status: null, stale: false, driverId: null, companyId: null, page: 1);

final adminDealsSearchProvider =
    FutureProvider.autoDispose.family<AdminSearchPage<AdminDealRow>, AdminDealQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).searchDeals(
        q: query.q,
        status: query.status,
        stale: query.stale,
        driverId: query.driverId,
        companyId: query.companyId,
        page: query.page,
      );
});

final adminAuditLogProvider = FutureProvider.autoDispose<List<AdminAuditLogEntry>>((ref) {
  return ref.watch(adminRepositoryProvider).auditLog();
});

final adminSettingsProvider = FutureProvider.autoDispose<Map<String, String>>((ref) {
  return ref.watch(adminRepositoryProvider).settings();
});
