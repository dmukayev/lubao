import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md: «В текстах интерфейса, push и писем „Хоргос“ не писать» —
/// название точки приходит из справочника, а не из строк ARB (задача 040).
void main() {
  const forbidden = ['Хоргос', 'Khorgos', 'Horgos', 'Қорғас', '霍尔果斯'];

  for (final lang in ['ru', 'kk', 'zh', 'en']) {
    test('app_$lang.arb не содержит название конкретной точки', () {
      final text = File('lib/l10n/app_$lang.arb').readAsStringSync();
      for (final word in forbidden) {
        expect(text.contains(word), isFalse, reason: 'в app_$lang.arb найдено «$word»');
      }
    });
  }
}
