import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

void main() {
  group('isValidPersonName', () {
    for (final name in ['Ерлан Қасымов', 'Ли Вэй', '李伟', "John O'Neil"]) {
      test('accepts "$name"', () {
        expect(isValidPersonName(name), isTrue);
      });
    }

    final rejectCases = {
      'digits': 'Ерлан2',
      'too short': 'A',
      'too long': 'A' * 81,
      'empty': '',
    };
    rejectCases.forEach((label, value) {
      test('rejects $label', () {
        expect(isValidPersonName(value), isFalse);
      });
    });
  });
}
