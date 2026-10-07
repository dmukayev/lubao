// Задача 034, сценарии 11 и 12 (часть приложения): два НОВЫХ водителя
// регистрируются по SMS (мастер из трёх шагов) и загружают селфи и права:
//  A — с собственным синтетическим ИИН (его подтвердит админ, сценарий 11);
//  B — с тем же ИИН, что у заблокированного администратором водителя
//      (сценарий 12: в проверке ⛔, «Подтвердить» неактивна).
// ИИН распознаётся OCR — это проверяется здесь же.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

/// Синтетические ИИН (контрольная сумма верна, людям не принадлежат).
const e2eIinDriverA = '950302502008';
const e2eIinBlockedDriver = '900101500109';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('новые водители: регистрация → селфи и права с ИИН → ИИН распознан', (tester) async {
    final run = E2eRun(binding, 'driver_register_iin');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    Future<void> register(String tag, String phoneLocal, String fullName, String iin, String licenseNo) async {
      await run.step(tester, '$tag-вход-нового-номера', () async {
        await loginDriver(tester, phoneLocal);
        await waitFor(tester, find.byKey(const Key('driverSetupFullName')));
        expectInsideSafeZone(tester);
      });
      await run.step(tester, '$tag-мастер-шаг1-имя-город', () async {
        await tester.enterText(find.byKey(const Key('driverSetupFullName')), fullName);
        await tester.enterText(find.byKey(const Key('driverSetupHomeCity')), 'Алматы');
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Алматы').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('driverSetupNext')));
        await tester.pumpAndSettle();
      });
      await run.step(tester, '$tag-мастер-шаг2-кузов', () async {
        await tester.tap(find.byKey(const Key('driverSetupBody-TENT')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('driverSetupCapacity-20')));
        await tester.tap(find.byKey(const Key('driverSetupCapacity-20')));
        await tester.pumpAndSettle();
        expectInsideSafeZone(tester);
        await tester.tap(find.byKey(const Key('driverSetupNext')));
        await tester.pumpAndSettle();
      });
      await run.step(tester, '$tag-мастер-шаг3-готово', () async {
        await tester.tap(find.byKey(const Key('driverSetupNext')));
        await waitFor(tester, find.byType(NavigationBar));
      });
      if (tag == 'A') {
        // Новичок без проверки откликается (041, п.1): гейт — только на «Подтверждаю».
        await run.step(tester, '$tag-новичок-откликается-без-проверки', () async {
          final card = find.byKey(const Key('feedCargoCard-$e2eCargo5'));
          await reveal(tester, card);
          await tester.tap(card);
          await waitFor(tester, find.byKey(const Key('cargoDetailRespondButton')));
          expect(find.byKey(const Key('cargoVerifyHint')), findsOneWidget, reason: 'мягкая подсказка про проверку');
          await tester.tap(find.byKey(const Key('cargoDetailRespondButton')));
          await waitFor(tester, find.text(t.cargoAlreadyResponded));
          await tester.tap(find.byType(BackButton).first);
          await tester.pumpAndSettle();
        });
      }
      await run.step(tester, '$tag-селфи-и-права', () async {
        await goTab(tester, t.profileTitle);
        final verify = find.byKey(const Key('driverProfileVerifyButton'));
        await reveal(tester, verify);
        await tester.tap(verify);
        await waitFor(tester, find.byKey(const Key('driverVerifyGallery-selfie')));
        usePhoto(await makeSyntheticDocument('selfie-$tag.png', ['SELFIE', fullName]));
        await tester.tap(find.byKey(const Key('driverVerifyGallery-selfie')));
        // 043 п.2: новый водитель — согласие на ПДн перед первой загрузкой.
        await acceptPdConsent(tester);
        await waitFor(tester, find.text(t.driverVerificationStatusPending));
        usePhoto(await makeSyntheticDocument('driver-license-$tag.png', [
          'ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ',
          fullName,
          'ИИН $iin',
          'Номер $licenseNo',
        ]));
        final gallery = find.byKey(const Key('driverVerifyGallery-driverLicense'));
        await reveal(tester, gallery);
        await tester.tap(gallery);
        await waitForCount(tester, find.text(t.driverVerificationStatusPending), 2);
        expectInsideSafeZone(tester);
      });
      await run.step(tester, '$tag-ИИН-распознан', () async {
        final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
        final repo = container.read(driverRepositoryProvider);
        final docs = await repo.verificationDocuments();
        final doc = docs.where((d) => d.type == VerificationDocType.driverLicense).first;
        final deadline = DateTime.now().add(const Duration(seconds: 90));
        AdminDocumentRecognition? recognition;
        while (DateTime.now().isBefore(deadline)) {
          recognition = await repo.documentRecognition(doc.id);
          if (recognition.status != 'PENDING') break;
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        expect(recognition?.status, 'DONE', reason: 'OCR не отработал');
        // Водителю — маска (ИИН целиком в ответ не отдаётся).
        expect(recognition!.fields['iin']?.value, '${iin.substring(0, 4)}••••${iin.substring(8)}');
      });
    }

    await register('A', '7010000006', 'Сергей Новиков', e2eIinDriverA, 'AB1234567');
    await run.step(tester, 'выход-A', () async {
      await tester.tap(find.byType(BackButton).first);
      await waitFor(tester, find.byType(NavigationBar));
      await logoutViaProfile(tester, driver: true);
    });
    await register('B', '7010000007', 'Руслан Дублёров', e2eIinBlockedDriver, 'CD7654321');
  });
}
