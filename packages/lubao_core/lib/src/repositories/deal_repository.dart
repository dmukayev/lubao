import 'dart:typed_data';

import 'package:dio/dio.dart';

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

  /// 044: пакет документов водителя (только логист компании, после подтверждения).
  Future<DriverDocumentsPackage> driverDocuments(String dealId) async {
    final res = await _client.dio.get('/deals/$dealId/driver-documents');
    return DriverDocumentsPackage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Байты документа из пакета — для превью (авторизованный запрос).
  Future<Uint8List> driverDocumentFile(String dealId, String documentId) async {
    final res = await _client.dio.get<List<int>>('/deals/$dealId/driver-documents/files/$documentId', options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(res.data ?? const []);
  }

  /// Одноразовая ссылка на PDF (5 минут) — открыть в браузере/просмотрщике.
  Future<Uri> driverDocumentsPdfLink(String dealId) async {
    final res = await _client.dio.post('/deals/$dealId/driver-documents/pdf-link');
    final token = (res.data as Map<String, dynamic>)['token'] as String;
    return Uri.parse('${_client.dio.options.baseUrl}/deals/$dealId/driver-documents.pdf').replace(queryParameters: {'token': token});
  }

  /// Водителю — кто и когда открывал его документы по сделке.
  Future<List<DriverDocsAccess>> driverDocumentsAccessLog(String dealId) async {
    final res = await _client.dio.get('/deals/$dealId/driver-documents/access-log');
    return (res.data as List<dynamic>).map((e) => DriverDocsAccess.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Deal> advanceStatus(String id, DealStatus status) async {
    final res = await _client.dio.patch('/deals/$id/status', data: {'status': dealStatusToJson(status)});
    return Deal.fromJson(res.data as Map<String, dynamic>);
  }

  /// `reasonCode` — код пресета причины (038, п.15): «взял другой груз» и
  /// т.п. считаются в статистике по коду, не по переведённой строке.
  Future<Deal> cancel(String id, {required String reason, String? reasonCode}) async {
    final res = await _client.dio.patch('/deals/$id/cancel', data: {
      'reason': reason,
      if (reasonCode != null) 'reasonCode': reasonCode,
    });
    return Deal.fromJson(res.data as Map<String, dynamic>);
  }
}
