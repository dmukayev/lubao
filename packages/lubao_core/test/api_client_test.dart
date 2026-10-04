import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/src/api/api_client.dart';
import 'package:lubao_core/src/api/token_storage.dart';

/// Не трогает flutter_secure_storage/платформенные каналы — просто
/// хранилище в памяти, как и заявлено в конструкторе ApiClient
/// (tokenStorage инъектируется ради тестируемости).
class _FakeTokenStorage extends TokenStorage {
  String? access;
  String? refresh;

  @override
  Future<void> save(String accessToken, String refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

/// Dio с единственным перехватчиком — отвечает на любой запрос заданной
/// ошибкой/ответом, не трогая сеть. Используется только как [refreshDio].
Dio _dioThatAlwaysThrows(DioExceptionType type, {int? statusCode}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    handler.reject(DioException(
      requestOptions: options,
      type: type,
      response: statusCode == null ? null : Response(requestOptions: options, statusCode: statusCode),
    ));
  }));
  return dio;
}

Dio _dioThatSucceeds({required String accessToken, required String refreshToken}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: {'accessToken': accessToken, 'refreshToken': refreshToken},
    ));
  }));
  return dio;
}

void main() {
  // 024 п.1: при сетевой ошибке /auth/refresh водителя нельзя разлогинивать —
  // он мог просто оказаться без связи на границе. Разлогин — только если
  // сервер явно ответил 401/403 (токен отозван/просрочен).
  group('ApiClient — refresh и сетевые ошибки (024 п.1)', () {
    test('refresh падает с connectionError (нет сети) → токены на месте, onSessionExpired не сработал', () async {
      final storage = _FakeTokenStorage()
        ..access = 'old-access'
        ..refresh = 'old-refresh';
      final client = ApiClient(
        baseUrl: 'http://test',
        tokenStorage: storage,
        refreshDio: _dioThatAlwaysThrows(DioExceptionType.connectionError),
      );

      var sessionExpiredFired = false;
      client.onSessionExpired.listen((_) => sessionExpiredFired = true);

      await _forceRefresh(client);

      expect(storage.access, 'old-access');
      expect(storage.refresh, 'old-refresh');
      expect(sessionExpiredFired, isFalse);
    });

    test('refresh падает с таймаутом → токены на месте, onSessionExpired не сработал', () async {
      final storage = _FakeTokenStorage()
        ..access = 'old-access'
        ..refresh = 'old-refresh';
      final client = ApiClient(
        baseUrl: 'http://test',
        tokenStorage: storage,
        refreshDio: _dioThatAlwaysThrows(DioExceptionType.connectionTimeout),
      );

      var sessionExpiredFired = false;
      client.onSessionExpired.listen((_) => sessionExpiredFired = true);

      await _forceRefresh(client);

      expect(storage.access, 'old-access');
      expect(storage.refresh, 'old-refresh');
      expect(sessionExpiredFired, isFalse);
    });

    test('refresh падает с 5xx → токены на месте, onSessionExpired не сработал', () async {
      final storage = _FakeTokenStorage()
        ..access = 'old-access'
        ..refresh = 'old-refresh';
      final client = ApiClient(
        baseUrl: 'http://test',
        tokenStorage: storage,
        refreshDio: _dioThatAlwaysThrows(DioExceptionType.badResponse, statusCode: 503),
      );

      var sessionExpiredFired = false;
      client.onSessionExpired.listen((_) => sessionExpiredFired = true);

      await _forceRefresh(client);

      expect(storage.access, 'old-access');
      expect(storage.refresh, 'old-refresh');
      expect(sessionExpiredFired, isFalse);
    });

    test('сервер отвечает 401 на /auth/refresh (токен реально отозван) → токены очищены, onSessionExpired сработал', () async {
      final storage = _FakeTokenStorage()
        ..access = 'old-access'
        ..refresh = 'old-refresh';
      final client = ApiClient(
        baseUrl: 'http://test',
        tokenStorage: storage,
        refreshDio: _dioThatAlwaysThrows(DioExceptionType.badResponse, statusCode: 401),
      );

      var sessionExpiredFired = false;
      client.onSessionExpired.listen((_) => sessionExpiredFired = true);

      await _forceRefresh(client);

      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
      expect(sessionExpiredFired, isTrue);
    });

    test('успешный refresh сохраняет новую пару токенов', () async {
      final storage = _FakeTokenStorage()
        ..access = 'old-access'
        ..refresh = 'old-refresh';
      final client = ApiClient(
        baseUrl: 'http://test',
        tokenStorage: storage,
        refreshDio: _dioThatSucceeds(accessToken: 'new-access', refreshToken: 'new-refresh'),
      );

      await _forceRefresh(client);

      expect(storage.access, 'new-access');
      expect(storage.refresh, 'new-refresh');
    });
  });
}

/// _doRefresh — приватный метод, вызывается только изнутри ApiClient при
/// 401 на основном dio. Гоняем через тот же публичный путь (запрос →
/// перехватчик видит 401 → пытается refresh), подставив фейковый основной
/// dio-адаптер, который один раз отвечает 401, а дальше используется
/// обычный dio.fetch на повтор (который тоже упадёт — нас интересует только
/// состояние токенов/стрима после попытки refresh, не финальный результат
/// исходного запроса).
Future<void> _forceRefresh(ApiClient client) async {
  // 401 только на первый запрос — если refresh всё же удастся (тест
  // «успешный refresh»), повтор с новым токеном не должен уйти в
  // бесконечный цикл 401 → refresh → retry → 401 → ...
  client.dio.httpClientAdapter = _Returns401OnceAdapter();
  try {
    await client.dio.get('/whatever');
  } catch (_) {
    // ожидаемо, когда refresh так и не удался — нас интересует только
    // побочный эффект на tokenStorage/onSessionExpired
  }
}

class _Returns401OnceAdapter implements HttpClientAdapter {
  var _calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    _calls++;
    final statusCode = _calls == 1 ? 401 : 200;
    return ResponseBody.fromString('{}', statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
