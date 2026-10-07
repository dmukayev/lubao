import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api_providers.dart';

/// 043 п.8: версия ниже `minAppVersion` из админки → экран «Обновите
/// приложение» вместо всего остального. Проверка при старте; нет сети или
/// сервер не ответил — пускаем (не запираем человека из-за сбоя).
final appUpdateRequiredProvider = StateNotifierProvider<AppUpdateGate, bool>((ref) => AppUpdateGate(ref)..check());

class AppUpdateGate extends StateNotifier<bool> {
  AppUpdateGate(this._ref) : super(false);

  final Ref _ref;

  Future<void> check() async {
    try {
      final minimum = await _ref.read(referenceDataRepositoryProvider).minAppVersion();
      if (minimum == null) return;
      final current = (await PackageInfo.fromPlatform()).version;
      if (mounted) state = isVersionBelow(current, minimum);
    } catch (e) {
      debugPrint('AppUpdateGate: $e');
    }
  }
}
