// Задача 034, сценарии 11 и 12 (часть приложения): два НОВЫХ водителя
// регистрируются по SMS (мастер из трёх шагов) и загружают селфи и права:
//  A — с собственным синтетическим ИИН (его подтвердит админ, сценарий 11);
//  B — с тем же ИИН, что у заблокированного администратором водителя
//      (сценарий 12: в проверке ⛔, «Подтвердить» неактивна).
// ИИН распознаётся OCR — это проверяется здесь же.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
        if (tag == 'A') {
          // 045 п.7–8: страна → уточнить область по тапу; допуски — тут же, необязательно.
          final kz = find.byKey(const Key('driverSetupCountry-KZ'));
          await reveal(tester, kz);
          await tester.tap(kz);
          await tester.pumpAndSettle();
          final regions = find.byKey(const Key('directionRegions-KZ'));
          await reveal(tester, regions);
          expect(find.descendant(of: regions, matching: find.text(t.directionRegionsAll)), findsOneWidget);
          await tester.tap(regions);
          await tester.pumpAndSettle();
          await tester.tap(find.byType(CheckboxListTile).at(1));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('directionRegionsDone')));
          await tester.pumpAndSettle();
          expect(find.descendant(of: regions, matching: find.text(t.directionRegionsCount(1))), findsOneWidget);
          await waitAndReveal(tester, find.text(t.driverSetupPermitsOptional));
          expectNoOverflow(tester);
        }
        await reveal(tester, find.byKey(const Key('driverSetupNext')));
        await tester.tap(find.byKey(const Key('driverSetupNext')));
        await waitFor(tester, find.byType(NavigationBar));
      });
      // 045 п.9, 11: сразу главная и одна шторка «Где вы сейчас?» — без
      // отдельного шага и без автоматического анонса.
      await run.step(tester, '$tag-где-вы-сейчас', () async {
        await waitFor(tester, find.byKey(const Key('whereNowSheet')));
        expectInsideSafeZone(tester);
        expectNoOverflow(tester);
        if (tag == 'A') {
          final looking = find.byKey(const Key('whereNowLooking'));
          expect(find.descendant(of: looking, matching: find.text(t.statusLookingFrom('Алматы'))), findsOneWidget);
          await reveal(tester, looking);
          await tester.tap(looking);
          await waitFor(tester, find.byKey(const Key('driverStatus-lookingHere')));
          // Логист видит его в «Кто свободен».
          final logist = Dio(BaseOptions(baseUrl: e2eApiBase, connectTimeout: e2eHttpTimeout, receiveTimeout: e2eHttpTimeout, validateStatus: (_) => true));
          final login = await logist.post('/auth/company/login', data: {'email': 'e2e-owner@lubao-test.kz', 'password': e2ePassword, 'deviceName': 'e2e', 'platform': 'ios'});
          final rows = (await logist.get('/arrivals', options: Options(headers: {'authorization': 'Bearer ${login.data['accessToken']}'}))).data as List<dynamic>;
          expect(rows.any((r) => r['driverName'] == fullName), isTrue, reason: '«Ищу груз из Алматы» — виден логисту');
        } else {
          await tester.tap(find.byKey(const Key('whereNowNotLooking')));
          await waitFor(tester, find.byKey(const Key('driverStatus-notLooking')));
        }
      });
      if (tag == 'A') {
        // 045 п.5: регистрация не создаёт машин-заглушек — гараж пуст, одна
        // карточка-призыв; лента при этом уже показывает грузы (по предпочтению).
        await run.step(tester, '$tag-гараж-пуст-после-регистрации', () async {
          await goTab(tester, t.profileTitle);
          final garage = find.text(t.garageGoToGarage);
          await reveal(tester, garage);
          await tester.tap(garage);
          await waitFor(tester, find.byKey(const Key('garageEmptyCta')));
          expect(find.text(t.garageKindTractor), findsNothing, reason: 'нет заглушки «Тягач»');
          expect(find.text(t.garageNoPlate), findsNothing);
          expectInsideSafeZone(tester);
          expectNoOverflow(tester);
          await tester.tap(find.byType(BackButton).first);
          await tester.pumpAndSettle();
          await goTab(tester, t.navFeed);
          await waitAndReveal(tester, find.byKey(const Key('feedCargoCard-$e2eCargo5')));
        });
        // Новичок без проверки откликается (041, п.1): гейт — только на «Подтверждаю».
        await run.step(tester, '$tag-новичок-откликается-без-проверки', () async {
          final card = find.byKey(const Key('feedCargoCard-$e2eCargo5'));
          await reveal(tester, card);
          await tester.tap(card);
          await waitFor(tester, find.byKey(const Key('cargoDetailRespondButton')));
          // 043 п.11: до отклика — подсказка, как открыть телефон.
          expect(find.byKey(const Key('cargoContactLockedHint')), findsOneWidget);
          await tester.tap(find.byKey(const Key('cargoDetailRespondButton')));
          await waitFor(tester, find.text(t.cargoAlreadyResponded));
          expect(find.byKey(const Key('cargoVerifyHint')), findsOneWidget, reason: 'после отклика — мягкая подсказка про проверку');
          await tester.tap(find.byType(BackButton).first);
          await tester.pumpAndSettle();
          // 045 п.2: в ленте у груза — «Вы откликнулись», а не «Опубликован».
          final feedCard = find.byKey(const Key('feedCargoCard-$e2eCargo5'));
          await waitAndReveal(tester, feedCard);
          await waitFor(tester, find.descendant(of: feedCard, matching: find.text(t.feedStateResponded)));
          expect(find.descendant(of: feedCard, matching: find.text(t.cargoStatusPublished)), findsNothing);
          // 045 п.3: над лентой — «Ваши отклики: 1 · ждут ответа 1», тап → «Мои отклики».
          final summary = find.byKey(const Key('homeMyResponses'));
          await waitAndReveal(tester, summary);
          expect(find.descendant(of: summary, matching: find.textContaining(t.homeMyResponsesPending(1))), findsOneWidget);
          await tester.tap(summary);
          await waitFor(tester, find.text(t.myResponsesTitle));
          await tester.tap(find.byType(BackButton).first);
          await tester.pumpAndSettle();
        });
        // 043 п.11: телефон логиста новичку — только после отклика «Готов взять».
        await run.step(tester, '$tag-телефон-после-отклика', () async {
          GoRouter.of(tester.element(find.byType(NavigationBar))).push('/driver/cargo/$e2eCargoKz');
          final call = find.byKey(const Key('cargoDetailCallButton'));
          await waitFor(tester, call);
          expect(tester.widget<IconSquareButton>(call).onPressed, isNull, reason: 'до отклика номер закрыт');
          final respond = find.byKey(const Key('cargoDetailRespondButton'));
          await tester.tap(respond);
          await waitFor(tester, find.text(t.cargoAlreadyResponded));
          expect(tester.widget<IconSquareButton>(call).onPressed, isNotNull, reason: '«Готов взять» → «Позвонить» появляется');
          final launcher = useFakeUrlLauncher();
          await tester.tap(call);
          final deadline = DateTime.now().add(const Duration(seconds: 10));
          while (launcher.launched.isEmpty && DateTime.now().isBefore(deadline)) {
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(launcher.launched.single, startsWith('tel:'), reason: 'номер пришёл по нажатию');
          expectInsideSafeZone(tester);
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
