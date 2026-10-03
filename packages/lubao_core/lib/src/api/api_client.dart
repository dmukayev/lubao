import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

  final Dio dio;

  String? _userId;

  /// Временная dev-авторизация: сервер доверяет заголовку X-User-Id вместо
  /// проверки JWT/сессии. Реальные SMS/email-логины будут подключены позже.
  void setCurrentUserId(String? userId) {
    _userId = userId;
    if (userId == null) {
      dio.options.headers.remove('X-User-Id');
    } else {
      dio.options.headers['X-User-Id'] = userId;
    }
  }

  String? get currentUserId => _userId;
}
