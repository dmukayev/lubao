import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'api_providers.dart';

final cargoFeedProvider = FutureProvider.autoDispose<List<Cargo>>((ref) {
  return ref.watch(cargoRepositoryProvider).feed();
});

final myCargosProvider = FutureProvider.autoDispose<List<Cargo>>((ref) {
  return ref.watch(cargoRepositoryProvider).mine();
});

final cargoByIdProvider = FutureProvider.autoDispose.family<Cargo, String>((ref, id) {
  return ref.watch(cargoRepositoryProvider).byId(id);
});

final cargoResponsesProvider = FutureProvider.autoDispose.family<List<CargoResponse>, String>((ref, cargoId) {
  return ref.watch(cargoRepositoryProvider).responsesFor(cargoId);
});

final dealsMineProvider = FutureProvider.autoDispose<List<Deal>>((ref) {
  return ref.watch(dealRepositoryProvider).mine();
});

final dealByIdProvider = FutureProvider.autoDispose.family<Deal, String>((ref, id) {
  return ref.watch(dealRepositoryProvider).byId(id);
});

final reviewsForDealProvider = FutureProvider.autoDispose.family<List<Review>, String>((ref, dealId) {
  return ref.watch(reviewRepositoryProvider).forDeal(dealId);
});

final chatMessagesProvider = FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, dealId) {
  return ref.watch(chatRepositoryProvider).messages(dealId);
});

final chatThreadProvider = FutureProvider.autoDispose.family<ChatThread, String>((ref, dealId) {
  return ref.watch(chatRepositoryProvider).threadForDeal(dealId);
});

final companyMembersProvider = FutureProvider.autoDispose<List<CompanyMember>>((ref) {
  return ref.watch(companyRepositoryProvider).members();
});

final myArrivalProvider = FutureProvider.autoDispose<Arrival?>((ref) {
  return ref.watch(arrivalRepositoryProvider).mine();
});

final driverVerificationDocumentsProvider = FutureProvider.autoDispose<List<VerificationDocument>>((ref) {
  return ref.watch(driverRepositoryProvider).verificationDocuments();
});
