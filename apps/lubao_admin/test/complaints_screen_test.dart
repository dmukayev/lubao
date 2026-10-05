import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/complaints/complaints_screen.dart';
import 'package:lubao_admin/providers/data_providers.dart';
import 'package:lubao_admin/providers/locale_provider.dart';

/// Задача 030 — живая проверка в браузере нашла `BoxConstraints forces an
/// infinite width` при открытии карточки непривязанной жалобы: Row(кнопка,
/// Spacer(), кнопка) падал, т.к. у FilledButton/OutlinedButton в теме
/// minimumSize на всю ширину (Size.fromHeight), а их интринсик-расчёт
/// внутри этого Row получал бесконечную ширину от предка (воспроизводилось
/// и на 1200px, и на 390px — ширина экрана была ни при чём). Этот баг не
/// ловился ни flutter analyze, ни responsive_test.dart (там подставлялись
/// фиктивные Text вместо настоящего _Detail) — только реальным рендером.
AdminComplaint _complaint({String? assignedToUserId}) => AdminComplaint(
      id: 'c1',
      reporterUserId: 'u1',
      reporterName: 'Logist',
      targetType: 'DEAL',
      targetId: 'd1',
      reason: 'Водитель отменил сделку без предупреждения',
      status: ComplaintStatus.open,
      assignedToUserId: assignedToUserId,
      assignedToName: assignedToUserId == null ? null : 'Admin',
      createdAt: DateTime(2026, 10, 5),
    );

Future<void> _pump(WidgetTester tester, {String? assignedToUserId}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      adminComplaintSelectedIdProvider.overrideWith((ref) => 'c1'),
      adminComplaintDetailProvider('c1').overrideWith(
        (ref) async => AdminComplaintDetail(complaint: _complaint(assignedToUserId: assignedToUserId), violatorComplaintsLastMonth: 0),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const ComplaintsScreen(),
    ),
  ));
  // Не pumpAndSettle() — список слева (_Queue) не переопределён и вечно
  // грузится без настоящего бэкенда; несколько тиков достаточно, чтобы
  // карточка жалобы (единственное, что здесь проверяется) отрисовалась.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('an unassigned complaint renders its action row without a layout exception', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Взять в работу'), findsOneWidget);
    expect(find.text('Принять решение'), findsOneWidget);
  });

  testWidgets('an assigned complaint renders its action row without a layout exception', (tester) async {
    await _pump(tester, assignedToUserId: 'admin-1');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Admin'), findsOneWidget);
    expect(find.text('Принять решение'), findsOneWidget);
  });

  testWidgets('renders correctly at a 390px mobile width too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Взять в работу'), findsOneWidget);
  });
}
