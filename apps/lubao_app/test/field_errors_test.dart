import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/features/shared/error_feedback.dart';
import 'package:lubao_app/features/shared/number_field.dart';
import 'package:lubao_app/providers/locale_provider.dart';
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

  test('поле кузова (INVALID_SPECS) — подпись из справочника', () {
    final data = {
      'code': 'INVALID_SPECS',
      'fields': [
        {'field': 'specs.volumeM3', 'rule': 'max', 'limit': 200, 'label': {'ru': 'Объём кузова', 'en': 'Body volume'}},
      ],
    };
    expect(validationErrorText(t, data), 'Объём кузова — не больше 200');
    expect(validationErrorText(t, {'code': 'INVALID_SPECS', 'fields': [{'field': 'specs.liters', 'rule': 'required', 'label': {'ru': 'Объём цистерны'}}]}), 'Объём цистерны — обязательно');
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
    expect(numberFieldError(t, '', max: 20, required: true), 'Обязательное поле');
    expect(numberFieldError(t, '-25', min: -30, max: 25, positive: false), isNull);
    expect(numberFieldError(t, '0,5', min: 1, max: 200), 'Не меньше 1');
    expect(numberFieldError(t, '50000', max: 30000), 'Не больше 30 000');
  });

  testWidgets('поле кузова из справочника: 500 при пределе 200 — «Не больше 200» под полем; обязательное — после «Сохранить»', (tester) async {
    const fields = [
      BodyField(key: 'volumeM3', kind: 'number', label: I18nText(kk: 'Көлем', ru: 'Объём кузова', zh: '容积'), unit: 'm3', forVehicle: true, min: 1, max: 200),
      BodyField(key: 'product', kind: 'enum', label: I18nText(kk: 'Өнім', ru: 'Продукт', zh: '产品'), forVehicle: true, required: true, options: [(code: 'FOOD', label: I18nText(kk: 'Тағам', ru: 'Пищевое', zh: '食品'))]),
    ];
    var values = <String, dynamic>{};
    var showRequired = false;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ListView(children: [
            SpecsForm(fields: fields, values: values, showRequired: showRequired, onChanged: (v) => setState(() => values = v)),
            TextButton(onPressed: () => setState(() => showRequired = !specsValid(fields, values)), child: const Text('save')),
          ]),
        ),
      ),
    ));

    await tester.enterText(find.byKey(const Key('spec-volumeM3')), '500');
    await tester.pump();
    expect(find.text('Не больше 200'), findsOneWidget);
    expect(specsValid(fields, values), isFalse);

    await tester.tap(find.text('save'));
    await tester.pump();
    expect(find.byKey(const Key('spec-product-required')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('spec-volumeM3')), '80');
    await tester.pump();
    await tester.tap(find.byKey(const Key('spec-product-FOOD')));
    await tester.pump();
    expect(find.text('Не больше 200'), findsNothing);
    expect(specsValid(fields, values), isTrue);
  });
}
