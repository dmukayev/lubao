// Задача 034, сценарии 4 и 5: водитель входит по телефону, публикует анонс
// «Буду на точке», затем из ленты открывает карточку груза и пишет в чат;
// сообщение видно в списке «Чаты». Данные — `backend/prisma/seed-e2e.ts`.
// Тексты — через ARB (`t.xxx`), не строками.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/router/app_router.dart';
import 'package:lubao_app/router/tab_scroll.dart';
import 'package:lubao_app/services/push_routing.dart';
import 'package:dio/dio.dart';
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
      final phone = find.byKey(const Key('driverLoginPhoneField'));
      await waitAndReveal(tester, phone);
      await tester.tap(phone);
      await tester.pumpAndSettle();
      await tester.enterText(phone, '7010000001');
      await tester.pumpAndSettle();
      // Android 360 dp: клавиатура закрывает кнопку — прячем её до нажатия.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      final send = find.byKey(const Key('driverLoginSendCodeButton'));
      await reveal(tester, send);
      await tester.tap(send);
      await waitFor(tester, find.byKey(const Key('driverLoginSentVia')));
      expect(find.text(t.loginCodeSentVia(t.loginChannelTelegram)), findsOneWidget);
      // Поле кода само берёт фокус — клавиатура закрывает «Отправить по-другому».
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
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
      // 053 п.6: наверху ленты — строка статуса, без приветствия и колокольчика.
      expect(find.byIcon(LucideIcons.bell), findsNothing);
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
      // 049 п.1: догруз выключен флагом — бейджа нет, хотя груз 6 помечен в сиде.
      expect(find.text(t.feedBadgePartial), findsNothing, reason: 'догруз за флагом, по умолчанию выключен');
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
      // Город выбран в шторке — до отправки (на Android 360 выбор терялся).
      await waitFor(tester, find.descendant(of: find.byKey(const Key('announceCityField')), matching: find.text('Астана')));
      final submitButton = find.byKey(const Key('announceArrivalSubmitButton'));
      await reveal(tester, submitButton);
      await tester.tap(submitButton);
      // Порядок важен на узком экране с крупным шрифтом: сначала анонс
      // (наверху), потом первая карточка ленты — прокрутка вниз к ней
      // выгружает анонс из дерева.
      await waitAndReveal(tester, find.byKey(const Key('anonsCityName')));
      // Карточка во время обновления показывает прежний город — ждём новый.
      await waitFor(tester, find.byWidgetPredicate((w) => w is Text && w.key == const Key('anonsCityName') && w.data == 'Астана'));
      await waitAndReveal(tester, find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('feedCargoCard-')));
      // Теперь первым — груз из Астаны, груз из Алматы ушёл вниз. Лента
      // перезагружается после анонса — ждём новый порядок, а не первый кадр.
      final reordered = DateTime.now().add(const Duration(seconds: 20));
      while (firstFeedCargoId(tester) != e2eCargo7) {
        if (DateTime.now().isAfter(reordered)) break;
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(firstFeedCargoId(tester), e2eCargo7);
      expectNoOverflow(tester);
    });

    // 060 п.6: вкладки туда-обратно — прокрутка ленты на месте, ничего не
    // грузится заново (нет запросов списков за 2 с); повторное нажатие — наверх.
    await run.step(tester, 'вкладки-туда-обратно-без-перезагрузки', () async {
      final container = ProviderScope.containerOf(tester.element(find.byType(NavigationBar)));
      // /drivers/me не считаем: «Профиль» при открытии перечитывает статус
      // проверки (админ подтвердил — водитель видит сразу), это не список.
      final listPaths = {'/cargos', '/deals/mine', '/responses/mine', '/chats'};
      var listRequests = 0;
      final counter = InterceptorsWrapper(onRequest: (options, handler) {
        if (options.method == 'GET' && listPaths.contains(options.path)) listRequests++;
        handler.next(options);
      });
      // Первое открытие вкладки грузит её данные — это нормально; сначала
      // открываем все один раз, потом считаем запросы при переключениях.
      for (final tab in [t.navTrips, t.navChats, t.profileTitle, t.navFeed]) {
        await goTab(tester, tab);
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      container.read(apiClientProvider).dio.interceptors.add(counter);
      try {
        final feed = tabScrollController('driver.feed');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        final offset = feed.offset;
        expect(offset, greaterThan(100), reason: 'лента прокрутилась');
        for (final tab in [t.navTrips, t.navChats, t.profileTitle, t.navFeed]) {
          await goTab(tester, tab);
          expect(find.byKey(const Key('skeletonList')), findsNothing, reason: 'вкладка «$tab» не грузится заново');
        }
        await tester.pump(const Duration(seconds: 2));
        expect(listRequests, 0, reason: 'переключение вкладок не перечитывает списки');
        expect((feed.offset - offset).abs(), lessThan(1), reason: 'прокрутка ленты сохранилась');
        // Повторное нажатие на «Грузы» — наверх.
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(t.navFeed)));
        await tester.pumpAndSettle();
        expect(feed.offset, lessThan(1));
        expectNoOverflow(tester);
      } finally {
        container.read(apiClientProvider).dio.interceptors.remove(counter);
      }
    });

    await run.step(tester, 'лента-карточка-груза', () async {
      final cargoCard = find.byKey(const Key('feedCargoCard-$e2eCargo1'));
      await reveal(tester, cargoCard);
      await tester.pumpAndSettle();
      // 047, эталон 28: в строке — категория, км по дороге и ₸/км, без «Опубликован».
      final km = tester.widget<Text>(find.byKey(const Key('feedCargoKm-$e2eCargo1')));
      expect(km.textSpan!.toPlainText(), contains('340 ${t.unitKm}'));
      // 065 (эталон 35): ₸/км — справа под ценой, не у километров.
      expect(km.textSpan!.toPlainText(), isNot(contains(t.perKmKzt('').trim())));
      expect(find.byKey(const Key('feedCargoPerKm-$e2eCargo1')), findsOneWidget);
      expect(find.descendant(of: cargoCard, matching: find.textContaining('Стройматериалы', findRichText: true)), findsOneWidget);
      expect(find.descendant(of: cargoCard, matching: find.text(t.cargoStatusPublished)), findsNothing);
      await tester.tap(cargoCard);
      await waitFor(tester, find.byKey(const Key('cargoDetailChatButton')));
      expectInsideSafeZone(tester);
      // 062: номер груза «№ 482 915»; нажатие — копирует номер.
      final numberWidget = find.byType(CargoNumberText);
      await waitFor(tester, numberWidget);
      final number = tester.widget<CargoNumberText>(numberWidget).number;
      expect(number, inInclusiveRange(100000, 999999));
      expect(find.text(t.cargoNumberLabel(formatCargoNumber(number))), findsOneWidget);
      await tester.tap(numberWidget);
      await waitFor(tester, find.text(t.cargoNumberCopied('$number')));
      ScaffoldMessenger.of(tester.element(numberWidget)).clearSnackBars();
      await tester.pumpAndSettle();
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

    // 061 п.2: push с адресом вкладки поверх открытого чата — лента в своей
    // вкладке, одна оболочка, без «Duplicate GlobalKey».
    await run.step(tester, 'push-arrival-поверх-чата', () async {
      final router = ProviderScope.containerOf(tester.element(find.byType(LubaoApp))).read(routerProvider);
      openPushLink(router, '/arrival', UserRole.driver);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('chatMessageInput')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/driver/feed');
      // Лента — в своей вкладке (прокрутка сохранена, полосы чипов может не быть видно).
      await waitFor(tester, find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('feedCargoCard-')).first);
    });

    await run.step(tester, 'список-чатов', () async {
      await tester.tap(find.text(t.navChats));
      await waitFor(tester, find.textContaining(messageText));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });

    // 070: в синей карточке нет «Изменить» — город с карандашом открывает
    // изменение, «Отменить» / «Я уехал» — таблеткой справа от города.
    await run.step(tester, 'анонс-город-и-кнопка-справа', () async {
      await goTab(tester, t.navFeed);
      await waitAndReveal(tester, find.byKey(const Key('anonsCityName')));
      expect(find.text(t.driverHomeEditButton), findsNothing, reason: '070: кнопки «Изменить» нет');
      final city = tester.getRect(find.byKey(const Key('anonsCityName')));
      final leave = tester.getRect(find.byKey(const Key('anonsLeaveButton')));
      expect(leave.left, greaterThan(city.left), reason: 'кнопка справа от города');
      expect((leave.center.dy - city.center.dy).abs(), lessThan(city.height), reason: 'в одной строке с городом');
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'анонс-отменить-и-повторить', () async {
      await tester.tap(find.byKey(const Key('anonsLeaveButton')));
      // Лента перестраивается (порядок по домашнему городу) — карточка анонса
      // уезжает наверх: возвращаемся к началу.
      await waitForCondition(tester, () => find.byKey(const Key('anonsLeaveButton')).evaluate().isEmpty);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      await waitAndReveal(tester, find.byKey(const Key('driverAnnounceArrivalButton')));
      expect(find.byKey(const Key('anonsCityName')), findsNothing, reason: 'анонс снят');
      // Вернуть анонс как был — следующим сценариям нужен водитель в Астане.
      await waitAndReveal(tester, find.text(t.driverHomeRepeatButton));
      await tester.tap(find.text(t.driverHomeRepeatButton));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      await waitFor(tester, find.byWidgetPredicate((w) => w is Text && w.key == const Key('anonsCityName') && w.data == 'Астана'));
      expectNoOverflow(tester);
    });
  });
}
