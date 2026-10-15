import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'api_providers.dart';

/// 078 (decisions.md «Сначала показать, потом обновить»): экран открывается из
/// сохранённого на телефоне мгновенно, свежее подтягивается следом; без связи
/// остаётся сохранённое.
Stream<T> _cached<T>(Ref ref, String path, T Function(Object? data) parse, Future<T> Function() fetch, {Map<String, dynamic>? query}) =>
    cacheFirst(ref.watch(apiClientProvider), path, query: query, parse: parse, fetch: fetch);

List<T> _list<T>(Object? data, T Function(Map<String, dynamic> json) fromJson) =>
    [for (final e in data as List<dynamic>) fromJson(e as Map<String, dynamic>)];

/// 078: лента показана из сохранённого старше часа — пометка «обновляется».
final feedFromCacheAtProvider = StateProvider<DateTime?>((ref) => null);

/// Первая страница ленты водителя; порядок и отсев — на сервере (040, п.5).
/// 059: фильтр и сортировка ленты — запоминается на устройстве.
class FeedFilterNotifier extends StateNotifier<FeedFilter> {
  FeedFilterNotifier(this._store) : super(FeedFilter.empty) {
    // Хранилище не ответило за 2 с — лента не ждёт, фильтр пустой.
    ready = _store.load().timeout(const Duration(seconds: 2), onTimeout: () => FeedFilter.empty).then((saved) {
      if (mounted && state == FeedFilter.empty) state = saved;
    });
  }

  /// 064 п.10: сохранённый фильтр прочитан — лента при старте ждёт его и
  /// уходит одним запросом (а не «пустой» + «сохранённый»).
  late final Future<void> ready;

  final FeedFilterStore _store;

  void set(FeedFilter value) {
    state = value;
    _store.save(value);
  }
}

/// Хранилище фильтра (подменяется в тестах).
final feedFilterStoreProvider = Provider<FeedFilterStore>((ref) => FeedFilterStore());

final feedFilterProvider = StateNotifierProvider<FeedFilterNotifier, FeedFilter>((ref) => FeedFilterNotifier(ref.watch(feedFilterStoreProvider)));

final cargoFeedProvider = StreamProvider.autoDispose<CargoFeedPage>((ref) async* {
  // Сначала — сохранённый фильтр, потом подписка на него: один запрос при старте.
  await ref.read(feedFilterProvider.notifier).ready;
  // Все обращения к ref — здесь, до следующих await: фильтр могут сменить,
  // пока идёт запрос, и ref после этого трогать нельзя.
  final filter = ref.watch(feedFilterProvider);
  final repo = ref.watch(cargoRepositoryProvider);
  final api = ref.watch(apiClientProvider);
  final fromCacheAt = ref.read(feedFromCacheAtProvider.notifier);
  // 078: сохранённая лента — не старше 6 ч (CachePolicy); старше часа — с
  // пометкой «обновляется», пока не пришла свежая.
  final cached = await api.peek('/cargos', query: {'limit': 30, 'offset': 0, ...filter.toQuery()});
  if (cached != null) {
    try {
      final page = CargoFeedPage.fromJson(cached.data as Map<String, dynamic>);
      if (cached.age > const Duration(hours: 1)) fromCacheAt.state = cached.savedAt;
      yield page;
    } catch (_) {}
  }
  CargoFeedPage? fresh;
  try {
    fresh = await repo.feed(filter: filter);
  } catch (_) {
    if (cached == null) rethrow;
  }
  if (fresh != null) {
    fromCacheAt.state = null;
    yield fresh;
  }
});

/// «Помещается к текущему» (040, п.6): есть только у водителя с активной сделкой.
final partialHintProvider = FutureProvider.autoDispose.family<PartialHint?, String>((ref, cargoId) {
  return ref.watch(cargoRepositoryProvider).partialHint(cargoId);
});

final myCargosProvider = StreamProvider.autoDispose<List<Cargo>>((ref) {
  return _cached(ref, '/cargos/mine', (d) => _list(d, Cargo.fromJson), () => ref.watch(cargoRepositoryProvider).mine());
});

/// Мой отклик на груз — состояние кнопки в карточке водителя (041).
final myCargoResponseProvider = StreamProvider.autoDispose.family<MyCargoResponse?, String>((ref, cargoId) {
  return _cached(ref, '/cargos/$cargoId/my-response', (d) => (d as Map<String, dynamic>)['response'] == null ? null : MyCargoResponse.fromJson(d['response'] as Map<String, dynamic>), () => ref.watch(cargoRepositoryProvider).myResponse(cargoId));
});

