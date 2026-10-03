import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedLocales = [Locale('ru'), Locale('kk'), Locale('zh')];

Locale _initialLocale() {
  final deviceLocale = PlatformDispatcher.instance.locale;
  final match = supportedLocales.where((l) => l.languageCode == deviceLocale.languageCode);
  return match.isNotEmpty ? match.first : const Locale('ru');
}

final localeProvider = StateProvider<Locale>((ref) => _initialLocale());
