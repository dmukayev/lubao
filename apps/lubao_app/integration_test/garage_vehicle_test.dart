// Задача 034, сценарий 7: гараж — добавить прицеп с синтетическим фото
// техпаспорта, выбрать шаблон размера (033) → прицеп «на проверке»; документ
// распознан (OCR): госномер, VIN и грузоподъёмность достались из фото.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: гараж → прицеп с фото техпаспорта → размер → «на проверке» → документ распознан', (tester) async {
    final run = E2eRun(binding, 'garage_vehicle');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход-водителя', () async {
      await loginDriver(tester, '7010000001');
      await waitFor(tester, find.byType(NavigationBar));
    });

    await run.step(tester, 'гараж', () async {
      await goTab(tester, t.profileTitle);
      await reveal(tester, find.text(t.garageGoToGarage));
      await tester.tap(find.text(t.garageGoToGarage));
      // Список машин длиннее экрана SE с крупным шрифтом — кнопка внизу.
      await waitAndReveal(tester, find.byKey(const Key('garageAddVehicle')));
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'шторка-добавления', () async {
      final add = find.byKey(const Key('garageAddVehicle'));
      await reveal(tester, add);
      await tester.tap(add);
      await waitFor(tester, find.byKey(const Key('addVehicleKindTrailer')));
      await tester.tap(find.byKey(const Key('addVehicleKindTrailer')));
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'поля-прицепа', () async {
      await tester.tap(find.byKey(const Key('addVehicleBodyType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тентованный').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('addVehicleCapacity')), '20');
      await tester.enterText(find.byKey(const Key('addVehicleLength')), '13.6');
      // Шаблон размера (033): первый из предложенных для «Тент».
      final preset = find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('addVehicleSizePreset-')).first;
      await reveal(tester, preset);
      await tester.tap(preset);
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'фото-техпаспорта', () async {
      final photo = await makeSyntheticDocument('trailer-passport.png', [
        'VEHICLE REGISTRATION',
        'Plate 123ABC02',
        'VIN WDB9634031L123456',
        'Max mass 40000 kg',
        'Tare mass 20000 kg',
      ]);
      usePhoto(photo);
      final gallery = find.byKey(const Key('addVehiclePhotoGallery'));
      await reveal(tester, gallery);
      await tester.tap(gallery);
      await acceptPdConsentIfAsked(tester);
      expect(find.text('trailer-passport.png'), findsOneWidget);
    });

    await run.step(tester, 'отправка-на-проверку', () async {
      final submit = find.byKey(const Key('addVehicleSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      // 044 п.7: шаг «Сфотографируйте машину» — спереди снимаем, сбоку пропускаем.
      await waitFor(tester, find.byKey(const Key('vehiclePhotosSheet')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('vehiclePhoto-vehiclePhotoFront')));
      await acceptPdConsentIfAsked(tester);
      await waitFor(tester, find.descendant(of: find.byKey(const Key('vehiclePhoto-vehiclePhotoFront')), matching: find.byIcon(LucideIcons.checkCircle2)));
      await tester.tap(find.byKey(const Key('vehiclePhotosDone')));
      await waitFor(tester, find.text(t.garagePending));
      expect(find.text(t.garagePending), findsWidgets);
      // Сбоку фото нет — мягкое напоминание в карточке.
      expect(find.text(t.garagePhotosReminder), findsWidgets);
      // Размер прицепа из шаблона виден в карточке: «… м³ · … пал.».
      expect(find.textContaining(t.unitM3), findsWidgets);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'документ-распознан-OCR', () async {
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      final repo = container.read(driverRepositoryProvider);
      final docs = await repo.verificationDocuments();
      final doc = docs.where((d) => d.type == VerificationDocType.trailerPassport).first;
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      AdminDocumentRecognition? recognition;
      while (DateTime.now().isBefore(deadline)) {
        recognition = await repo.documentRecognition(doc.id);
        if (recognition.status != 'PENDING') break;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      expect(recognition?.status, 'DONE', reason: 'OCR не отработал (контейнер lubao-e2e-ocr поднят?)');
      expect(recognition!.fields['plateNumber']?.value, '123ABC02');
      expect(recognition.fields['vin']?.value, 'WDB9634031L123456');
      expect(recognition.fields['capacityTons']?.value, '20.0');
    });
  });
}
