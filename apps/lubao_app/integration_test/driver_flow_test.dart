// Задача 034, сценарии 4 и 5: водитель входит по телефону, публикует анонс
// «Буду на точке», затем из ленты открывает карточку груза и пишет в чат;
// сообщение видно в списке «Чаты». Данные — `backend/prisma/seed-e2e.ts`.
// Тексты — через ARB (`t.xxx`), не строками.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('водитель: вход → анонс → лента → чат → сообщение', (tester) async {
    final run = E2eRun(binding, 'driver_flow');
    await clearPersistedSession();

    // 043 п.8: версия ниже minAppVersion из админки — только экран обновления.
    await run.step(tester, 'обновите-приложение', () async {
      final admin = await adminApi();
      Future<void> setMin(String value) => admin.patch('/admin/settings/minAppVersion', data: {'value': value, 'reason': 'E2E'});
      await setMin('99.0.0');
      try {
        await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: const LubaoApp()));
        await waitFor(tester, find.byKey(const Key('appUpdateTitle')));
        expect(find.byKey(const Key('appUpdateButton')), findsOneWidget);
        expect(find.byKey(const Key('roleSelectDriverButton')), findsNothing);
        expectInsideSafeZone(tester);
        expectNoOverflow(tester);
      } finally {
        await setMin('');
      }
    });

    await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: const LubaoApp()));

    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    // 042 п.3: водитель выбирает, куда прислать код; «Не пришло? Отправить
    // по-другому» — тот же код другим каналом.
    await run.step(tester, 'вход-выбор-канала-кода', () async {
      await tester.tap(find.byKey(const Key('roleSelectDriverButton')));
      await tester.pumpAndSettle();
      await waitFor(tester, find.byKey(const Key('driverLoginChannel-telegram')));
      // 043 п.2: «Продолжая, вы принимаете Условия и Политику» — на экране входа.
      expect(find.byKey(const Key('legalLoginNotice')), findsOneWidget);
      expect(find.byKey(const Key('driverLoginChannel-whatsapp')), findsOneWidget);
      expect(find.byKey(const Key('driverLoginChannel-sms')), findsOneWidget);
      await tester.tap(find.byKey(const Key('driverLoginChannel-telegram')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('driverLoginPhoneField')), '7010000001');
      await tester.pumpAndSettle();
      final send = find.byKey(const Key('driverLoginSendCodeButton'));
      await reveal(tester, send);
      await tester.tap(send);
      await waitFor(tester, find.byKey(const Key('driverLoginSentVia')));
      expect(find.text(t.loginCodeSentVia(t.loginChannelTelegram)), findsOneWidget);
      final viaSms = find.byKey(const Key('driverLoginResendVia-sms'));
      await reveal(tester, viaSms);
      await tester.tap(viaSms);
      await waitFor(tester, find.text(t.loginCodeSentVia(t.loginChannelSms)));
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'вход', () async {
      for (var i = 0; i < 4; i++) {
        await reveal(tester, find.byKey(Key('driverLoginCodeDigit$i')));
        await tester.enterText(find.byKey(Key('driverLoginCodeDigit$i')), e2eDevCode[i]);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await waitFor(tester, find.byKey(const Key('driverStatusBar')));
      expectInsideSafeZone(tester);
    });

    // 040: «свободен в <город>» — город по умолчанию домашний (Алматы), несколько
    // анонсов в одном приложении, порядок ленты задаёт город анонса.
    await run.step(tester, 'анонс-свободен-в-алматы', () async {
      // 045 п.11: статус «Не ищу» → шторка «Где вы сейчас?» → «Еду, буду в …».
      expect(find.byKey(const Key('driverStatus-notLooking')), findsOneWidget);
      await tester.tap(find.byKey(const Key('driverStatusBar')));
      await waitFor(tester, find.byKey(const Key('whereNowSheet')));
      await tester.tap(find.byKey(const Key('whereNowGoing')));
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
      await waitAndReveal(tester, find.byKey(const Key('feedCargoCard-$e2eCargo6')));
      expect(find.text('Догруз'), findsWidgets, reason: 'груз 6 помечен «можно догрузом»');
      expect(firstFeedCargoId(tester), e2eCargo6);
    });

    await run.step(tester, 'смена-города-анонса-на-астану', () async {
      await reveal(tester, find.byKey(const Key('anonsEditButton')));
      await tester.tap(find.byKey(const Key('anonsEditButton')));
      await tester.pumpAndSettle();
      await waitAndReveal(tester, find.byKey(const Key('announceCityField')));
      await tester.tap(find.byKey(const Key('announceCityField')));
      await tester.pumpAndSettle();
      // Поиск не зависит от языка интерфейса: латиницей.
      await pickCityByName(tester, 'Astana', 'Астана');
      final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
      await reveal(tester, submitButton);
      await tester.tap(submitButton);
      // Порядок важен на узком экране с крупным шрифтом: сначала анонс
      // (наверху), потом первая карточка ленты — прокрутка вниз к ней
      // выгружает анонс из дерева.
      await waitAndReveal(tester, find.byKey(const Key('anonsCityName')));
      // Карточка во время обновления показывает прежний город — ждём новый.
      await waitFor(tester, find.byWidgetPredicate((w) => w is Text && w.key == const Key('anonsCityName') && w.data == 'Астана'));
      await waitAndReveal(tester, find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('feedCargoCard-')).first);
      // Теперь первым — груз из Астаны, груз из Алматы ушёл вниз.
      expect(firstFeedCargoId(tester), e2eCargo7);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'лента-карточка-груза', () async {
      final cargoCard = find.byKey(const Key('feedCargoCard-$e2eCargo1'));
      await reveal(tester, cargoCard);
      await tester.pumpAndSettle();
      // 047, эталон 28: в строке — категория, км по дороге и ₸/км, без «Опубликован».
      final km = tester.widget<Text>(find.byKey(const Key('feedCargoKm-$e2eCargo1')));
      expect(km.textSpan!.toPlainText(), contains('340 ${t.unitKm}'));
      expect(find.byKey(const Key('feedCargoPerKm-$e2eCargo1')), findsOneWidget);
      expect(find.descendant(of: cargoCard, matching: find.textContaining('Стройматериалы', findRichText: true)), findsOneWidget);
      expect(find.descendant(of: cargoCard, matching: find.text(t.cargoStatusPublished)), findsNothing);
      await tester.tap(cargoCard);
      await waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));
      expectInsideSafeZone(tester);
    });

    // Кнопка WhatsApp — свой значок (не облачко чата), ведёт в wa.me и
    // пишет contact_event (решение «Телефон и чат доступны сразу»).
    await run.step(tester, 'whatsapp-значок-у-казахстанской-компании', () async {
      // У китайской компании кнопки нет (Google/WhatsApp на её стороне не
      // используются) — проверяем на грузе казахстанской.
      expect(find.byKey(const Key('cargoDetailWhatsappButton')), findsNothing);
      GoRouter.of(tester.element(find.byKey(const Key('cargoDetailChatButton')))).push('/driver/cargo/$e2eCargoKz');
      final button = find.byKey(const Key('cargoDetailWhatsappButton'));
      await waitFor(tester, button);
      expect(find.descendant(of: button, matching: find.byType(WhatsAppIcon)), findsOneWidget);
    });

    await run.step(tester, 'whatsapp-переход-и-событие', () async {
      final button = find.byKey(const Key('cargoDetailWhatsappButton'));
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      final driverId = container.read(sessionProvider)!.driver!.id;
      final admin = await adminApi();
      Future<int> whatsappCount() async => ((await admin.get('/admin/drivers/$driverId')).data['stats']['whatsapp'] as num).toInt();
      final before = await whatsappCount();
      final launcher = useFakeUrlLauncher();
      await tester.tap(button);
      // 043 п.11: номер приходит запросом по нажатию — ждём реальным временем.
      final launchDeadline = DateTime.now().add(const Duration(seconds: 10));
      while (launcher.launched.isEmpty && DateTime.now().isBefore(launchDeadline)) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(launcher.launched, hasLength(1));
      expect(launcher.launched.single, matches(RegExp(r'^https://wa\.me/\d{10,15}$')));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (await whatsappCount() == before && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      expect(await whatsappCount(), before + 1, reason: 'нажатие WhatsApp записано в contact_events');
      await tester.tap(find.byType(BackButton).first);
      await waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));
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
