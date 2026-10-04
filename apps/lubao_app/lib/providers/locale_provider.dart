import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedLocales = [Locale('ru'), Locale('kk'), Locale('zh'), Locale('en')];

Locale _initialLocale() {
  // WidgetsBinding.instance.platformDispatcher (не статический
  // PlatformDispatcher.instance из dart:ui) — тестовый биндинг переопределяет
  // именно его, иначе tester.platformDispatcher.localeTestValue тихо не
  // действует и тесты видят настоящую локаль машины разработчика.
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final match = supportedLocales.where((l) => l.languageCode == deviceLocale.languageCode);
  return match.isNotEmpty ? match.first : const Locale('ru');
}

final localeProvider = StateProvider<Locale>((ref) => _initialLocale());
