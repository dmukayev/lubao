// Задача 034, сценарий 6 (+049 п.1): водитель откликается на три груза,
// логист (через API — «параллельный сценарий») выбирает его на каждый;
// водитель ведёт первую сделку до «В пути». Догруз выключен флагом — вторую
// на ту же машину не подтвердить («одна перевозка за раз»), после доставки
// первой — подтверждается; третья снова упирается в шторку.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: отклик → выбор → подтверждение → статусы; одна перевозка за раз', (tester) async {
    final run = E2eRun(binding, 'driver_deal');
    await clearPersistedSession();
    // Системный диалог геолокации робот нажать не может — подменяем запрос ОС
    // (041, п.11); сама шторка согласия и логика приложения — настоящие.
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));

    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await run.step(tester, 'вход', () async {
      await loginDriver(tester, '7010000002');
      await waitFor(tester, find.byKey(const Key('driverStatusBar')));
    });

    await run.step(tester, 'отклики-на-три-груза', () async {
      for (final cargoId in [e2eCargo1, e2eCargo2, e2eCargo3]) {
        final card = find.byKey(Key('feedCargoCard-$cargoId'));
        await reveal(tester, card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await waitFor(tester, find.byKey(const Key('cargoDetailRespondButton')));
        await tester.tap(find.byKey(const Key('cargoDetailRespondButton')));
        await waitFor(tester, find.text(t.cargoAlreadyResponded));
        await tester.tap(find.byType(BackButton).first);
        await tester.pumpAndSettle();
      }
    });

    late String deal1, deal2, deal3;
    await run.step(tester, 'логист-выбирает-через-API', () async {
      final logist = await LogistApi.login();
      deal1 = await logist.selectFirstResponse(e2eCargo1);
      deal2 = await logist.selectFirstResponse(e2eCargo2);
      deal3 = await logist.selectFirstResponse(e2eCargo3);
      await tester.tap(find.text(t.navDeals));
      await waitFor(tester, find.byKey(Key('driverDealCard-$deal1')));
      expectInsideSafeZone(tester);
    });

    // Груз с активной сделкой исчезает из ленты (041, п.2).
    await run.step(tester, 'груз-со-сделкой-исчез-из-ленты', () async {
      await goTab(tester, t.navCargos);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feedCargoCard-$e2eCargo1')), findsNothing);
      expect(find.byKey(const Key('feedCargoCard-$e2eCargo2')), findsNothing);
      await goTab(tester, t.navDeals);
      await waitFor(tester, find.byKey(Key('driverDealCard-$deal1')));
    });

    Future<void> openDeal(String dealId) async {
      final card = find.byKey(Key('driverDealCard-$dealId'));
      await reveal(tester, card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('dealNextStatusButton')));
    }

    Future<void> advance(String fromLabel, String toLabel) async {
      final button = find.byKey(const Key('dealNextStatusButton'));
      await waitAndReveal(tester, button);
      expect(find.descendant(of: button, matching: find.text(fromLabel)), findsOneWidget);
      await tester.tap(button);
      await waitAndReveal(tester, find.descendant(of: button, matching: find.text(toLabel)));
    }

    TrackingConsent consent() => ProviderScope.containerOf(tester.element(find.byType(LubaoApp))).read(trackingConsentProvider);

    // 041, п.11: «Загружен» — отдельное согласие на местоположение в рейсе.
    // Закрыли шторку, не нажав «Понятно» — сделка двигается, согласия нет, координаты не уйдут.
    await run.step(tester, 'сделка1-загружен-без-согласия-на-трекинг', () async {
      await openDeal(deal1);
      await advance(t.dealConfirm, t.dealMarkLoaded);
      expect(consent().trip, isFalse);
      await waitAndReveal(tester, find.byKey(const Key('dealNextStatusButton')));
      await tester.tap(find.byKey(const Key('dealNextStatusButton')));
      await waitFor(tester, find.byKey(const Key('tripTrackingConsentSheet')));
      expect(find.text(t.tripTrackingConsentTitle), findsOneWidget);
      expect(find.text(t.tripTrackingConsentBody), findsOneWidget);
      expectInsideSafeZone(tester);
      // Закрываем шторку касанием по затемнению.
      await tester.tapAt(const Offset(20, 80));
      await waitFor(tester, find.descendant(of: find.byKey(const Key('dealNextStatusButton')), matching: find.text(t.dealMarkInTransit)));
      expect(consent().trip, isFalse, reason: 'без «Понятно» согласия на рейс нет, репортер не стартует');
      // Переключатель в карточке на паузе: логист не видит местоположение.
      expect(tester.widget<SwitchListTile>(find.byKey(const Key('tripTrackingSwitch'))).value, isFalse);
      await advance(t.dealMarkInTransit, t.dealMarkDelivered);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // 044: после «Подтверждаю перевозку» логист открывает пакет документов и
    // скачивает PDF; водитель видит «Логист открыл документы».
    await run.step(tester, 'логист-открыл-документы-водитель-видит', () async {
      final logist = await LogistApi.login();
      final notYet = await logist.driverDocuments(deal3);
      expect(notYet.statusCode, 403, reason: 'до подтверждения водителем документы закрыты');
      final pkg = await logist.driverDocuments(deal1);
      expect(pkg.statusCode, 200);
      expect((pkg.data as Map)['driver']['fullName'], isNotEmpty);
      final pdf = await logist.driverDocumentsPdf(deal1);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      await openDeal(deal1);
      await waitAndReveal(tester, find.byKey(const Key('driverDocsOpened')));
      await tester.tap(find.byKey(const Key('driverDocsOpened')));
      await waitFor(tester, find.text(t.dealDocsAccessTitle));
      expectInsideSafeZone(tester);
      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // 049 п.1: догруз выключен — пока первая сделка в пути, вторую на ту же
    // машину не подтвердить: шторка «одна перевозка за раз».
    await run.step(tester, 'сделка2-одна-перевозка-за-раз', () async {
      await openDeal(deal2);
      await waitAndReveal(tester, find.byKey(const Key('dealNextStatusButton')));
      await tester.tap(find.byKey(const Key('dealNextStatusButton')));
      await waitFor(tester, find.text(t.dealVehicleOneDealTitle));
      expect(find.text(t.dealVehicleOneDealBody), findsOneWidget);
      expect(find.text(t.dealVehicleFullOpenCurrent), findsOneWidget);
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
      await tester.tapAt(const Offset(20, 80)); // закрыть шторку
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // 045 п.11: после «Доставлено» — «Вы в Алматы. Ищете груз отсюда?» одним касанием.
    await run.step(tester, 'доставлено-ищете-груз-отсюда', () async {
      await openDeal(deal1);
      final next = find.byKey(const Key('dealNextStatusButton'));
      await waitAndReveal(tester, next);
      expect(find.descendant(of: next, matching: find.text(t.dealMarkDelivered)), findsOneWidget);
      await tester.tap(next);
      await waitFor(tester, find.text(t.deliveredAskTitle('Алматы')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('deliveredLookHere')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // Первая доставлена — машина свободна: второй рейс подтверждается.
    // «Понятно» → согласие дано, переключатель включён, пауза работает.
    await run.step(tester, 'сделка2-согласие-на-трекинг-и-пауза', () async {
      await openDeal(deal2);
      await advance(t.dealConfirm, t.dealMarkLoaded);
      await waitAndReveal(tester, find.byKey(const Key('dealNextStatusButton')));
      await tester.tap(find.byKey(const Key('dealNextStatusButton')));
      await waitFor(tester, find.byKey(const Key('consentUnderstoodButton')));
      await tester.tap(find.byKey(const Key('consentUnderstoodButton')));
      await waitFor(tester, find.descendant(of: find.byKey(const Key('dealNextStatusButton')), matching: find.text(t.dealMarkInTransit)));
      expect(consent().trip, isTrue);
      expect(consent().tripSharingActive, isTrue);
      final switchTile = find.byKey(const Key('tripTrackingSwitch'));
      await reveal(tester, switchTile);
      expect(tester.widget<SwitchListTile>(switchTile).value, isTrue);
      expect(find.text(t.tripTrackingSwitchOn), findsOneWidget);
      // Пауза: согласие остаётся, передача выключена.
      await tester.tap(switchTile);
      await tester.pumpAndSettle();
      expect(consent().trip, isTrue);
      expect(consent().tripPaused, isTrue);
      expect(find.text(t.tripTrackingSwitchPaused), findsOneWidget);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();
      expect(consent().tripSharingActive, isTrue);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      // Второй рейс «загружен» — статус «В рейсе»; анонс «Ищу груз из Алматы»
      // погас сам при подтверждении (040 п.4).
      await goTab(tester, t.navFeed);
      await waitFor(tester, find.byKey(const Key('driverStatus-inTrip')));
      await goTab(tester, t.navDeals);
    });

    await run.step(tester, 'сделка3-одна-перевозка-за-раз', () async {
      await openDeal(deal3);
      await waitAndReveal(tester, find.byKey(const Key('dealNextStatusButton')));
      await tester.tap(find.byKey(const Key('dealNextStatusButton')));
      await waitFor(tester, find.text(t.dealVehicleOneDealTitle));
      expectInsideSafeZone(tester);
      await tester.tapAt(const Offset(20, 80));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    Future<void> tapInDialog(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // 046 п.1: причина — чипом из списка; «Другое» требует текст.
    await run.step(tester, 'отмена-причина-из-списка', () async {
      await openDeal(deal3);
      await waitAndReveal(tester, find.byKey(const Key('dealCancelButton')));
      await tester.tap(find.byKey(const Key('dealCancelButton')));
      await waitFor(tester, find.byKey(const Key('cancelReason_VEHICLE_BREAKDOWN')));
      expect(find.byKey(const Key('cancelReason_TOOK_OTHER_CARGO')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('cancelSubmit'))).onPressed, isNull);
      await tapInDialog(find.byKey(const Key('cancelReason_OTHER')));
      await waitFor(tester, find.byKey(const Key('cancelOtherText')));
      expect(tester.widget<FilledButton>(find.byKey(const Key('cancelSubmit'))).onPressed, isNull);
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
      await tapInDialog(find.byKey(const Key('cancelReason_TERMS_CHANGED')));
      await tapInDialog(find.byKey(const Key('cancelSubmit')));
      await waitFor(tester, find.byKey(const Key('dealCancelReason')));
      expect(find.textContaining(t.cancelReasonTermsChanged), findsOneWidget);
      expect(find.textContaining(t.cancelStageBeforeConfirm), findsOneWidget);
      // Отмена до подтверждения — жалобу не предлагаем.
      expect(find.byKey(const Key('complaintOffer')), findsNothing);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // 046 п.6: отмена «Загружен» по своей вине → сразу «Пожаловаться» со сделкой.
    await run.step(tester, 'отмена-после-загрузки-и-жалоба', () async {
      await openDeal(deal2);
      await waitAndReveal(tester, find.byKey(const Key('dealCancelButton')));
      await tester.tap(find.byKey(const Key('dealCancelButton')));
      await waitFor(tester, find.byKey(const Key('cancelReason_VEHICLE_BREAKDOWN')));
      await tapInDialog(find.byKey(const Key('cancelReason_VEHICLE_BREAKDOWN')));
      await tapInDialog(find.byKey(const Key('cancelSubmit')));
      await waitFor(tester, find.byKey(const Key('complaintOffer')));
      expectInsideSafeZone(tester);
      await tester.enterText(find.byKey(const Key('complaintText')), 'E2E: машина сломалась после загрузки');
      await tapInDialog(find.byKey(const Key('complaintSubmit')));
      await waitFor(tester, find.text(t.complaintSent));
      await waitFor(tester, find.byKey(const Key('dealCancelReason')));
      expect(find.textContaining(t.cancelStageAfterLoad), findsOneWidget);
      await waitAndReveal(tester, find.byKey(const Key('dealComplain')));
    });
  });
}
