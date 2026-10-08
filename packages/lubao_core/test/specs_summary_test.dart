import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

// 048 п.3, 6: строка машины по профилю кузова.
void main() {
  testWidgets('цистерна: «Цистерна · 30 000 л · Пищевое · 3 секц.»; паллет нет', (tester) async {
    late String line;
    final tank = BodyType.fromJson({
      'id': 'bt',
      'code': 'TANK',
      'name': {'ru': 'Цистерна', 'kk': 'Цистерна', 'zh': '罐车'},
      'profile': 'TANK',
      'fields': [
        {'key': 'liters', 'kind': 'number', 'unit': 'l', 'label': {'ru': 'Объём'}, 'forVehicle': true, 'forCargo': false},
        {
          'key': 'product', 'kind': 'enum', 'label': {'ru': 'Продукт'}, 'forVehicle': true, 'forCargo': false,
          'options': [{'code': 'FOOD', 'label': {'ru': 'Пищевое'}}],
        },
        {'key': 'sections', 'kind': 'number', 'unit': 'sections', 'label': {'ru': 'Секции'}, 'forVehicle': true, 'forCargo': false},
      ],
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: Builder(builder: (context) {
        line = specsSummary(context.l10n, 'ru', tank, {'liters': 30000, 'product': 'FOOD', 'sections': 3, 'palletsEuro': 33});
        return const SizedBox();
      }),
    ));
    expect(line, 'Цистерна · 30 000 л · Пищевое · 3 секц.');
    expect(tank.isVolume, isFalse);
    expect(tank.hasCapacity, isFalse);
  });
}
