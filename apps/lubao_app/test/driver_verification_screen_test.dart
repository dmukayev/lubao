import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/profile/driver_verification_screen.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 031, п.25 — блок «Распознано» под документом на мобильной
/// проверке: только чтение (значение + «проверьте» при низкой уверенности),
/// без сверки с чёрным списком. Не должен ронять layout.
VerificationDocument _doc() => VerificationDocument(
      id: 'doc1',
      type: VerificationDocType.driverLicense,
      fileUrl: 'https://example.com/doc1.jpg',
      status: VerificationDocStatus.pending,
      createdAt: DateTime(2026, 10, 1),
    );

AdminDocumentRecognition _recognition() => const AdminDocumentRecognition(
      status: 'DONE',
      fields: {
        'fullName': AdminRecognizedField(value: 'Ерлан Тохтаров', confidence: 0.9, checksumOk: true, needsReview: false),
        'iin': AdminRecognizedField(value: '850712345600', confidence: 0.4, checksumOk: false, needsReview: true),
      },
    );

void main() {
  testWidgets('shows the recognition block with a needs-review field without a layout exception', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        driverVerificationDocumentsProvider.overrideWith((ref) async => [_doc()]),
        driverDocumentRecognitionProvider('doc1').overrideWith((ref) async => _recognition()),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const DriverVerificationScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Распознано'), findsOneWidget);
    expect(find.text('Ерлан Тохтаров'), findsOneWidget);
  });

  testWidgets('renders correctly at a 390px mobile width too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        driverVerificationDocumentsProvider.overrideWith((ref) async => [_doc()]),
        driverDocumentRecognitionProvider('doc1').overrideWith((ref) async => _recognition()),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const DriverVerificationScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
