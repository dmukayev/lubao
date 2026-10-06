import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/src/api/api_client.dart';
import 'package:lubao_core/src/api/token_storage.dart';
import 'package:lubao_core/src/repositories/arrival_repository.dart';
import 'package:lubao_core/src/models/arrival.dart';

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
    test('пустое тело без Content-Type → нет анонсов, без исключения', () async {
      final repo = _repoWithBody('', withJsonContentType: false);
      final mine = await repo.mine();
      expect(mine.current, isNull);
      expect(mine.all, isEmpty);
    });

    test('{"arrival": null} → нет текущего анонса', () async {
      final repo = _repoWithBody('{"arrival": null}');
      expect((await repo.mine()).current, isNull);
    });

    test('{"arrival": {...}} → распарсенный Arrival', () async {
      final repo = _repoWithBody(
        '{"arrival": {"id":"a1","pointId":"p1","plannedAt":"2026-01-01T00:00:00.000Z","waitDays":2,'
        '"anyCountry":false,"countryIds":[],"status":"PLANNED","viewsCount":0}}',
      );
      final arrival = (await repo.mine()).current;
      expect(arrival, isNotNull);
      expect(arrival!.id, 'a1');
    });

    test('040: несколько анонсов — «текущий» и «остальные», вопрос свежести распознаётся', () async {
      final repo = _repoWithBody(
        '{"arrival": {"id":"a1","pointId":"p1","plannedAt":"2026-01-01T00:00:00.000Z","plannedDay":"2026-01-01","waitDays":2,'
        '"anyCountry":false,"countryIds":[],"status":"ON_SITE","viewsCount":0,"ask":"STILL_LOOKING"},'
        '"arrivals": ['
        '{"id":"a1","pointId":"p1","plannedAt":"2026-01-01T00:00:00.000Z","plannedDay":"2026-01-01","waitDays":2,"anyCountry":false,"countryIds":[],"status":"ON_SITE","viewsCount":0,"ask":"STILL_LOOKING"},'
        '{"id":"a2","pointId":"p2","plannedAt":"2026-01-05T00:00:00.000Z","plannedDay":"2026-01-05","waitDays":2,"anyCountry":true,"countryIds":[],"status":"PLANNED","viewsCount":0,"ask":null}'
        ']}',
      );
      final mine = await repo.mine();
      expect(mine.all.length, 2);
      expect(mine.current!.ask, ArrivalQuestion.stillLooking);
      expect(mine.others.map((a) => a.id), ['a2']);
      expect(mine.others.single.ask, isNull);
    });

    test('EXPIRED распознаётся как статус', () {
      expect(arrivalStatusFromJson('EXPIRED'), ArrivalStatus.expired);
      expect(arrivalStatusFromJson('чего-то-нового'), ArrivalStatus.planned);
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
