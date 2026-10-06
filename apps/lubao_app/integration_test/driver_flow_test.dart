// Задача 034, сценарии 4 и 5: водитель входит по телефону, публикует анонс
// «Буду на точке», затем из ленты открывает карточку груза и пишет в чат;
// сообщение видно в списке «Чаты». Данные — `backend/prisma/seed-e2e.ts`.
// Тексты — через ARB (`t.xxx`), не строками.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: вход → анонс → лента → чат → сообщение', (tester) async {
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));

    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await loginDriver(tester, '7010000001');

    // --- Главная: анонс «Буду на точке» ---
    await waitFor(tester, find.byKey(const Key('driverAnnounceArrivalButton')));
    expectInsideSafeZone(tester);
    await tester.tap(find.byKey(const Key('driverAnnounceArrivalButton')));
    await tester.pumpAndSettle();

    final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
    await tester.scrollUntilVisible(submitButton, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(submitButton);
    await waitFor(tester, find.byKey(const Key('driverCheckInButton')));

    // --- Лента → карточка груза ---
    final cargoCard = find.byKey(const Key('feedCargoCard-$e2eCargo1'));
    await tester.scrollUntilVisible(cargoCard, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(cargoCard);
    await waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));

    // --- «Написать» → чат → сообщение ---
    await tester.tap(find.byKey(const Key('cargoDetailChatButton')));
    await waitFor(tester, find.byKey(const Key('chatMessageInput')));
    expectInsideSafeZone(tester);

    const messageText = 'E2E: проверка сквозного сценария';
    await tester.enterText(find.byKey(const Key('chatMessageInput')), messageText);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chatSendButton')));
    await waitFor(tester, find.text(messageText));

    // --- Список «Чаты» показывает это сообщение ---
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.navChats));
    await waitFor(tester, find.textContaining(messageText));
    expectInsideSafeZone(tester);
    expectNoOverflow(tester);
  });
}
