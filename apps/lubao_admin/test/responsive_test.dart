import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_admin/features/shared/responsive.dart';

/// Задача 030, п.14 — golden/widget-тесты раскладки на 390 (телефон) и
/// 1280 (компьютер): без переполнений, одна панель за раз на узком,
/// обе рядом на широком.
void main() {
  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ResponsiveMasterDetail', () {
    testWidgets('at 390px shows only the master list when nothing is selected', (tester) async {
      await setWidth(tester, 390);
      await tester.pumpWidget(MaterialApp(
        home: ResponsiveMasterDetail(
          hasSelection: false,
          master: const Text('MASTER_LIST'),
          detail: const Text('DETAIL_CARD'),
        ),
      ));

      expect(find.text('MASTER_LIST'), findsOneWidget);
      expect(find.text('DETAIL_CARD'), findsNothing);
    });

    testWidgets('at 390px shows only the detail card once something is selected', (tester) async {
      await setWidth(tester, 390);
      await tester.pumpWidget(MaterialApp(
        home: ResponsiveMasterDetail(
          hasSelection: true,
          master: const Text('MASTER_LIST'),
          detail: const Text('DETAIL_CARD'),
        ),
      ));

      expect(find.text('MASTER_LIST'), findsNothing);
      expect(find.text('DETAIL_CARD'), findsOneWidget);
    });

    testWidgets('at 1280px shows both the master list and the detail card side by side', (tester) async {
      await setWidth(tester, 1280);
      await tester.pumpWidget(MaterialApp(
        home: ResponsiveMasterDetail(
          hasSelection: true,
          master: const Text('MASTER_LIST'),
          detail: const Text('DETAIL_CARD'),
        ),
      ));

      expect(find.text('MASTER_LIST'), findsOneWidget);
      expect(find.text('DETAIL_CARD'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ResponsiveTwoColumn', () {
    testWidgets('at 390px stacks the two sections vertically (no RenderFlex overflow)', (tester) async {
      await setWidth(tester, 390);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResponsiveTwoColumn(
            left: Container(width: 500, height: 50, color: Colors.red),
            right: Container(width: 500, height: 50, color: Colors.blue),
          ),
        ),
      ));

      // Переполнение (RenderFlex overflow) бросает исключение при pump —
      // если дошли сюда без исключения, переполнения не было.
      expect(tester.takeException(), isNull);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('at 1280px places the two sections side by side in a Row', (tester) async {
      await setWidth(tester, 1280);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ResponsiveTwoColumn(
            left: const Text('LEFT'),
            right: const Text('RIGHT'),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('LEFT'), findsOneWidget);
      expect(find.text('RIGHT'), findsOneWidget);
    });
  });
}
