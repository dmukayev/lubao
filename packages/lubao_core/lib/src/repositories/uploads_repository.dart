import 'package:dio/dio.dart';

import '../api/api_client.dart';

class UploadsRepository {
  UploadsRepository(this._client);

  final ApiClient _client;

  /// Загружает изображение и возвращает публичную ссылку на файл.
  /// [bytes] нужен вместо пути к файлу, чтобы одинаково работать на
  /// вебе (где нет файловой системы) и на мобильных платформах.
  Future<String> uploadImage(List<int> bytes, {required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _client.dio.post('/uploads/image', data: formData);
    return (res.data as Map<String, dynamic>)['url'] as String;
  }

  /// Документы верификации (селфи, техпаспорта, права) идут в приватный
  /// бакет (задача 026, п.6) — в отличие от [uploadImage] возвращает не
  /// публичную ссылку, а ключ объекта; сохранить его как fileUrl в
  /// `POST /drivers/me/verification-documents` — админ увидит фото через
  /// временную presigned-ссылку, не напрямую.
  Future<String> uploadDocument(List<int> bytes, {required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _client.dio.post('/uploads/document', data: formData);
    return (res.data as Map<String, dynamic>)['key'] as String;
  }
}
