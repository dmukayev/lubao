// Задача 034: логист (email+пароль) → «Водители» (036) → «Проверенные» меняет
// список → чат с водителем → «Предложить груз» → «Пригласить» → сделка (035);
// затем тот же водитель входит, подтверждает перевозку и двигает «Загружен»
// прямо в карточке чата, не выходя из переписки.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('логист: «Водители» → фильтр → чат → пригласить → водитель подтверждает и грузит', (tester) async {
    final run = E2eRun(binding, 'logist_drivers');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход-логиста', () async {
      await loginLogist(tester);
      await waitFor(tester, find.text(t.navDrivers));
    });

    await run.step(tester, 'водители-экран', () async {
      await tester.tap(find.text(t.navDrivers));
      await waitFor(tester, find.text(t.driversAtPointTitleShort));
      await waitFor(tester, find.text('Борис Т.'));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
      // Единственная точка — чипа точки нет; в полосе дней «Сег», не «Сегодня».
      expect(find.byKey(const Key('driversPointChip')), findsNothing);
      expect(find.text(t.driversAtPointTodayShort), findsOneWidget);
      // Два водителя на точке: проверенный и нет.
      expect(find.text('Нурлан Х.'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('driverVerifiedPill-')), findsWidgets);
      final d4Card = find.ancestor(of: find.text('Нурлан Х.'), matching: find.byType(AppCard));
      expect(
        find.descendant(of: d4Card, matching: find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('driverVerifiedPill-'))),
        findsNothing,
        reason: 'у непроверенного водителя нет плашки «Проверен»',
      );
    });

    await run.step(tester, 'фильтр-проверенные', () async {
      final verified = find.byKey(const Key('driversFilterVerified'));
      await tester.scrollUntilVisible(verified, 80,
          scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal).at(1));
      await tester.ensureVisible(verified);
      await tester.pumpAndSettle();
      await tester.tap(verified);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Борис Т.'), findsOneWidget);
      expect(find.text('Нурлан Х.'), findsNothing, reason: 'непроверенный водитель должен пропасть из списка «Проверенные»');
      expectNoOverflow(tester);
      // Выключаем фильтр: непроверенный снова в списке.
      await tester.tap(verified);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Нурлан Х.'), findsOneWidget);
    });

    await run.step(tester, 'чат-с-водителем', () async {
      final card = find.ancestor(of: find.text('Борис Т.'), matching: find.byType(AppCard));
      final chatButton = find.descendant(
        of: card,
        matching: find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('driversAtPointChat-')),
      );
      await tester.tap(chatButton);
      await waitFor(tester, find.byKey(const Key('chatMessageInput')));
      expectInsideSafeZone(tester);
      const message = 'E2E: логист пишет водителю';
      await tester.enterText(find.byKey(const Key('chatMessageInput')), message);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatSendButton')));
      await waitFor(tester, find.text(message));
    });

    await run.step(tester, 'предложить-груз', () async {
      await tester.tap(find.byKey(const Key('chatOfferCargoButton')));
      await waitFor(tester, find.text(t.chatOfferCargoSheetTitle));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('chatCargoPickerItem-$e2eCargo4')));
      await waitFor(tester, find.byKey(const Key('chatCardActionButton')));
      expect(find.text(t.driversAtPointInvite), findsWidgets);
    });

    await run.step(tester, 'пригласить-сделка', () async {
      await tester.tap(find.byKey(const Key('chatCardActionButton')));
      // После приглашения кнопка «Пригласить» исчезает: сделка создана.
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.byKey(const Key('chatCardActionButton')).evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('Приглашение не создало сделку за 20 с');
        await tester.pump(const Duration(milliseconds: 300));
      }
      expectNoOverflow(tester);
    });

    await run.step(tester, 'выход-логиста', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await logoutViaProfile(tester, driver: false);
    });

    await run.step(tester, 'вход-водителя-D3', () async {
      await loginDriver(tester, '7010000003');
      await waitFor(tester, find.byType(NavigationBar));
    });

    await run.step(tester, 'чат-водителя-подтверждение', () async {
      await goTab(tester, t.navChats);
      await waitFor(tester, find.textContaining('E2E Test Logistics'));
      await tester.tap(find.textContaining('E2E Test Logistics').first);
      await waitFor(tester, find.byKey(const Key('chatConfirmButton')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('chatConfirmButton')));
      await waitFor(tester, find.byKey(const Key('chatCardNextStatusButton')));
      expect(find.descendant(of: find.byKey(const Key('chatCardNextStatusButton')), matching: find.text(t.dealMarkLoaded)), findsOneWidget);
    });

    await run.step(tester, 'загружен-в-карточке-чата', () async {
      await tester.tap(find.byKey(const Key('chatCardNextStatusButton')));
      await waitFor(
        tester,
        find.descendant(of: find.byKey(const Key('chatCardNextStatusButton')), matching: find.text(t.dealMarkInTransit)),
      );
      // Остались в чате: поле ввода на месте.
      expect(find.byKey(const Key('chatMessageInput')), findsOneWidget);
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });
  });
}
