import 'dart:async';
import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({required String baseUrl, TokenStorage? tokenStorage})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))),
        _refreshDio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))),
        tokenStorage = tokenStorage ?? TokenStorage() {
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  final Dio dio;

  /// Отдельный Dio без интерсептора — используется только для самого
  /// /auth/refresh, чтобы не уйти в рекурсию через тот же onError.
  final Dio _refreshDio;

  final TokenStorage tokenStorage;

  /// Единственный "в полёте" refresh — конкурентные 401 ждут один и тот же
  /// Future, а не плодят параллельные запросы обновления токена.
  Future<String?>? _refreshing;

  final _sessionExpiredController = StreamController<void>.broadcast();

  /// Срабатывает, когда refresh не удался (токен отозван/просрочен) —
  /// приложение должно разлогинить пользователя.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final isAuthRoute = error.requestOptions.path.startsWith('/auth/refresh');
    if (error.response?.statusCode != 401 || isAuthRoute) {
      handler.next(error);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      handler.next(error);
      return;
    }

    try {
      final retried = await dio.fetch(error.requestOptions..headers['Authorization'] = 'Bearer $newAccessToken');
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenStorage.readRefresh();
    if (refreshToken == null) return null;

    try {
      final res = await _refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = res.data as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      await tokenStorage.save(accessToken, newRefreshToken);
      return accessToken;
    } catch (_) {
      await tokenStorage.clear();
      _sessionExpiredController.add(null);
      return null;
    }
  }

  Future<void> logoutLocally() => tokenStorage.clear();
}
