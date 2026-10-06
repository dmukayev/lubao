import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/verification/verification_screen.dart';
import 'package:lubao_admin/providers/data_providers.dart';
import 'package:lubao_admin/providers/locale_provider.dart';

/// Задача 031, этап E, п.22 — блок «Распознано» на экране проверки: поля
/// со статусом (включая ⛔ чёрный список) не должны ронять layout, и итог
/// по чёрному списку должен быть виден внизу блока.
AdminVerificationDriverProfile _profile() => AdminVerificationDriverProfile(
      id: 'd1',
      fullName: 'Ерлан Тохтаров',
      isVerified: false,
      vehicles: const [],
      documents: [
        AdminCardDocument(id: 'doc1', type: 'DRIVER_LICENSE', fileUrl: '/admin/documents/doc1/file', status: VerificationStatus.pending, createdAt: DateTime(2026, 10, 1)),
      ],
    );

AdminDocumentRecognition _recognition() => const AdminDocumentRecognition(
      status: 'DONE',
      engineVersion: 'rules-v1',
      durationMs: 42,
      fields: {
        'fullName': AdminRecognizedField(value: 'Ерлан Тохтаров', confidence: 0.9, checksumOk: true, needsReview: false, match: null),
        'iin': AdminRecognizedField(value: '850712345611', confidence: 0.95, checksumOk: true, needsReview: false, match: 'blacklisted'),
      },
    );

List<Override> _overrides() => [
      adminVerificationSelectedIdProvider.overrideWith((ref) => 'd1'),
      adminVerificationDriverProfileProvider('d1').overrideWith((ref) async => _profile()),
      adminDocumentRecognitionProvider('doc1').overrideWith((ref) async => _recognition()),
    ];

void main() {
  testWidgets('renders the recognition panel with a blacklist banner without a layout exception', (tester) async {
    // Контент внутри ListView (большой _BigViewer + панель «Распознано»)
    // не влезает в дефолтный тестовый вьюпорт 800x600 — часть элементов
    // sliver'ами не строится за пределами cacheExtent. Достаточно высокое
    // окно гарантирует, что весь ListView строится целиком, без скролла.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const VerificationScreen(),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Распознано'), findsOneWidget);
    expect(find.text('Совпадение с чёрным списком — подтвердить без явного решения нельзя'), findsWidgets);
  });

  testWidgets('renders correctly at a 390px mobile width too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const VerificationScreen(),
      ),
    ));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
  });
}