final cargoByIdProvider = StreamProvider.autoDispose.family<Cargo, String>((ref, id) {
  return _cached(ref, '/cargos/$id', (d) => Cargo.fromJson(d as Map<String, dynamic>), () => ref.watch(cargoRepositoryProvider).byId(id));
});

final cargoResponsesProvider = StreamProvider.autoDispose.family<List<CargoResponse>, String>((ref, cargoId) {
  return _cached(ref, '/cargos/$cargoId/responses', (d) => _list(d, CargoResponse.fromJson), () => ref.watch(cargoRepositoryProvider).responsesFor(cargoId));
});

final dealsMineProvider = StreamProvider.autoDispose<List<Deal>>((ref) {
  return _cached(ref, '/deals/mine', (d) => _list(d, Deal.fromJson), () => ref.watch(dealRepositoryProvider).mine());
});

final dealByIdProvider = StreamProvider.autoDispose.family<Deal, String>((ref, id) {
  return _cached(ref, '/deals/$id', (d) => Deal.fromJson(d as Map<String, dynamic>), () => ref.watch(dealRepositoryProvider).byId(id));
});

final reviewsForDealProvider = FutureProvider.autoDispose.family<List<Review>, String>((ref, dealId) {
  return ref.watch(reviewRepositoryProvider).forDeal(dealId);
});

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  return _cached(ref, '/chats/$chatId/messages', (d) => _list(d, ChatMessage.fromJson), () => ref.watch(chatRepositoryProvider).messages(chatId));
});

final chatThreadProvider = StreamProvider.autoDispose.family<ChatThread, String>((ref, chatId) {
  return _cached(ref, '/chats/$chatId', (d) => ChatThread.fromJson(d as Map<String, dynamic>), () => ref.watch(chatRepositoryProvider).thread(chatId));
});

/// Мои чаты (задача 017, п.1) — вкладка «Чаты» у водителя и логиста.
final myChatsProvider = StreamProvider.autoDispose<List<MyChatEntry>>((ref) {
  return _cached(ref, '/chats', (d) => _list(d, MyChatEntry.fromJson), () => ref.watch(chatRepositoryProvider).myChats());
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

/// Мои активные анонсы (040: их может быть несколько).
final myArrivalsProvider = StreamProvider.autoDispose<MyArrivals>((ref) {
  return _cached(ref, '/arrivals/me', ArrivalRepository.parseMine, () => ref.watch(arrivalRepositoryProvider).mine());
});

final arrivalTemplateProvider = FutureProvider.autoDispose<ArrivalTemplate?>((ref) {
  return ref.watch(arrivalRepositoryProvider).lastTemplate();
});

final driverVerificationDocumentsProvider = StreamProvider.autoDispose<List<VerificationDocument>>((ref) {
  return _cached(ref, '/drivers/me/verification-documents', (d) => _list(d, VerificationDocument.fromJson), () => ref.watch(driverRepositoryProvider).verificationDocuments());
});

/// Блок «Распознано» под документом (задача 031, п.25).
final driverDocumentRecognitionProvider = FutureProvider.autoDispose.family<AdminDocumentRecognition, String>((ref, documentId) {
  return ref.watch(driverRepositoryProvider).documentRecognition(documentId);
});

/// Гараж (задача 031, этап B) — тягачи и прицепы водителя.
final garageVehiclesProvider = StreamProvider.autoDispose<List<GarageVehicle>>((ref) {
  return _cached(ref, '/drivers/me/vehicles', (d) => _list(d, GarageVehicle.fromJson), () => ref.watch(driverRepositoryProvider).vehicles());
});

final devicesProvider = FutureProvider.autoDispose<List<DeviceSession>>((ref) {
  return ref.watch(authRepositoryProvider).listSessions();
});

/// 058 п.8: избранные грузы водителя (☆ в ленте и карточке, раздел в «Моих рейсах»).
final favoriteCargosProvider = StreamProvider.autoDispose<List<Cargo>>((ref) {
  return _cached(ref, '/cargos/favorites', (d) => _list(d, Cargo.fromJson), () => ref.watch(cargoRepositoryProvider).favorites());
});

/// 058 п.6: «Мои водители» компании.
final myDriversProvider = StreamProvider.autoDispose<List<CompanyDriverEntry>>((ref) {
  return _cached(ref, '/company-drivers', (d) => _list(d, CompanyDriverEntry.fromJson), () => ref.watch(companyDriversRepositoryProvider).mine());
});

/// 058 п.6: «Компании, где я в списке» и приглашения водителю.
final driverCompaniesProvider = FutureProvider.autoDispose<List<DriverCompanyEntry>>((ref) {
  return ref.watch(companyDriversRepositoryProvider).myCompanies();
});

