import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/feed/cargo_detail_screen.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 040, п.6: подсказка «Помещается к текущему: 8 т + 10 т из 20 т».
Cargo _cargo() => Cargo(
      id: 'c',
      companyId: 'co',
      companyName: 'Co',
      pointId: 'p',
      destinationCountryId: 'kz',
      bodyTypeId: 'bt',
      price: 1,
      currency: Currency.usd,
      readyDate: DateTime(2026, 10, 8),
      status: CargoStatus.published,
      publishedAt: DateTime(2026, 10, 1),
      expiresAt: DateTime(2026, 10, 3),
      allowPartial: true,
    );

Future<void> _pump(WidgetTester tester, PartialHint? hint, {String locale = 'ru'}) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(locale),
    supportedLocales: supportedLocales,
    localizationsDelegates: LubaoLocalizations.localizationsDelegates,
    home: Scaffold(body: PartialLoadBlock(cargo: _cargo(), hint: hint)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('без активной сделки — только плашка «Догруз», без подсказки', (tester) async {
    await _pump(tester, null);
    expect(find.text('Догруз'), findsOneWidget);
    expect(find.byKey(const Key('cargoPartialHint')), findsNothing);
  });

  testWidgets('помещается: «8 т + 10 т из 20 т»', (tester) async {
    await _pump(tester, const PartialHint(fits: true, committedWeightKg: 8000, cargoWeightKg: 10000, capacityKg: 20000));
    expect(find.text('Помещается к текущему: 8 т + 10 т из 20 т'), findsOneWidget);
  });

  testWidgets('не помещается — честно говорит об этом', (tester) async {
    await _pump(tester, const PartialHint(fits: false, reason: 'FULL', committedWeightKg: 15000, cargoWeightKg: 10000, capacityKg: 20000));
    expect(find.text('Не поместится к текущему: 15 т + 10 т из 20 т'), findsOneWidget);
  });

  testWidgets('другая дата погрузки — это следующий рейс, а не догруз', (tester) async {
    await _pump(tester, const PartialHint(fits: false, reason: 'NEXT_TRIP', committedWeightKg: 8000));
    expect(find.text('Другая дата погрузки — это следующий рейс, а не догруз'), findsOneWidget);
  });

  testWidgets('на английском и китайском тексты те же по смыслу', (tester) async {
    await _pump(tester, const PartialHint(fits: true, committedWeightKg: 8500, cargoWeightKg: 10000, capacityKg: 20000), locale: 'en');
    expect(find.text('Fits with your current load: 8.5 t + 10 t of 20 t'), findsOneWidget);
    await _pump(tester, const PartialHint(fits: true, committedWeightKg: 8000, cargoWeightKg: 10000, capacityKg: 20000), locale: 'zh');
    expect(find.textContaining('8 吨 + 10 吨'), findsOneWidget);
  });
}
