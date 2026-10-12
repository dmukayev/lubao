import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

/// 074 п.5 (CI): у каждого кода ошибки сервера есть текст на 4 языках, а
/// «Что-то пошло не так» напрямую — только внутри общей функции.
void main() {
  final repo = Directory.current.parent.parent; // packages/lubao_core → корень
  final codesFile = File('${repo.path}/backend/src/common/error-codes.ts');

  List<String> userCodes() {
    final src = codesFile.readAsStringSync();
    final start = src.indexOf('USER_ERROR_CODES');
    final end = src.indexOf('] as const', start);
    return RegExp(r"'([A-Z][A-Z0-9_]+)'").allMatches(src.substring(start, end)).map((m) => m.group(1)!).toList();
  }

  test('каждый код из backend/src/common/error-codes.ts — свой текст на ru, kk, zh, en', () {
    final codes = userCodes();
    expect(codes.length, greaterThan(50));
    for (final lang in ['ru', 'kk', 'zh', 'en']) {
      final t = lookupLubaoLocalizations(Locale(lang));
      final missing = [for (final c in codes) if ((errorCodeText(t, c) ?? '').isEmpty) c];
      expect(missing, isEmpty, reason: 'нет текста ($lang): $missing');
    }
  });

  test('t.commonError напрямую — только в общих функциях ошибок', () {
    const allowed = ['packages/lubao_core/lib/src/api/error_text.dart', 'apps/lubao_app/lib/features/shared/error_feedback.dart'];
    final offenders = <String>[];
    for (final dir in ['apps/lubao_app/lib', 'apps/lubao_admin/lib', 'packages/lubao_core/lib']) {
      for (final f in Directory('${repo.path}/$dir').listSync(recursive: true).whereType<File>()) {
        final rel = f.path.substring(repo.path.length + 1);
        if (!rel.endsWith('.dart') || rel.contains('l10n/generated') || allowed.contains(rel)) continue;
        if (RegExp(r'\b(t|l10n|context\.l10n)\.commonError\b').hasMatch(f.readAsStringSync())) offenders.add(rel);
      }
    }
    expect(offenders, isEmpty);
  });
}
