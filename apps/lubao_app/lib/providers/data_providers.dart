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

final chatMessagesProvider = FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).messages(chatId);
});

final chatThreadProvider = FutureProvider.autoDispose.family<ChatThread, String>((ref, chatId) {
  return ref.watch(chatRepositoryProvider).thread(chatId);
});

/// Мои чаты (задача 017, п.1) — вкладка «Чаты» у водителя и логиста.
final myChatsProvider = FutureProvider.autoDispose<List<MyChatEntry>>((ref) {
  return ref.watch(chatRepositoryProvider).myChats();
});

/// Кандидаты на «Нашёл в Lubao» при закрытии груза (п.6).
final cargoCloseCandidatesProvider = FutureProvider.autoDispose.family<List<CargoCloseCandidate>, String>((ref, cargoId) {
  return ref.watch(cargoRepositoryProvider).closeCandidates(cargoId);
});

final companyMembersProvider = FutureProvider.autoDispose<List<CompanyMember>>((ref) {
  return ref.watch(companyRepositoryProvider).members();
});

/// Единственный документ, подтверждающий компанию (задача 012, п.5).
final companyVerificationDocumentsProvider = FutureProvider.autoDispose<List<VerificationDocument>>((ref) {
  return ref.watch(companyRepositoryProvider).verificationDocuments();
});

final myArrivalProvider = FutureProvider.autoDispose<Arrival?>((ref) {
  return ref.watch(arrivalRepositoryProvider).mine();
});

final arrivalTemplateProvider = FutureProvider.autoDispose<ArrivalTemplate?>((ref) {
  return ref.watch(arrivalRepositoryProvider).lastTemplate();
});

final driverVerificationDocumentsProvider = FutureProvider.autoDispose<List<VerificationDocument>>((ref) {
  return ref.watch(driverRepositoryProvider).verificationDocuments();
});

/// Блок «Распознано» под документом (задача 031, п.25).
final driverDocumentRecognitionProvider = FutureProvider.autoDispose.family<AdminDocumentRecognition, String>((ref, documentId) {
  return ref.watch(driverRepositoryProvider).documentRecognition(documentId);
});

/// Гараж (задача 031, этап B) — тягачи и прицепы водителя.
final garageVehiclesProvider = FutureProvider.autoDispose<List<GarageVehicle>>((ref) {
  return ref.watch(driverRepositoryProvider).vehicles();
});

final devicesProvider = FutureProvider.autoDispose<List<DeviceSession>>((ref) {
  return ref.watch(authRepositoryProvider).listSessions();
});
