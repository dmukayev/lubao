import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

LoadingPoint _p(String id, String ru) => LoadingPoint(id: id, cityId: 'c-$id', name: I18nText(kk: ru, ru: ru, zh: ru), isActive: true);

void main() {
  testWidgets('недавний город не дублирует ключ строки в общем списке', (tester) async {
    final points = [_p('a', 'Алматы'), _p('b', 'Астана'), _p('c', 'Шымкент')];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCityPicker(context, points: points, recentIds: const ['b']),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cityPickerRecent-b')), findsOneWidget);
    expect(find.byKey(const Key('cityPickerRow-b')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('cityPickerSearch')), 'ас');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('cityPickerRow-b')), findsOneWidget);
  });
}
