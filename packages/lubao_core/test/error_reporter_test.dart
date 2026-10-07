import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

class _Recorder extends Interceptor {
  final bodies = <Map<String, dynamic>>[];
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    bodies.add(options.data as Map<String, dynamic>);
    handler.resolve(Response(requestOptions: options, statusCode: 204));
  }
}

void main() {
  test('ErrorReporter: отчёт уходит один раз на одинаковую ошибку и не больше лимита', () async {
    final recorder = _Recorder();
    final dio = Dio()..interceptors.add(recorder);
    final reporter = ErrorReporter(dio, app: 'app', appVersion: '1.0.0', enabled: true);
    await reporter.report(StateError('a'), StackTrace.current);
    await reporter.report(StateError('a'), StackTrace.current);
    expect(recorder.bodies, hasLength(1));
    expect(recorder.bodies.single, containsPair('app', 'app'));
    expect(recorder.bodies.single, containsPair('appVersion', '1.0.0'));
    for (var i = 0; i < 50; i++) {
      await reporter.report(StateError('e$i'), null);
    }
    expect(recorder.bodies, hasLength(ErrorReporter.maxReports));
  });

  test('ErrorReporter: в debug выключен', () async {
    final recorder = _Recorder();
    final reporter = ErrorReporter(Dio()..interceptors.add(recorder), app: 'app', enabled: false);
    await reporter.report(StateError('x'), null);
    expect(recorder.bodies, isEmpty);
  });
}
