import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'api_providers.dart';

/// Тип очереди «Проверка целиком» — водители/компании (задача 028, п.7).
final adminVerificationTypeProvider = StateProvider.autoDispose<String>((ref) => 'driver');

/// Выбранный в очереди субъект — сохраняется при переключении типа, пока
/// явно не выбрали другого (экран сам решает, что показать при null).
final adminVerificationSelectedIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final adminVerificationQueueProvider = FutureProvider.autoDispose.family<List<AdminVerificationQueueItem>, String>((ref, type) {
  return ref.watch(adminRepositoryProvider).verificationQueue(type);
});

final adminVerificationDriverProfileProvider = FutureProvider.autoDispose.family<AdminVerificationDriverProfile, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).verificationDriverProfile(id);
});

final adminVerificationCompanyProfileProvider = FutureProvider.autoDispose.family<AdminVerificationCompanyProfile, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).verificationCompanyProfile(id);
});

/// Блок «Распознано» (задача 031, п.22) — отдельно от профиля, подгружается
/// только для открытого в данный момент документа.
final adminDocumentRecognitionProvider = FutureProvider.autoDispose.family<AdminDocumentRecognition, String>((ref, documentId) {
  return ref.watch(adminRepositoryProvider).documentRecognition(documentId);
});

/// Вкладка очереди жалоб — NEW/IN_REVIEW/CLOSED (задача 028, п.24a).
final adminComplaintsTabProvider = StateProvider.autoDispose<String>((ref) => 'NEW');

/// «Мои» — только назначенные на текущего админа (п.24a).
final adminComplaintsMineProvider = StateProvider.autoDispose<bool>((ref) => false);

final adminComplaintSelectedIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final complaintsProvider = FutureProvider.autoDispose<List<AdminComplaint>>((ref) {
  final tab = ref.watch(adminComplaintsTabProvider);
  final mine = ref.watch(adminComplaintsMineProvider);
  return ref.watch(adminRepositoryProvider).complaints(tab: tab, mine: mine);
});

final adminComplaintCountsProvider = FutureProvider.autoDispose<({int newCount, int inReviewCount, int closedCount})>((ref) {
  return ref.watch(adminRepositoryProvider).complaintCounts();
});

final adminComplaintDetailProvider = FutureProvider.autoDispose.family<AdminComplaintDetail, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).complaintDetail(id);
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

/// Разрез сводки по городам (040, п.9).
final adminCityStatsProvider = FutureProvider.autoDispose<List<CityStatsRow>>((ref) {
  return ref.watch(adminRepositoryProvider).statsByCity();
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

typedef AdminDealQuery = ({String q, String? status, bool? stale, String? driverId, String? companyId, int page});
const defaultAdminDealQuery = (q: '', status: null, stale: null, driverId: null, companyId: null, page: 1);

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

final adminCargoDetailProvider = FutureProvider.autoDispose.family<AdminCargoDetail, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).cargoDetail(id);
});

final adminDealDetailProvider = FutureProvider.autoDispose.family<AdminDealDetail, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).dealDetail(id);
});

/// Переписка подгружается только по явному открытию вкладки (п.17 — каждое
/// открытие пишется в audit_log на бэкенде), а не вместе с карточкой сделки
/// — поэтому отдельный provider, не часть [adminDealDetailProvider].
final adminDealChatProvider = FutureProvider.autoDispose.family<List<AdminChatMessage>, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).dealChat(id);
});

final adminSettingsProvider = FutureProvider.autoDispose<Map<String, String>>((ref) {
  return ref.watch(adminRepositoryProvider).settings();
});

final adminTranslationStatsProvider = FutureProvider.autoDispose<AdminTranslationStats>((ref) {
  return ref.watch(adminRepositoryProvider).translationStats();
});
