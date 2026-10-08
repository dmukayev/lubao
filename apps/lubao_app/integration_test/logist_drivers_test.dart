// Задача 034: логист (email+пароль) → «Водители» (036) → «Проверенные» меняет
// список → чат с водителем → «Предложить груз» → «Пригласить» → сделка (035);
// затем тот же водитель входит, подтверждает перевозку и двигает «Загружен»
// прямо в карточке чата, не выходя из переписки.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

/// Водители сида (backend/prisma/seed-e2e.ts): D3 проверен, D4 — нет.
const _d3Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd003');
const _d4Card = Key('driversAtPointCard-dddddddd-dddd-4ddd-8ddd-ddddddddd004');
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

    await run.step(tester, 'логист-выбирает-согласившегося', () async {
      await goTab(tester, t.navChats);
      await waitFor(tester, find.textContaining('Борис'));
      await tester.tap(find.textContaining('Борис').first);
      await waitFor(tester, find.byKey(const Key('chatCardActionButton')));
      expect(find.descendant(of: find.byKey(const Key('chatCardActionButton')), matching: find.text(t.responseSelect)), findsOneWidget);
      await tester.tap(find.byKey(const Key('chatCardActionButton')));
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.byKey(const Key('chatCardActionButton')).evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('Выбор водителя не создал сделку за 20 с');
        await tester.pump(const Duration(milliseconds: 300));
      }
      expectNoOverflow(tester);
    });

    await run.step(tester, 'выход-логиста-2', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await logoutViaProfile(tester, driver: false);
    });

    await run.step(tester, 'вход-водителя-D3-снова', () async {
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
