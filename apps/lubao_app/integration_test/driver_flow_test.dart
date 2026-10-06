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

    // 040: «свободен в <город>» — город по умолчанию домашний (Алматы), несколько
    // анонсов в одном приложении, порядок ленты задаёт город анонса.
    await run.step(tester, 'анонс-свободен-в-алматы', () async {
      await tester.tap(find.byKey(const Key('driverAnnounceArrivalButton')));
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
      // Город по умолчанию — домашний город водителя (Алматы).
      expect(find.descendant(of: find.byKey(const Key('announceCityField')), matching: find.text('Алматы')), findsOneWidget);
      final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
      await reveal(tester, submitButton);
      await tester.tap(submitButton);
      await waitFor(tester, find.byKey(const Key('driverCheckInButton')));
      expect(tester.widget<Text>(find.byKey(const Key('anonsCityName'))).data, 'Алматы');
      // Груз из Алматы виден первым (город анонса = город погрузки).
      await waitFor(tester, find.byKey(const Key('feedCargoCard-$e2eCargo6')));
      expect(find.text('Догруз'), findsWidgets, reason: 'груз 6 помечен «можно догрузом»');
      expect(firstFeedCargoId(tester), e2eCargo6);
    });

    await run.step(tester, 'смена-города-анонса-на-астану', () async {
      await reveal(tester, find.byKey(const Key('anonsEditButton')));
      await tester.tap(find.byKey(const Key('anonsEditButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('announceCityField')));
      await tester.pumpAndSettle();
      // Поиск не зависит от языка интерфейса: латиницей.
      await pickCityByName(tester, 'Astana', 'Астана');
      final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
      await reveal(tester, submitButton);
      await tester.tap(submitButton);
      await waitFor(tester, find.byKey(const Key('anonsCityName')));
      await waitFor(tester, find.byKey(const Key('feedCargoCard-$e2eCargo7')));
      expect(tester.widget<Text>(find.byKey(const Key('anonsCityName'))).data, 'Астана');
      // Теперь первым — груз из Астаны, груз из Алматы ушёл вниз.
      expect(firstFeedCargoId(tester), e2eCargo7);
      expectNoOverflow(tester);
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
