import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

String _defaultBaseUrl() {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(baseUrl: _defaultBaseUrl()));

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final referenceDataRepositoryProvider = Provider((ref) => ReferenceDataRepository(ref.watch(apiClientProvider)));
final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.watch(apiClientProvider)));

final referenceDataProvider = FutureProvider<ReferenceData>((ref) {
  return ref.watch(referenceDataRepositoryProvider).fetch();
});
