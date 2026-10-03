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

final adminCompaniesProvider = FutureProvider.autoDispose<List<AdminCompanySummary>>((ref) {
  return ref.watch(adminRepositoryProvider).companies();
});

final adminDriversProvider = FutureProvider.autoDispose<List<AdminDriverSummary>>((ref) {
  return ref.watch(adminRepositoryProvider).drivers();
});
