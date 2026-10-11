import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'providers/api_providers.dart';
import 'services/perf_log.dart';

void main() {
  // Чистые адреса без «#» (задача 042, п.2): https://<хост>/invite/<токен>
  // открывает экран принятия приглашения на вебе; на мобильных — no-op.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  // 060 п.5: замеры — только со сборкой --dart-define=PERF_LOG=true.
  PerfLog.start();
  final container = ProviderContainer();
  // Ошибки release-сборки — на наш сервер, он чистит ПДн и шлёт в Sentry (043 п.6).
  final reporter = ErrorReporter(container.read(apiClientProvider).dio, app: 'app')..install();
  PackageInfo.fromPlatform().then((info) => reporter.appVersion = info.version, onError: (_) {});
  runApp(UncontrolledProviderScope(container: container, child: const LubaoApp()));
}
