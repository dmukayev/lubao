import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

/// На физическом устройстве (не симулятор/эмулятор) "localhost" указывает
/// на само устройство, а не на Mac с бэкендом — поэтому базовый URL можно
/// переопределить: `flutter run --dart-define=API_BASE_URL=http://<lan-ip>:3000`.
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String _defaultBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl: _defaultBaseUrl()));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final referenceDataRepositoryProvider = Provider((ref) => ReferenceDataRepository(ref.watch(apiClientProvider)));
final driverRepositoryProvider = Provider((ref) => DriverRepository(ref.watch(apiClientProvider)));
final companyRepositoryProvider = Provider((ref) => CompanyRepository(ref.watch(apiClientProvider)));
final cargoRepositoryProvider = Provider((ref) => CargoRepository(ref.watch(apiClientProvider)));
final dealRepositoryProvider = Provider((ref) => DealRepository(ref.watch(apiClientProvider)));
final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(apiClientProvider)));
final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref.watch(apiClientProvider)));
final uploadsRepositoryProvider = Provider((ref) => UploadsRepository(ref.watch(apiClientProvider)));
final arrivalRepositoryProvider = Provider((ref) => ArrivalRepository(ref.watch(apiClientProvider)));
final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(baseUrl: _defaultBaseUrl());
  ref.onDispose(service.disconnect);
  return service;
});

final referenceDataProvider = FutureProvider<ReferenceData>((ref) {
  return ref.watch(referenceDataRepositoryProvider).fetch();
});
