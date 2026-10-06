// Задача 034 (логист) + шаги 036: вход email+пароль → «Водители»: экран
// компактный, без переполнений, фильтр «Проверенные», карточка водителя →
// чат → сообщение → «Предложить груз» (из чата без груза).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('логист: вход → «Водители» → фильтр → чат → предложить груз', (tester) async {
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));

    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await loginLogist(tester);

    // --- «Водители» (задача 036) ---
    await waitFor(tester, find.text(t.navDrivers));
    await tester.tap(find.text(t.navDrivers));
    await waitFor(tester, find.text(t.driversAtPointTitleShort));
    expectInsideSafeZone(tester);
    expectNoOverflow(tester);

    // Водитель D3 уже на точке (сид): компактное имя «Борис Т.», итоги.
    await waitFor(tester, find.text('Борис Т.'));
    expect(find.textContaining(t.driversAtPointNowAtPlace(1).split('·').first.trim()), findsWidgets);

    // Фильтр «Проверенные»: водитель верифицирован → остаётся в списке.
    final verified = find.byKey(const Key('driversFilterVerified'));
    await tester.scrollUntilVisible(
      verified,
      80,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal).at(1),
    );
    await tester.ensureVisible(verified);
    await tester.pumpAndSettle();
    await tester.tap(verified);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Борис Т.'), findsOneWidget);
    expectNoOverflow(tester);

    // --- Карточка → чат ---
    final chatButton = find.byWidgetPredicate((w) {
      final key = w.key;
      return key is ValueKey && key.value.toString().startsWith('driversAtPointChat-');
    });
    await tester.tap(chatButton.first);
    await waitFor(tester, find.byKey(const Key('chatMessageInput')));
    expectInsideSafeZone(tester);

    const message = 'E2E: логист пишет водителю';
    await tester.enterText(find.byKey(const Key('chatMessageInput')), message);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await waitFor(tester, find.text(message));

    // --- «Предложить груз» из чата без груза → карточка груза с «Пригласить» ---
    await tester.tap(find.text(t.chatOfferCargoButton));
    await waitFor(tester, find.text(t.chatOfferCargoSheetTitle));
    final firstCargo = find.byType(ListTile).first;
    await tester.tap(firstCargo);
    await waitFor(tester, find.text(t.driversAtPointInvite));
    expectNoOverflow(tester);
  });
}
