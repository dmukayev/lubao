import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../services/data_cache_store.dart';

/// На физическом устройстве (не симулятор/эмулятор) "localhost" указывает
/// на само устройство, а не на Mac с бэкендом — поэтому базовый URL можно
/// переопределить: `flutter run --dart-define=API_BASE_URL=http://<lan-ip>:3000`.
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Публичный адрес приложения для ссылок-приглашений (https, не lubao://).
const appPublicUrl = String.fromEnvironment('APP_PUBLIC_URL', defaultValue: 'https://app.lubao.kz');

String _defaultBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

/// 078: ответы сервера сохраняются на телефоне — «сначала показать, потом обновить».
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl: _defaultBaseUrl())..cacheStore = DataCacheStore());

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final referenceDataRepositoryProvider = Provider((ref) => ReferenceDataRepository(ref.watch(apiClientProvider)));
final driverRepositoryProvider = Provider((ref) => DriverRepository(ref.watch(apiClientProvider)));
final companyRepositoryProvider = Provider((ref) => CompanyRepository(ref.watch(apiClientProvider)));
/// 058 п.6: «Мои водители» / «Компании, где я в списке».
final companyDriversRepositoryProvider = Provider((ref) => CompanyDriversRepository(ref.watch(apiClientProvider)));
final cargoRepositoryProvider = Provider((ref) => CargoRepository(ref.watch(apiClientProvider)));
final dealRepositoryProvider = Provider((ref) => DealRepository(ref.watch(apiClientProvider)));
final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(apiClientProvider)));
final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref.watch(apiClientProvider)));
final uploadsRepositoryProvider = Provider((ref) => UploadsRepository(ref.watch(apiClientProvider)));
/// 052: короткие ссылки «Поделиться».
final shareRepositoryProvider = Provider((ref) => ShareRepository(ref.watch(apiClientProvider)));
final arrivalRepositoryProvider = Provider((ref) => ArrivalRepository(ref.watch(apiClientProvider)));
final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(baseUrl: _defaultBaseUrl(), apiClient: ref.watch(apiClientProvider));
  ref.onDispose(service.disconnect);
  return service;
});

/// 078: справочники — из сохранённого сразу, свежие — в фоне.
final referenceDataProvider = StreamProvider<ReferenceData>((ref) {
  return cacheFirst(ref.watch(apiClientProvider), '/reference-data',
      parse: ReferenceDataRepository.parse, fetch: () => ref.watch(referenceDataRepositoryProvider).fetch());
});
