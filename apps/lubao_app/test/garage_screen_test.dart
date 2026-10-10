import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/profile/garage_screen.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

GarageVehicle _vehicle({
  required String id,
  required VehicleKind kind,
  String? brand,
  String? plateNumber,
  double? capacityTons,
  bool isVerified = false,
  bool hasDocument = true,
}) =>
    GarageVehicle(
      id: id,
      kind: kind,
      plateNumber: plateNumber,
      brand: brand,
      capacityTons: capacityTons,
      isOwner: true,
      isVerified: isVerified,
      hasDocument: hasDocument,
      isArchived: false,
      createdAt: DateTime(2026, 10, 1),
    );

Future<void> _pump(WidgetTester tester, List<GarageVehicle> vehicles) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [garageVehiclesProvider.overrideWith((ref) async => vehicles)],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const GarageScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows tractors and trailers in their own sections with the right status badge', (tester) async {
    await _pump(tester, [
      _vehicle(id: 't1', kind: VehicleKind.tractor, brand: 'MAN TGX', plateNumber: '777 ABP 05', isVerified: true),
      _vehicle(id: 't2', kind: VehicleKind.tractor, brand: 'Volvo FH', plateNumber: '123 ABC 02', isVerified: false),
      _vehicle(id: 'r1', kind: VehicleKind.trailer, plateNumber: '45 ABC 05', capacityTons: 20, isVerified: true),
    ]);

    expect(find.text('ТЯГАЧИ'), findsOneWidget);
    expect(find.text('ПРИЦЕПЫ'), findsOneWidget);
    expect(find.textContaining('MAN TGX'), findsOneWidget);
    expect(find.textContaining('Volvo FH'), findsOneWidget);
    expect(find.text('проверена'), findsNWidgets(2));
    expect(find.text('на проверке'), findsOneWidget);
  });

  // 045 п.5: пустой гараж — одна карточка-призыв, без разделов-заглушек.
  testWidgets('пустой гараж: карточка «Добавьте машину» с кнопкой', (tester) async {
    await _pump(tester, []);

    expect(find.byKey(const Key('garageEmptyCta')), findsOneWidget);
    expect(find.text('Добавьте машину'), findsOneWidget);
    expect(find.text('Добавить машину или прицеп'), findsOneWidget);
    expect(find.text('Нет тягачей'), findsNothing);
  });

  testWidgets('карточка машины: первой строкой госномер, без номера — «Без номера»', (tester) async {
    await _pump(tester, [
      _vehicle(id: 't1', kind: VehicleKind.tractor, plateNumber: '123ABC02', isVerified: true, hasDocument: true),
      _vehicle(id: 'r1', kind: VehicleKind.trailer, plateNumber: null, capacityTons: 20, isVerified: false, hasDocument: true),
    ]);
    expect(tester.widget<Text>(find.byKey(const Key('garageVehicleTitle-t1'))).data, '123ABC02');
    expect(tester.widget<Text>(find.byKey(const Key('garageVehicleTitle-r1'))).data, 'Без номера');
  });

  // Huawei Y7: экран 360 dp и системный шрифт ×1,3 — раньше текст карточки
  // сжимался до буквы в строке и «Добавить документ» было не нажать.
  testWidgets('узкий экран и крупный шрифт: карточка без переполнения, «Добавить документ» нажимается', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, [
      _vehicle(id: 'r1', kind: VehicleKind.trailer, plateNumber: '45 ABC 05', capacityTons: 20, isVerified: false, hasDocument: false),
    ]);
    expect(tester.takeException(), isNull);
    final add = find.byKey(const Key('garageAddDocument-r1'));
    expect(add, findsOneWidget);
    // Надпись — в одну-две строки, а не столбиком по букве.
    expect(tester.getSize(add).width, greaterThan(100));
  });
}
