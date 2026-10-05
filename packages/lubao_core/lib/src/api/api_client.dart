import 'dart:async';
import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  /// [refreshDio] — только для тестов (024 п.1): подменить сетевой слой
  /// только для /auth/refresh, не трогая основной [dio].
  ApiClient({required String baseUrl, TokenStorage? tokenStorage, Dio? refreshDio})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))),
        _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))),
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

  /// Для RealtimeService (задача 029, п.10): сокет может протухнуть
  /// (access живёт 15 мин — токен из 006) без единого обычного HTTP-
  /// запроса между делом, который сам обновил бы токен через интерсептор
  /// `_onError`. Тот же "один в полёте" refresh, что и у HTTP-слоя — два
  /// параллельных вызова (HTTP 401 и socket connect_error) не плодят два
  /// запроса на обновление.
  Future<String?> refreshAccessToken() => _refreshAccessToken();

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
    } on DioException catch (e) {
      // Разлогин — только если сервер явно ответил 401/403 (refresh-токен
      // отозван/просрочен/обнаружено повторное использование). Любая другая
      // ошибка — не долетело до сервера, таймаут, 5xx — не повод выкидывать
      // водителя на границе без связи из приложения (024 п.1): токены
      // остаются на месте, следующий запрос попробует refresh заново.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await tokenStorage.clear();
        _sessionExpiredController.add(null);
      }
      return null;
    }
  }

  Future<void> logoutLocally() => tokenStorage.clear();
}
