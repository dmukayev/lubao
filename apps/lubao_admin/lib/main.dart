import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'app.dart';
import 'providers/api_providers.dart';

/// Сквозные сценарии админки (задача 034): в тестовой сборке включаем
/// семантику Flutter — у кнопок и полей появляются роли и подписи в DOM,
/// по которым Playwright находит элементы (`--dart-define=E2E=true`).
const _e2e = bool.fromEnvironment('E2E');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_e2e) SemanticsBinding.instance.ensureSemantics();
  final container = ProviderContainer();
  // Ошибки release-сборки — на наш сервер (043 п.6).
  ErrorReporter(container.read(apiClientProvider).dio, app: 'admin').install();
  runApp(UncontrolledProviderScope(container: container, child: const LubaoAdminApp()));
}
