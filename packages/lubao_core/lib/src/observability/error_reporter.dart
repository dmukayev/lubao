import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ошибки Flutter → `POST /client-errors` нашего сервера (043 п.6), он
/// вычищает ПДн и пересылает в Sentry. Без SDK Sentry в приложении: из Китая
/// sentry.io может быть недоступен. Только в release-сборках; не больше
/// [maxReports] за запуск, одинаковые — один раз.
class ErrorReporter {
  ErrorReporter(this._dio, {required this.app, this.appVersion, bool? enabled}) : _enabled = enabled ?? kReleaseMode;

  static const maxReports = 20;

  final Dio _dio;
  final String app;
  String? appVersion;
  final bool _enabled;
  final _seen = <String>{};

  void install() {
    if (!_enabled) return;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      report(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      return false;
    };
  }

  Future<void> report(Object error, StackTrace? stack) async {
    if (!_enabled || _seen.length >= maxReports) return;
    final message = error.toString();
    if (!_seen.add(message)) return;
    try {
      await _dio.post('/client-errors', data: {
        'message': message.length > 2000 ? message.substring(0, 2000) : message,
        if (stack != null) 'stack': _trim(stack.toString(), 8000),
        'platform': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'),
        'app': app,
        if (appVersion != null) 'appVersion': appVersion,
      });
    } catch (_) {
      // Отчёт об ошибке не должен сам ронять приложение или зацикливаться.
    }
  }

  static String _trim(String s, int max) => s.length > max ? s.substring(0, max) : s;
}
