import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/src/api/api_client.dart';
import 'package:lubao_core/src/api/token_storage.dart';
import 'package:lubao_core/src/offline/contact_event_queue.dart';
import 'package:lubao_core/src/repositories/cargo_repository.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<void> save(String accessToken, String refreshToken) async {}

  @override
  Future<String?> readAccess() async => null;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> clear() async {}
}

/// Всегда отвечает той же ошибкой, что реальный Dio выдал бы без сети.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.exceptionBuilder);

  final DioException Function(RequestOptions options) exceptionBuilder;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    throw exceptionBuilder(options);
  }

  @override
  void close({bool force = false}) {}
}

class _FixedStatusAdapter implements HttpClientAdapter {
  _FixedStatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString('{"message":"Driver not found"}', statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Задача 029, п.14 — `logContactEvent` различает «нет сети» (очередь) от
/// «сервер ответил с ошибкой» (пробрасывает исключение как раньше).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final backing = <String, String>{};

  setUp(() {
    backing.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          return backing[call.arguments['key'] as String];
        case 'write':
          backing[call.arguments['key'] as String] = call.arguments['value'] as String;
          return null;
        case 'delete':
          backing.remove(call.arguments['key'] as String);
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('a connection error (no network) is swallowed and queued, not thrown at the call site', () async {
    final client = ApiClient(baseUrl: 'http://test', tokenStorage: _FakeTokenStorage());
    client.dio.httpClientAdapter = _ThrowingAdapter(
      (options) => DioException(requestOptions: options, type: DioExceptionType.connectionError),
    );
    final repo = CargoRepository(client);

    // Не бросает — именно это раньше ломало `unawaited(...)` на границе
    // без сети (необработанное исключение).
    await repo.logContactEvent(driverId: 'd1', companyId: 'c1', type: 'CALL');

    final queue = ContactEventQueue();
    final sent = <String>[];
    await queue.flush((e) async => sent.add(e.driverId));
    expect(sent, ['d1']);
  });

  test('a real server error (404) is not queued — it propagates like before', () async {
    final client = ApiClient(baseUrl: 'http://test', tokenStorage: _FakeTokenStorage());
    client.dio.httpClientAdapter = _FixedStatusAdapter(404);
    final repo = CargoRepository(client);

    await expectLater(
      () => repo.logContactEvent(driverId: 'd1', companyId: 'c1', type: 'CALL'),
      throwsA(isA<DioException>()),
    );

    final queue = ContactEventQueue();
    var called = false;
    await queue.flush((e) async => called = true);
    expect(called, isFalse, reason: 'a real 404 must not be silently retried forever');
  });

  test('flushPendingContactEvents() sends a previously queued event once the network is back', () async {
    final offlineClient = ApiClient(baseUrl: 'http://test', tokenStorage: _FakeTokenStorage());
    offlineClient.dio.httpClientAdapter = _ThrowingAdapter(
      (options) => DioException(requestOptions: options, type: DioExceptionType.connectionTimeout),
    );
    final offlineRepo = CargoRepository(offlineClient);
    await offlineRepo.logContactEvent(driverId: 'd1', companyId: 'c1', cargoId: 'cargo1', type: 'WHATSAPP');

    final requests = <RequestOptions>[];
    final onlineClient = ApiClient(baseUrl: 'http://test', tokenStorage: _FakeTokenStorage());
    onlineClient.dio.httpClientAdapter = _RecordingAdapter(requests);
    final onlineRepo = CargoRepository(onlineClient);

    await onlineRepo.flushPendingContactEvents();

    expect(requests, hasLength(1));
    expect(requests.first.data, {'driverId': 'd1', 'companyId': 'c1', 'cargoId': 'cargo1', 'type': 'WHATSAPP'});
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.requests);

  final List<RequestOptions> requests;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}
