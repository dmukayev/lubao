import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/src/api/api_client.dart';
import 'package:lubao_core/src/api/token_storage.dart';
import 'package:lubao_core/src/repositories/arrival_repository.dart';

/// Не трогает flutter_secure_storage — ApiClient() по умолчанию создаёт
/// настоящий TokenStorage, которому нужен платформенный канал.
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

/// Отвечает на любой запрос заданным телом/заголовками без похода в сеть.
class _FixedBodyAdapter implements HttpClientAdapter {
  _FixedBodyAdapter({required this.body, this.withJsonContentType = true});

  final String body;
  final bool withJsonContentType;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(
      body,
      200,
      headers: withJsonContentType
          ? {Headers.contentTypeHeader: [Headers.jsonContentType]}
          : {},
    );
  }

  @override
  void close({bool force = false}) {}
}

ArrivalRepository _repoWithBody(String body, {bool withJsonContentType = true}) {
  final client = ApiClient(baseUrl: 'http://test', tokenStorage: _FakeTokenStorage());
  client.dio.httpClientAdapter = _FixedBodyAdapter(body: body, withJsonContentType: withJsonContentType);
  return ArrivalRepository(client);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Задача 027: NestJS отдаёт bare `null` пустым телом без Content-Type —
  // Dio кладёт в res.data пустую строку '', а не null. Эндпоинты теперь
  // всегда оборачивают в объект ({arrival: ...}/{template: ...}), но
  // репозиторий должен переживать и старое поведение (пустое тело), не
  // падая с CastError.
  group('ArrivalRepository.mine — пустые/явные ответы (027)', () {
    test('пустое тело без Content-Type → null, без исключения', () async {
      final repo = _repoWithBody('', withJsonContentType: false);
      expect(await repo.mine(), isNull);
    });

    test('{"arrival": null} → null', () async {
      final repo = _repoWithBody('{"arrival": null}');
      expect(await repo.mine(), isNull);
    });

    test('{"arrival": {...}} → распарсенный Arrival', () async {
      final repo = _repoWithBody(
        '{"arrival": {"id":"a1","pointId":"p1","plannedAt":"2026-01-01T00:00:00.000Z","waitDays":2,'
        '"anyCountry":false,"countryIds":[],"status":"PLANNED","viewsCount":0}}',
      );
      final arrival = await repo.mine();
      expect(arrival, isNotNull);
      expect(arrival!.id, 'a1');
    });
  });

  group('ArrivalRepository.lastTemplate — пустые/явные ответы (027)', () {
    test('пустое тело без Content-Type → null, без исключения', () async {
      final repo = _repoWithBody('', withJsonContentType: false);
      expect(await repo.lastTemplate(), isNull);
    });

    test('{"template": null} → null', () async {
      final repo = _repoWithBody('{"template": null}');
      expect(await repo.lastTemplate(), isNull);
    });

    test('{"template": {...}} → распарсенный ArrivalTemplate', () async {
      final repo = _repoWithBody('{"template": {"pointId":"p1","anyCountry":true,"countryIds":["kz"]}}');
      final template = await repo.lastTemplate();
      expect(template, isNotNull);
      expect(template!.pointId, 'p1');
    });
  });
}
