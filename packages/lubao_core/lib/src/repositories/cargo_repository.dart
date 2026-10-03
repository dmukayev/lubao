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

  Future<void> delete(String cargoId) async {
    await _client.dio.delete('/cargos/$cargoId');
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
    required String cargoId,
    required String type,
  }) async {
    await _client.dio.post('/contact-events', data: {
      'driverId': driverId,
      'companyId': companyId,
      'cargoId': cargoId,
      'type': type,
    });
  }
}
