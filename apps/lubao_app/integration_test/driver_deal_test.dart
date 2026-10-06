// Задача 034, сценарий 6 + шаги 037: водитель откликается на три груза
// (10 + 8 + 10 т на 20-тонный прицеп), логист (через API — «параллельный
// сценарий») выбирает его на каждый; водитель подтверждает перевозку и
// ведёт первую сделку «Загружен» → «В пути»; вторая (догруз 8 т) тоже
// подтверждается, третья (+10 т) — упирается в «Машина заполнена».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: отклик → выбор → подтверждение → статусы; догруз; «Машина заполнена»', (tester) async {
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));

    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await loginDriver(tester, '7010000002');
    await waitFor(tester, find.byKey(const Key('driverAnnounceArrivalButton')));

    // --- Отклики на три груза ---
    for (final cargoId in [e2eCargo1, e2eCargo2, e2eCargo3]) {
      final card = find.byKey(Key('feedCargoCard-$cargoId'));
      await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('cargoDetailRespondButton')));
      await tester.tap(find.byKey(const Key('cargoDetailRespondButton')));
      await waitFor(tester, find.text(t.cargoAlreadyResponded));
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    }

    // --- Логист выбирает водителя на каждый груз (через API) ---
    final logist = await LogistApi.login();
    final deal1 = await logist.selectFirstResponse(e2eCargo1);
    final deal2 = await logist.selectFirstResponse(e2eCargo2);
    final deal3 = await logist.selectFirstResponse(e2eCargo3);

    // --- Сделки водителя ---
    await tester.tap(find.text(t.navDeals));
    await waitFor(tester, find.byKey(Key('driverDealCard-$deal1')));
    expectInsideSafeZone(tester);

    Future<void> openDeal(String dealId) async {
      final card = find.byKey(Key('driverDealCard-$dealId'));
      await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('dealNextStatusButton')));
    }

    Future<void> advance(String fromLabel, String toLabel) async {
      expect(find.descendant(of: find.byKey(const Key('dealNextStatusButton')), matching: find.text(fromLabel)), findsOneWidget);
      await tester.tap(find.byKey(const Key('dealNextStatusButton')));
      await waitFor(tester, find.descendant(of: find.byKey(const Key('dealNextStatusButton')), matching: find.text(toLabel)));
    }

    // Сделка 1 (10 т): подтверждение → «Груз загружен» → «В пути».
    await openDeal(deal1);
    await advance(t.dealConfirm, t.dealMarkLoaded);
    await advance(t.dealMarkLoaded, t.dealMarkInTransit);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();

    // Сделка 2 (8 т): догруз 10 + 8 = 18 ≤ 20 т — подтверждается.
    await openDeal(deal2);
    await advance(t.dealConfirm, t.dealMarkLoaded);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();

    // Сделка 3 (+10 т = 28 > 20): «Машина заполнена», подтверждения нет.
    await openDeal(deal3);
    await tester.tap(find.byKey(const Key('dealNextStatusButton')));
    await waitFor(tester, find.text(t.dealVehicleFullTitle));
    expect(find.text(t.dealVehicleFullOpenCurrent), findsOneWidget);
    expectNoOverflow(tester);
  });
}
