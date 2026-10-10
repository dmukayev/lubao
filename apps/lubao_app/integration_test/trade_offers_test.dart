// Задача 058: груз на 2 машины с авансом в рублях — водитель видит «аванс ·
// нал.», «нужно 2», флаги; ☆ → «Избранное»; своя цена → встречная логиста →
// «Согласен» → сделка с итоговой ценой; второй водитель → груз ушёл из ленты;
// компания добавила водителя → «Принять» → он в «Моих»; «был в сети».
// Логист — через API (вторая e2e-компания, чтобы не трогать счётчики первой).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

const _kzLogist = 'e2e-owner@lubao-test.kz';

Future<Map<String, dynamic>> _cargoBody() async {
  final ref = (await Dio(BaseOptions(baseUrl: e2eApiBase)).get('/reference-data')).data as Map;
  final points = (ref['points'] as List).cast<Map>();
  final countries = (ref['countries'] as List).cast<Map>();
  final cities = (ref['cities'] as List).cast<Map>();
  final ru = countries.firstWhere((c) => c['code'] == 'RU');
  final moscow = cities.firstWhere((c) => c['countryId'] == ru['id'] && c['code'] == 'RU-MOSCOW');
  final tent = (ref['bodyTypes'] as List).cast<Map>().firstWhere((b) => b['code'] == 'TENT');
  final category = (ref['cargoCategories'] as List).cast<Map>().firstWhere((c) => c['isActive'] != false);
  final khorgos = points.firstWhere((p) => '${(p['name'] as Map)['ru']}'.contains('Хоргос'), orElse: () => points.first);
  return {
    'pointId': khorgos['id'],
    'destinationCountryId': ru['id'],
    'destinationCityId': moscow['id'],
    'bodyTypeId': tent['id'],
    'categoryId': category['id'],
    'weightKg': 20000,
    'volumeM3': 82,
    'price': 1250000,
    'currency': 'RUB',
    'advanceAmount': 300000,
    'paymentForm': 'CASH',
    'trucksNeeded': 2,
    'readyDate': ymd(DateTime.now().add(const Duration(days: 1))),
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('058: условия оплаты, несколько машин, своя и встречная цена, избранное, «Мои водители»', (tester) async {
    final run = E2eRun(binding, 'trade_offers');
    await clearPersistedSession();
    late LogistApi logist;
    late String cargoId;
    await run.step(tester, 'логист-публикует-груз-на-2-машины-в-рублях', () async {
      logist = await LogistApi.login(email: _kzLogist);
      cargoId = await logist.publishCargo(await _cargoBody());
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход-водителя', () async {
      await loginDriver(tester, '7010000005');
      await waitFor(tester, find.byKey(const Key('driverStatusBar')));
    });

    // До торга: сделок с этой компанией ещё нет — номер в Lubao → приглашение.
    await run.step(tester, 'компания-добавила-водителя-принять', () async {
      final res = await logist.createDriver('Ержан', '+7 701 000 00 05');
      expect(res['result'], 'INVITED_EXISTING');
      // Список «компаний» водителя перечитывается при входе на экран (до 3 попыток).
      final accept = find.byKey(const Key('companyInviteAccept-33333333-3333-4333-8333-333333333002'));
      for (var i = 0; i < 3 && accept.evaluate().isEmpty; i++) {
        await goTab(tester, t.profileTitle);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await goTab(tester, t.navFeed);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await waitFor(tester, accept, timeout: const Duration(seconds: 20));
      await tester.tap(accept);
      await tester.pumpAndSettle();
      final mine = await logist.myDrivers();
      expect(mine.any((d) => d['driverId'] == 'dddddddd-dddd-4ddd-8ddd-ddddddddd005' && d['status'] == 'ACTIVE'), isTrue);
    });

    final card = find.byKey(Key('feedCargoCard-$cargoId'));
    await run.step(tester, 'лента-аванс-нал-нужно-2-флаги', () async {
      await reveal(tester, card);
      await tester.pumpAndSettle();
      final terms = tester.widget<Text>(find.byKey(Key('feedCargoTerms-$cargoId')));
      expect(terms.data, contains('300 000 ₽'));
      expect(terms.data, contains(t.paymentFormCashShort));
      expect(find.descendant(of: card, matching: find.text(t.cargoTrucksLeft('2', '2'))), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining('🇷🇺')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining('1 250 000 ₽')), findsWidgets);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'звезда-в-избранное', () async {
      await tester.tap(find.byKey(Key('favoriteCargo-$cargoId')).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.navTrips);
      await waitFor(tester, find.byKey(Key('favoriteTripCard-$cargoId')));
      await goTab(tester, t.navFeed);
    });

    await run.step(tester, 'своя-цена', () async {
      await reveal(tester, card);
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('offerProposeButton')));
      await tester.tap(find.byKey(const Key('offerProposeButton')));
      await waitFor(tester, find.byKey(const Key('offerPrice')));
      await tester.enterText(find.byKey(const Key('offerPrice')), '1150000');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('offerSend')));
      await waitFor(tester, find.byKey(const Key('offerSentText')));
      expect(find.text(t.offerSent('1 150 000 ₽')), findsOneWidget);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'встречная-цена-логиста-и-согласен', () async {
      final mine = (await logist.pendingResponses(cargoId)).first;
      await logist.counterOffer(mine['id'] as String, 1200000);
      // Встречная приходит по сокету (responses:updated) — карточка обновится сама.
      await waitFor(tester, find.byKey(const Key('offerCounterCard')), timeout: const Duration(seconds: 20));
      expect(find.text(t.offerCounterFromLogist('1 200 000 ₽')), findsOneWidget);
      await tester.tap(find.byKey(const Key('offerCounterAgree')));
      await waitFor(tester, find.byKey(const Key('dealPrice')));
      expect(tester.widget<Text>(find.byKey(const Key('dealPrice'))).data, '1 200 000 ₽');
      expect(find.byKey(const Key('dealTerms')), findsOneWidget);
    });

    await run.step(tester, 'второй-водитель-груз-ушёл-из-ленты', () async {
      await (await DriverApi.login('+77010000004')).respond(cargoId);
      final second = (await logist.pendingResponses(cargoId)).first;
      await logist.select(second['id'] as String);
      // Сделка открыта поверх карточки груза — назад до нижнего меню.
      for (var i = 0; i < 3 && find.byType(NavigationBar).evaluate().isEmpty; i++) {
        await tester.tap(find.byType(BackButton).first);
        await tester.pumpAndSettle();
      }
      await goTab(tester, t.navFeed);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(card, findsNothing);
    });

    await run.step(tester, 'был-в-сети', () async {
      final mine = await logist.myDrivers();
      final me = mine.firstWhere((d) => d['driverId'] == 'dddddddd-dddd-4ddd-8ddd-ddddddddd005');
      expect(me['lastSeenAt'], isNotNull, reason: 'водитель только что ходил в API — «в сети»');
      await goTab(tester, t.profileTitle);
      await waitFor(tester, find.byKey(const Key('driverCompaniesSection')));
    });
  });
}
