import '../api/api_client.dart';
import '../models/common.dart';
import '../models/deal.dart';

class DealRepository {
  DealRepository(this._client);

  final ApiClient _client;

  Future<List<Deal>> mine() async {
    final res = await _client.dio.get('/deals/mine');
    return (res.data as List<dynamic>).map((e) => Deal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Deal> byId(String id) async {
    final res = await _client.dio.get('/deals/$id');
    return Deal.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Deal> advanceStatus(String id, DealStatus status) async {
    final res = await _client.dio.patch('/deals/$id/status', data: {'status': dealStatusToJson(status)});
    return Deal.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Deal> cancel(String id, {required String reason}) async {
    final res = await _client.dio.patch('/deals/$id/cancel', data: {'reason': reason});
    return Deal.fromJson(res.data as Map<String, dynamic>);
  }
}
