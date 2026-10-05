import '../api/api_client.dart';
import '../models/cargo.dart';
import '../models/response.dart';

class CargoRepository {
  CargoRepository(this._client);

  final ApiClient _client;

  Future<List<Cargo>> feed() async {
    final res = await _client.dio.get('/cargos');
    return (res.data as List<dynamic>).map((e) => Cargo.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<void> inviteDriver(String cargoId, String driverId) async {
    await _client.dio.post('/cargos/$cargoId/invite', data: {'driverId': driverId});
  }

  Future<void> logContactEvent({
    required String driverId,
    required String companyId,
    String? cargoId,
    String? dealId,
    required String type,
  }) async {
    await _client.dio.post('/contact-events', data: {
      'driverId': driverId,
      'companyId': companyId,
      if (cargoId != null) 'cargoId': cargoId,
      if (dealId != null) 'dealId': dealId,
      'type': type,
    });
  }
}
