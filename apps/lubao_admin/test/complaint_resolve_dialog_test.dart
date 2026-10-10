import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/complaints/complaint_resolve_dialog.dart';
import 'package:lubao_admin/providers/locale_provider.dart';

void main() {
  for (final width in [1280.0, 360.0])
  testWidgets('решение по жалобе ($width px): выбрать вариант, ответ автору, «Сохранить» нажимается', (tester) async {
    tester.view.physicalSize = Size(width, 740) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    ComplaintResolveResult? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () async => result = await showComplaintResolveDialog(context, targetType: 'CARGO'), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Пустой ответ — кнопка нажимается и объясняет, чего не хватает.
    await tester.tap(find.byKey(const Key('complaintResolveSave')));
    await tester.pump();
    expect(find.text('Напишите ответ автору — он его увидит'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.byType(RadioListTile<String>).at(1));
    await tester.enterText(find.byType(TextField), 'Предупредили компанию');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result?.resolution, 'WARNED');
  });
}
