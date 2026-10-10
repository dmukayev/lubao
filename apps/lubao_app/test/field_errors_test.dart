import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/features/shared/error_feedback.dart';
import 'package:lubao_app/features/shared/number_field.dart';
import 'package:lubao_core/lubao_core.dart';

void main() {
  late LubaoLocalizations t;
  setUpAll(() async => t = await LubaoLocalizations.delegate.load(const Locale('ru')));

  test('ответ сервера VALIDATION_FAILED → поле и предел по-русски', () {
    final data = {
      'code': 'VALIDATION_FAILED',
      'fields': [
        {'field': 'innerLengthM', 'rule': 'max', 'limit': 20},
      ],
    };
    expect(validationErrorText(t, data), 'Длина внутри, м — не больше 20');
    expect(validationErrorText(t, {'code': 'VALIDATION_FAILED', 'fields': [{'field': 'innerHeightM', 'rule': 'max', 'limit': 4.5}]}), 'Высота внутри, м — не больше 4,5');
  });

  test('неизвестное поле или старый ответ — общий текст (null)', () {
    expect(validationErrorText(t, {'code': 'VALIDATION_FAILED', 'fields': [{'field': 'zzz', 'rule': 'max', 'limit': 1}]}), isNull);
    expect(validationErrorText(t, {'message': ['x']}), isNull);
  });

  test('поле размера: 50 → «Не больше 20», «abc» → «Введите число», «13,6» — ок', () {
    expect(numberFieldError(t, '50', max: 20), 'Не больше 20');
    expect(numberFieldError(t, 'abc', max: 20), 'Введите число');
    expect(numberFieldError(t, '0', max: 20), 'Должно быть больше 0');
    expect(numberFieldError(t, '13,6', max: 20), isNull);
    expect(numberFieldError(t, '', max: 20), isNull);
    expect(numberFieldError(t, '', max: 20, required: true), 'Введите число');
  });
}
