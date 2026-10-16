// Задача 034: логист (email+пароль) → «Водители» (036) → «Проверенные» меняет
// список → чат с водителем → «Предложить груз» → «Пригласить» → сделка (035);
// затем тот же водитель входит, подтверждает перевозку и двигает «Загружен»
// прямо в карточке чата, не выходя из переписки.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/features/shared/share_action.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_app/services/disk_bytes_cache.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

/// Водители сида (backend/prisma/seed-e2e.ts): D3 проверен, D4 — нет.
const _d3Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd003');
const _d4Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd004');
/// D2 — не на точке; встаёт и уходит через API, пока у логиста открыт список.
const _d2Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd002');
/// D6 — «свободен в Алматы» на сегодня (040).
const _d6Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd006');
const _d3Id = 'dddddddd-dddd-4ddd-8ddd-ddddddddd003';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('логист: «Водители» → фильтр → чат → пригласить → водитель подтверждает и грузит', (tester) async {
    final run = E2eRun(binding, 'logist_drivers');
    await clearPersistedSession();
    // Системный диалог геолокации робот нажать не может — подменяем запрос ОС (041, п.11).
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход-логиста', () async {
      await loginLogist(tester);
      await waitFor(tester, find.text(t.navDrivers));
    });

    await run.step(tester, 'водители-экран', () async {
      await tester.tap(find.text(t.navDrivers));
      await waitFor(tester, find.text(t.driversAtPointTitleShort));
      await waitFor(tester, find.byKey(_d3Card));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
      // Город по умолчанию — город последнего груза компании (Хоргос, 040 п.8);
      // название — из справочника, в тексте ARB города нет. В полосе дней «Сег».
      expect(find.byKey(const Key('driversPointChip')), findsOneWidget);
      expect(find.text(t.driversAtPointTitle('Хоргос')), findsOneWidget);
      expect(find.text(t.driversAtPointTodayShort), findsOneWidget);
      // Два водителя на точке: проверенный и нет.
      expect(find.byKey(_d4Card), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('driverVerifiedPill-')), findsWidgets);
      final d4Card = find.byKey(_d4Card);
      expect(
        find.descendant(of: d4Card, matching: find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('driverVerifiedPill-'))),
        findsNothing,
        reason: 'у непроверенного водителя нет плашки «Проверен»',
      );
    });

    // Владелец: «водитель не появился, пока не обновишь страницу». Водитель
    // встал на линию — карточка появляется сама; уехал — исчезает сама.
    await run.step(tester, 'водитель-появляется-сам', () async {
      expect(find.byKey(_d2Card), findsNothing);
      final d2 = await DriverApi.login('+77010000002');
      await d2.checkInAt('Хоргос');
      await waitFor(tester, find.byKey(_d2Card, skipOffstage: false), timeout: const Duration(seconds: 15));
      await d2.leave();
      await waitForCondition(tester, () => find.byKey(_d2Card, skipOffstage: false).evaluate().isEmpty, timeout: const Duration(seconds: 15));
    });

    // Выбор груза для приглашения: подсказка, кружки, «Пригласить» — после выбора.
    // Здесь только проверяем выбор и закрываем без приглашения.
    await run.step(tester, 'пригласить-выбор-груза', () async {
      final invite = find.byKey(const Key('driversAtPointInvite-dddddddd-dddd-4ddd-8ddd-ddddddddd004'));
      await waitAndReveal(tester, invite);
      await tester.tap(invite);
      await waitFor(tester, find.byKey(const Key('inviteCargoHint')));
      final submit = find.byKey(const Key('inviteCargoSubmit'));
      final options = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('inviteCargo-') && (w.key! as ValueKey<String>).value != 'inviteCargoSubmit' && (w.key! as ValueKey<String>).value != 'inviteCargoHint');
      if (options.evaluate().length > 1) {
        // 072: «Пригласить» активна всегда — без выбора подсказка становится ошибкой.
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text(t.inviteCargoPickRequired), findsOneWidget);
      }
      await tester.tap(options.first);
      await tester.pumpAndSettle();

      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
      Navigator.of(tester.element(submit)).pop();
      await tester.pumpAndSettle();
    });

    // 040, п.8: «Кто свободен в <город>» — выбор города сверху; водитель, объявивший
    // «свободен в Алматы», виден только там.
    await run.step(tester, 'кто-свободен-выбор-города-алматы', () async {
      await tester.tap(find.byKey(const Key('driversPointChip')));
      await pickCityByName(tester, 'Almaty', 'Алматы');
      await waitFor(tester, find.byKey(_d6Card));
      expect(find.text(t.driversAtPointTitle('Алматы')), findsOneWidget);
      expect(find.byKey(_d3Card), findsNothing, reason: 'D3 на месте в другом городе');
      expect(find.byKey(_d4Card), findsNothing);
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'кто-свободен-обратно-хоргос', () async {
      await tester.tap(find.byKey(const Key('driversPointChip')));
      await pickCityByName(tester, 'korg', 'Хоргос');
      await waitFor(tester, find.byKey(_d3Card));
      expect(find.byKey(_d6Card), findsNothing);
    });

    await run.step(tester, 'фильтр-проверенные', () async {
      final verified = find.byKey(const Key('driversFilterVerified'));
      await tester.scrollUntilVisible(verified, 80,
          scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal).at(1));
      await tester.ensureVisible(verified);
      await tester.pumpAndSettle();
      await tester.tap(verified);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_d3Card), findsOneWidget);
      expect(find.byKey(_d4Card), findsNothing, reason: 'непроверенный водитель должен пропасть из списка «Проверенные»');
      expectNoOverflow(tester);
      // Выключаем фильтр: непроверенный снова в списке.
      await tester.tap(verified);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_d4Card), findsOneWidget);
    });

    // 058 п.6: ☆ у водителя → «Мои»; «Создать водителя». 061 п.1: номер уже в
    // Lubao, но ответ — как на любой номер: ссылка для отправки, в списке —
    // имя от компании и «ждёт входа», без карточки водителя.
    await run.step(tester, 'мои-водители-звезда-и-создать', () async {
      final star = find.byKey(const Key('driverSave-dddddddd-dddd-4ddd-8ddd-ddddddddd003'));
      await reveal(tester, star);
      await tester.tap(star);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('driversTabMine')));
      await waitFor(tester, find.byKey(const Key('myDriverCard-dddddddd-dddd-4ddd-8ddd-ddddddddd003')));
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('myDriversCreate')));
      await waitFor(tester, find.byKey(const Key('myDriversCreateName')));
      await tester.enterText(find.byKey(const Key('myDriversCreateName')), 'Нурлан');
      await tester.enterText(find.byKey(const Key('myDriversCreatePhone')), '+7 701 000 00 04');
      await tester.pumpAndSettle();
      final shared = <String>[];
      debugShareOverride = (text) async => shared.add(text);
      addTearDown(() => debugShareOverride = null);
      await tester.tap(find.byKey(const Key('myDriversCreateSubmit')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      for (var i = 0; i < 20 && shared.isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      debugShareOverride = null;
      expect(shared, hasLength(1));
      expect(shared.single, contains('/co/'), reason: 'приглашение — ссылка компании');
      expect(find.byKey(const Key('myDriverCard-dddddddd-dddd-4ddd-8ddd-ddddddddd004')), findsNothing, reason: 'до «Принять» driverId не отдаётся');
      final pending = find.ancestor(of: find.text('Нурлан'), matching: find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('myDriverCard-')));
      await waitFor(tester, pending);
      expect(find.descendant(of: pending.first, matching: find.textContaining(t.myDriversWaiting)), findsOneWidget);
      await tester.tap(find.byKey(const Key('driversTabAll')));
      await waitFor(tester, find.byKey(_d3Card));
    });

    await run.step(tester, 'чат-с-водителем', () async {
      final card = find.byKey(_d3Card);
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

    // Приглашение с согласием (041, п.3): «Пригласить» создаёт INVITED, не сделку.
    await run.step(tester, 'пригласить-ждём-согласия', () async {
      await tester.tap(find.byKey(const Key('chatCardActionButton')));
      await waitFor(tester, find.byKey(const Key('chatInvitedWaiting')));
      expect(find.byKey(const Key('chatCardActionButton')), findsNothing, reason: 'сделки нет: «Выбрать» из INVITED недоступно');
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

    await run.step(tester, 'водитель-видит-приглашение-и-соглашается', () async {
      await goTab(tester, t.navChats);
      await waitFor(tester, find.textContaining('E2E Test Logistics'));
      await tester.tap(find.textContaining('E2E Test Logistics').first);
      await waitFor(tester, find.byKey(const Key('chatDeclineInvitationButton')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('chatCargoReadyButton')));
      // «Готов взять» → отклик PENDING: теперь ждёт выбора логиста.
      await waitFor(tester, find.text(t.chatResponseSentLabel));
    });

    // 054: селфи принято → в профиле «Поставить это фото в профиль?» → «Да» →
    // фото рядом с именем; предложение больше не показывается.
    await run.step(tester, 'фото-профиля-из-селфи', () async {
      await approvedSelfieViaApi('7010000003');
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.profileTitle);
      await waitAndReveal(tester, find.byKey(const Key('avatarOfferCard')));
      expect(find.text(t.avatarOfferTitle), findsOneWidget);
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('avatarOfferYes')));
      // Фото — в шапке профиля, список прокручен к карточке: возвращаемся наверх.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await waitAndReveal(tester, find.byKey(const Key('driverAvatar-$_d3Id-photo')), timeout: const Duration(seconds: 30));
      expect(find.byKey(const Key('avatarOfferCard')), findsNothing);
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'выход-водителя', () async {
      await logoutViaProfile(tester, driver: true);
    });

    // 054 п.4: логист видит лицо водителя в «Водителях» и в чатах.
    await run.step(tester, 'логист-видит-фото-водителя', () async {
      await loginLogist(tester);
      await waitFor(tester, find.text(t.navDrivers));
      await tester.tap(find.text(t.navDrivers));
      await waitAndReveal(tester, find.byKey(_d3Card));
      await waitFor(tester, find.descendant(of: find.byKey(_d3Card), matching: find.byKey(const Key('driverAvatar-$_d3Id-photo'))), timeout: const Duration(seconds: 30));
      expectNoOverflow(tester);
    });

    // 067: нажатие по строке (не по имени) — полная карточка водителя: фото
    // водителя, фото машины, «Позвонить»; ✕ закрывает. Фото машины — на весь экран.
    await run.step(tester, 'карточка-водителя-по-строке', () async {
      await vehiclePhotoViaApi('7010000003', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa003');
      await openDriverCardByRow(tester, _d3Card);
      await waitFor(tester, find.descendant(of: find.byKey(const Key('driverCard')), matching: find.byKey(const Key('driverAvatar-$_d3Id-photo'))), timeout: const Duration(seconds: 30));
      expect(find.byKey(const Key('driverCardStatus')), findsOneWidget);
      expectNoOverflow(tester);
    });

    // Снимок выше — верх шторки (фото, статус); дальше фото машины и кнопки.
    await run.step(tester, 'карточка-водителя-фото-машины-и-кнопки', () async {
      final photo = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('driverVehiclePhoto-'));
      await waitAndReveal(tester, photo, timeout: const Duration(seconds: 30));
      expectNoOverflow(tester);
      await tester.tap(photo.first);
      await waitFor(tester, find.byKey(const Key('fullScreenPhotos')));
      await tester.tap(find.byKey(const Key('fullScreenPhotosClose')));
      await tester.pumpAndSettle();
      await waitAndReveal(tester, find.byKey(const Key('driverCardCall')));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });

    // Снимок выше — шторка открыта; здесь ✕ закрывает её.
    await run.step(tester, 'карточка-водителя-крестик', () async {
      await tester.tap(find.byKey(const Key('driverCardClose')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('driverCard')), findsNothing, reason: '✕ закрывает шторку');
    });

    // 061 п.11: повторное нажатие на «Грузы» у логиста — список наверх.
    await run.step(tester, 'грузы-логиста-повторное-нажатие-наверх', () async {
      await goTab(tester, t.navCargos);
      final list = find.byKey(const Key('companyCargosList-active'));
      await waitFor(tester, list);
      final position = tester.state<ScrollableState>(find.descendant(of: list, matching: find.byType(Scrollable)).first).position;
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      if (position.maxScrollExtent > 100) expect(position.pixels, greaterThan(100), reason: 'список прокрутился');
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(t.navCargos)));
      await tester.pumpAndSettle();
      expect(position.pixels, lessThan(1));
      // 063 (эталон 35): чистая карточка — без плашки «Опубликован» и даты
      // публикации; на узком экране с крупным шрифтом видно больше одной карточки.
      expect(find.descendant(of: list, matching: find.text(t.cargoStatusPublished)), findsNothing);
      final screen = tester.getRect(list);
      final cards = find.descendant(of: list, matching: find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('companyCargoCard-')));
      final whole = cards.evaluate().where((e) {
        final box = e.renderObject! as RenderBox;
        final top = box.localToGlobal(Offset.zero).dy;
        return top >= screen.top && top + box.size.height <= screen.bottom;
      }).length;
      // Android 360 (список выше 500 dp) — не меньше двух целиком (третья видна);
      // iPhone SE с крупным шрифтом — хотя бы одна целиком.
      expect(whole, greaterThanOrEqualTo(screen.height >= 500 ? 2 : 1), reason: 'на экране целиком $whole карточки, высота списка ${screen.height}');
      expectNoOverflow(tester);
    });

    // 079: свой груз из списка — карточка сразу (сервер «медленный», 2 с).
    await run.step(tester, 'груз-логиста-сразу', () async {
      final list = find.byKey(const Key('companyCargosList-active'));
      await waitFor(tester, list);
      final card = find.descendant(of: list, matching: find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('companyCargoCard-'))).first;
      final id = (tester.widget(card).key! as ValueKey<String>).value.substring('companyCargoCard-'.length);
      ApiClient.simulateLatency = const Duration(seconds: 2);
      try {
        await tester.tap(card);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(Key('cargoDetailPrice-$id')), findsOneWidget, reason: '079: груз — в том же кадре');
        expect(find.byType(LoadingView), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      } finally {
        ApiClient.simulateLatency = null;
      }
    });

    await run.step(tester, 'груз-логиста-отклики-дорисованы', () async {
      // Отклики — под полной карточкой груза, за краем экрана.
      await waitAndReveal(tester, find.byKey(const Key('companyCargoResponsesTitle')));
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    // 079: шторка водителя — сразу с тем, что есть в строке «Водителей».
    await run.step(tester, 'шторка-водителя-сразу', () async {
      await goTab(tester, t.navDrivers);
      final row = find.byKey(_d3Card);
      await waitAndReveal(tester, row);
      final icon = find.descendant(of: row, matching: find.byType(BodyTypeIcon));
      ApiClient.simulateLatency = const Duration(seconds: 2);
      try {
        if (icon.evaluate().isNotEmpty) {
          await tester.tap(icon.first);
        } else {
          await tester.tapAt(tester.getBottomLeft(row) + const Offset(24, -12));
        }
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('driverCardName')), findsOneWidget, reason: '079: имя — сразу');
        expect(find.byType(LoadingView), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing, reason: '079: крутилок нет — блоки появляются, когда пришли');
      } finally {
        ApiClient.simulateLatency = null;
      }
    });

    await run.step(tester, 'шторка-водителя-дорисована', () async {
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('driverCardClose')));
      await tester.pumpAndSettle();
      await goTab(tester, t.navCargos);
    });

    // 078 п.2: начатую форму груза закрыли — при следующем открытии
    // «Продолжить черновик?», и введённое на месте.
    await run.step(tester, 'черновик-продолжить', () async {
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('postCargoPickupCity')));
      final price = find.byKey(const Key('postCargoPrice'));
      await reveal(tester, price);
      await tester.enterText(price, '777');
      await tester.pumpAndSettle();
      // Черновик пишется через секунду после правки.
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('draftDialog')));
      expect(find.text(t.draftContinueTitle), findsOneWidget);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'черновик-восстановлен', () async {
      await tester.tap(find.byKey(const Key('draftContinue')));
      await tester.pumpAndSettle();
      final price = find.byKey(const Key('postCargoPrice'));
      await waitAndReveal(tester, price);
      expect(find.descendant(of: price, matching: find.text('777')), findsOneWidget);
      // Начать заново — черновик стёрт, следующие сценарии открывают чистую форму.
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('draftDialog')));
      await tester.tap(find.byKey(const Key('draftStartOver')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'логист-выбирает-согласившегося', () async {
      // Водитель написал в чат — у логиста цифра непрочитанных на «Чатах».
      await (await DriverApi.login('+77010000003')).sendToCompanyChat('E2E Test Logistics', 'Готов, жду');
      await waitFor(tester, find.byWidgetPredicate((w) => w is Badge && w.key == const Key('navChatsBadge') && w.isLabelVisible), timeout: const Duration(seconds: 30));
      await goTab(tester, t.navChats);
      await waitFor(tester, find.textContaining('Борис'));
      await tester.tap(find.textContaining('Борис').first);
      await waitFor(tester, find.byKey(const Key('chatCardActionButton')));
      // 061 п.3: «Выбрать за …» — с ценой, которая уйдёт на сверку.
      expect(find.descendant(of: find.byKey(const Key('chatCardActionButton')), matching: find.textContaining(t.offerSelectFor('').trim())), findsOneWidget);
      await tester.tap(find.byKey(const Key('chatCardActionButton')));
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.byKey(const Key('chatCardActionButton')).evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('Выбор водителя не создал сделку за 20 с');
        await tester.pump(const Duration(milliseconds: 300));
      }
      expectNoOverflow(tester);
    });

    // 061 п.9: фото, что видел логист, после выхода на телефоне не остаются;
    // следующий вошедший — со своими вкладками.
    await run.step(tester, 'выход-логиста-2', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      if (!kIsWeb) expect(await DiskBytesCache.instance.debugFileCount(), greaterThan(0), reason: 'фото водителя были в кэше');
      await logoutViaProfile(tester, driver: false);
      expect(await DiskBytesCache.instance.debugFileCount(), 0, reason: 'кэш картинок очищен при выходе');
    });

    await run.step(tester, 'вход-водителя-D3-снова', () async {
      await loginDriver(tester, '7010000003');
      await waitFor(tester, find.byType(NavigationBar));
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(t.navDrivers)), findsNothing, reason: 'вкладки логиста не остались');
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
      // 041, п.11: начало рейса — отдельная шторка согласия на местоположение.
      await waitFor(tester, find.byKey(const Key('tripTrackingConsentSheet')));
      await tester.tap(find.byKey(const Key('consentUnderstoodButton')));
      await waitFor(
        tester,
        find.descendant(of: find.byKey(const Key('chatCardNextStatusButton')), matching: find.text(t.dealMarkInTransit)),
      );
      // Остались в чате: поле ввода на месте.
      expect(find.byKey(const Key('chatMessageInput')), findsOneWidget);
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });

    // 040, п.4: подтвердил сделку в приложении — анонс исполнил свою работу и погас сам.
    await run.step(tester, 'анонс-погас-после-подтверждения', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.navFeed);
      await waitFor(tester, find.byKey(const Key('driverStatusBar')));
      expect(find.byKey(const Key('driverCheckInButton')), findsNothing);
      expectNoOverflow(tester);
    });
  });
}
