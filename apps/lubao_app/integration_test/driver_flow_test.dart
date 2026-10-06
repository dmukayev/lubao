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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: вход → анонс → лента → чат → сообщение', (tester) async {
    final run = E2eRun(binding, 'driver_flow');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));

    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход', () async {
      await loginDriver(tester, '7010000001');
      await waitFor(tester, find.byKey(const Key('driverAnnounceArrivalButton')));
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'анонс-буду-на-точке', () async {
      await tester.tap(find.byKey(const Key('driverAnnounceArrivalButton')));
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
      final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
      await reveal(tester, submitButton);
      await tester.tap(submitButton);
      await waitFor(tester, find.byKey(const Key('driverCheckInButton')));
    });

    await run.step(tester, 'лента-карточка-груза', () async {
      final cargoCard = find.byKey(const Key('feedCargoCard-$e2eCargo1'));
      await reveal(tester, cargoCard);
      await tester.pumpAndSettle();
      await tester.tap(cargoCard);
      await waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));
      expectInsideSafeZone(tester);
    });

    const messageText = 'E2E: проверка сквозного сценария';
    await run.step(tester, 'чат-сообщение', () async {
      await tester.tap(find.byKey(const Key('cargoDetailChatButton')));
      await waitFor(tester, find.byKey(const Key('chatMessageInput')));
      expectInsideSafeZone(tester);
      await tester.enterText(find.byKey(const Key('chatMessageInput')), messageText);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chatSendButton')));
      await waitFor(tester, find.text(messageText));
    });

    await run.step(tester, 'список-чатов', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.navChats));
      await waitFor(tester, find.textContaining(messageText));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });
  });
}
