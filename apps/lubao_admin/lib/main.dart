import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Сквозные сценарии админки (задача 034): в тестовой сборке включаем
/// семантику Flutter — у кнопок и полей появляются роли и подписи в DOM,
/// по которым Playwright находит элементы (`--dart-define=E2E=true`).
const _e2e = bool.fromEnvironment('E2E');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_e2e) SemanticsBinding.instance.ensureSemantics();
  runApp(const ProviderScope(child: LubaoAdminApp()));
}
