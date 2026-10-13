import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../offline/response_cache.dart';
import 'token_storage.dart';

class ApiClient {
  /// [refreshDio] — только для тестов (024 п.1): подменить сетевой слой
  /// только для /auth/refresh, не трогая основной [dio].
  ApiClient({required String baseUrl, TokenStorage? tokenStorage, Dio? refreshDio})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20))),
        _refreshDio = refreshDio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20))),
        tokenStorage = tokenStorage ?? TokenStorage() {
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onResponse: _onResponse, onError: _onError));
  }

  // --- 078: «сначала показать, потом обновить», режим без связи -------------

  /// Хранилище ответов (в приложении — файлы на диске).
  CacheStore cacheStore = MemoryCacheStore();

  /// Чей кэш — id пользователя; нет сессии — не кэшируем.
  String? cacheScope;

  /// Нет связи с сервером: последний запрос не долетел. Любой ответ — снова есть.
  final offline = ValueNotifier<bool>(false);

  /// e2e: «выключить сеть» — запросы падают, как без связи.
  bool simulateOffline = false;

  /// e2e: журнал запросов «МЕТОД путь» — проверить, что повторно не ходим.
  final requestLog = <String>[];

  /// Изменений (POST/PATCH/…) за этот запуск; после изменения сохранённое
  /// показываем только если оно уже обновлено после него — без мигания старым.
  int _mutations = 0;
  final _freshKeys = <String>{};

  static bool isConnectivityError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      (e.type == DioExceptionType.unknown && e.response == null);

  /// Сохранённый ответ для мгновенного показа (или null: нет, устарел, чужой).
  Future<CachedResponse?> peek(String path, {Map<String, dynamic>? query}) async {
    final scope = cacheScope;
    final policy = CachePolicy.forPath(path);
    if (scope == null || policy == null) return null;
    final key = cacheKey(scope, path, query);
    if (_mutations > 0 && !_freshKeys.contains(key)) return null;
    final raw = await cacheStore.read(key);
    final cached = raw == null ? null : CachedResponse.decode(raw);
    if (cached == null || cached.age > policy.maxAge) return null;
    return cached;
  }

  /// Выход / смена пользователя — всё сохранённое стереть.
  Future<void> clearCache() async {
    _freshKeys.clear();
    await cacheStore.clear();
  }

  Future<void> _onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (response.requestOptions.extra['fromCache'] != true) offline.value = false;
    final options = response.requestOptions;
    final status = response.statusCode ?? 0;
    if (options.method != 'GET') {
      if (status >= 200 && status < 300) {
        _mutations++;
        _freshKeys.clear();
      }
    } else if (status == 200 && options.extra['fromCache'] != true) {
      final scope = cacheScope;
      final policy = CachePolicy.forPath(options.path);
      if (scope != null && policy != null) {
        final key = cacheKey(scope, options.path, options.queryParameters);
        var data = stripPhones(response.data);
        final keep = policy.keepLast;
        if (keep != null && data is List && data.length > keep) data = data.sublist(data.length - keep);
        _freshKeys.add(key);
        unawaited(cacheStore.write(key, CachedResponse(data, DateTime.now()).encode()).catchError((Object _) {}));
      }
    }
    handler.next(response);
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
    if (kDebugMode) requestLog.add('${options.method} ${options.path}');
    if (simulateOffline) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError, message: 'e2e: offline'), true);
      return;
    }
    final token = await tokenStorage.readAccess();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    // 078: нет связи — показать сохранённое (если есть), поднять флаг «нет связи».
    if (isConnectivityError(error)) {
      offline.value = true;
      final options = error.requestOptions;
      final scope = cacheScope;
      if (options.method == 'GET' && scope != null && CachePolicy.forPath(options.path) != null) {
        final raw = await cacheStore.read(cacheKey(scope, options.path, options.queryParameters));
        final cached = raw == null ? null : CachedResponse.decode(raw);
        if (cached != null) {
          handler.resolve(Response(requestOptions: options..extra['fromCache'] = true, data: cached.data, statusCode: 200));
          return;
        }
      }
      handler.next(error);
      return;
    }
    // 073: 401 от самого входа (неверный пароль, код) — это ответ, а не
    // истёкшая сессия: не обновляем токен и не подменяем ошибку (раньше чтение
    // токена в браузере по http падало, и вместо «Неверный пароль» было
    // «Что-то пошло не так»).
    final isAuthRoute = isLoginPath(error.requestOptions.path);
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

  /// Запросы входа и обновления токена — ошибки отдаются как есть.
  static bool isLoginPath(String path) {
    const prefixes = ['/auth/refresh', '/auth/company/login', '/auth/company/register', '/auth/company/forgot-password', '/auth/company/reset-password', '/auth/admin/login', '/auth/phone/', '/auth/telegram/'];
    return prefixes.any(path.startsWith);
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
