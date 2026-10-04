import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'api_providers.dart';

final statsProvider = FutureProvider.autoDispose<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).stats();
});

final verificationDocumentsProvider = FutureProvider.autoDispose<List<AdminVerificationDocument>>((ref) {
  return ref.watch(adminRepositoryProvider).verificationDocuments(status: 'PENDING');
});

final complaintsProvider = FutureProvider.autoDispose<List<AdminComplaint>>((ref) {
  return ref.watch(adminRepositoryProvider).complaints(status: 'OPEN');
});

/// Параметры поиска/фильтра/пагинации (задача 026) — record, не класс:
/// Riverpod сравнивает family-параметры по равенству, а записи уже имеют
/// value-equality из коробки.
typedef AdminSearchQuery = ({String q, bool? verified, bool? blocked, int page});

const defaultAdminSearchQuery = (q: '', verified: null, blocked: null, page: 1);

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
