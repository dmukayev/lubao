import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/cargo.dart';
import '../models/response.dart';
import '../offline/contact_event_queue.dart';
import '../offline/pending_contact_event.dart';

class CargoRepository {
  CargoRepository(this._client, {ContactEventQueue? contactEventQueue}) : _contactEventQueue = contactEventQueue ?? ContactEventQueue();

  final ApiClient _client;
  final ContactEventQueue _contactEventQueue;

  /// Лента водителя: порядок и отсев на сервере, страницами (040, п.5).
  Future<CargoFeedPage> feed({int limit = 30, int offset = 0}) async {
    final res = await _client.dio.get('/cargos', queryParameters: {'limit': limit, 'offset': offset});
    return CargoFeedPage.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Помещается к текущему: 8 т + 10 т из 20 т» — только для водителя с
  /// активной сделкой, иначе `null` (040, п.6).
  Future<PartialHint?> partialHint(String cargoId) async {
    final res = await _client.dio.get('/cargos/$cargoId/partial-hint');
    final data = res.data;
    if (data is! Map<String, dynamic>) return null;
    final hint = data['hint'];
    return hint is Map<String, dynamic> ? PartialHint.fromJson(hint) : null;
  }

  Future<List<Cargo>> mine() async {
    final res = await _client.dio.get('/cargos/mine');
    return (res.data as List<dynamic>).map((e) => Cargo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Cargo> byId(String id) async {
    final res = await _client.dio.get('/cargos/$id');
    return Cargo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Cargo> create(CreateCargoInput input) async {
    final res = await _client.dio.post('/cargos', data: input.toJson());
    return Cargo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Cargo> update(String cargoId, CreateCargoInput input) async {
    final res = await _client.dio.patch('/cargos/$cargoId', data: input.toJson());
    return Cargo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Кандидаты на «Нашёл в Lubao» (задача 017, п.6) — водители, с кем уже
  /// был отклик/звонок/переписка по этому грузу.
  Future<List<CargoCloseCandidate>> closeCandidates(String cargoId) async {
    final res = await _client.dio.get('/cargos/$cargoId/close-candidates');
    return (res.data as List<dynamic>).map((e) => CargoCloseCandidate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Груз нельзя закрыть без выбора исхода (задача 017, п.6) — заменяет
  /// старое «удалить» без причины.
  Future<void> close(String cargoId, {required String outcome, String? driverId}) async {
    await _client.dio.post('/cargos/$cargoId/close', data: {'outcome': outcome, if (driverId != null) 'driverId': driverId});
  }

  /// «Подходит N водителям на точке» при публикации (задача 033, п.10).
  Future<int> fitCount({double? weightKg, double? volumeM3, int? palletCount, String? pointId}) async {
    final res = await _client.dio.get('/cargos/fit-count', queryParameters: {
      if (pointId != null) 'pointId': pointId,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (palletCount != null) 'palletCount': palletCount,
    });
    return (res.data as Map<String, dynamic>)['count'] as int;
  }

  Future<List<CargoResponse>> responsesFor(String cargoId) async {
    final res = await _client.dio.get('/cargos/$cargoId/responses');
    return (res.data as List<dynamic>).map((e) => CargoResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CargoResponse> respond(String cargoId, {String? message}) async {
    final res = await _client.dio.post('/cargos/$cargoId/responses', data: {if (message != null) 'message': message});
    return CargoResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CargoResponse> updateResponseStatus(String responseId, String status) async {
    final res = await _client.dio.patch('/responses/$responseId', data: {'status': status});
    return CargoResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// «Мои отклики» водителя (041, п.9).
  Future<List<MyResponseEntry>> myResponses() async {
    final res = await _client.dio.get('/responses/mine');
    return (res.data as List<dynamic>).map((e) => MyResponseEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Мой отклик на груз (null — ещё не откликался).
  Future<MyCargoResponse?> myResponse(String cargoId) async {
    final res = await _client.dio.get('/cargos/$cargoId/my-response');
    final data = (res.data as Map<String, dynamic>)['response'];
    return data == null ? null : MyCargoResponse.fromJson(data as Map<String, dynamic>);
  }

  /// «Отозвать» (задача 035) — только пока отклик ещё `PENDING`.
  Future<CargoResponse> withdrawResponse(String responseId) async {
    final res = await _client.dio.post('/responses/$responseId/withdraw');
    return CargoResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> inviteDriver(String cargoId, String driverId) async {
    await _client.dio.post('/cargos/$cargoId/invite', data: {'driverId': driverId});
  }

  /// Задача 029, п.14 — звонок/WhatsApp часто случаются там, где сети уже
  /// нет (граница). Раньше запись contact_event была «выстрелил и
  /// забыл» без обработки ошибки — событие просто пропадало. Теперь при
  /// сбое, похожем на отсутствие сети (таймаут/нет соединения — не
  /// настоящий ответ сервера), событие уходит в локальную очередь и
  /// досылается при восстановлении связи ([flushPendingContactEvents]).
  Future<void> logContactEvent({
    required String driverId,
    required String companyId,
    String? cargoId,
    String? dealId,
    required String type,
  }) async {
    final event = PendingContactEvent(driverId: driverId, companyId: companyId, cargoId: cargoId, dealId: dealId, type: type);
    try {
      await _sendContactEvent(event);
    } on DioException catch (e) {
      if (_isConnectivityIssue(e)) {
        await _contactEventQueue.enqueue(event);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _sendContactEvent(PendingContactEvent event) {
    return _client.dio.post('/contact-events', data: event.toJson());
  }

  /// Сервер ответил (даже с ошибкой 4xx/5xx) — не сетевая проблема,
  /// повторная отправка той же пары id/type не исправит дело молча.
  bool _isConnectivityIssue(DioException e) => e.type != DioExceptionType.badResponse && e.type != DioExceptionType.cancel;

  /// Вызывается при восстановлении realtime-соединения (см.
  /// RealtimeConnector) — тот же сигнал «сеть снова есть», что уже
  /// используется для догоняющего рефетча чата.
  Future<void> flushPendingContactEvents() => _contactEventQueue.flush(_sendContactEvent);
}
