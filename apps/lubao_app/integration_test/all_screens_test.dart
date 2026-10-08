// Задача 034, п.17: разовый обход ВСЕХ маршрутов `app_router.dart` — водитель,
// логист и экраны без входа: безопасная зона, отсутствие переполнений,
// скриншот каждого экрана.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/router/app_router.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('обход всех экранов: безопасная зона и переполнения', (tester) async {
    final run = E2eRun(binding, 'all_screens');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
    final router = container.read(routerProvider);

    Future<void> visit(String name, String path, {Finder? expectFinder}) async {
      await run.step(tester, name, () async {
        router.go(path);
        await tester.pump(const Duration(milliseconds: 300));
        if (expectFinder != null) {
          await waitFor(tester, expectFinder);
        } else {
          await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)).catchError((_) => 0);
          await tester.pump(const Duration(seconds: 1));
        }
        expectInsideSafeZone(tester);
        expectNoOverflow(tester);
        expect(find.byType(ErrorWidget), findsNothing);
      });
    }

    // --- Без входа ---
    await visit('role-select', '/role-select', expectFinder: find.byKey(const Key('roleSelectDriverButton')));
    await visit('login-driver', '/login/driver');
    await visit('login-company', '/login/company');
    await visit('login-company-register', '/login/company/register');
    await visit('login-company-forgot', '/login/company/forgot-password');
    await visit('invite', '/invite/e2e-no-such-token');

    // --- Водитель ---
    await visit('role-select-2', '/role-select', expectFinder: find.byKey(const Key('roleSelectDriverButton')));
    await run.step(tester, 'вход-водителя', () async {
      await loginDriver(tester, '7010000002');
      await waitFor(tester, find.byKey(const Key('driverStatusBar')));
    });
    Future<(List<String>, List<String>)> myIds() async => (
          (await container.read(dealRepositoryProvider).mine()).map((d) => d.id).toList(),
          (await container.read(chatRepositoryProvider).myChats()).map((c) => c.thread.id).toList(),
        );
    var (dealIds, chatIds) = await myIds();
    await visit('driver-feed', '/driver/feed', expectFinder: find.byKey(const Key('driverStatusBar')));
    await visit('driver-chats', '/driver/chats');
    await visit('driver-deals', '/driver/deals');
    await visit('driver-profile', '/driver/profile');
    await visit('driver-cargo', '/driver/cargo/$e2eCargo1', expectFinder: find.byKey(const Key('cargoDetailChatButton')));
    await visit('driver-setup', '/driver/setup');
    await visit('driver-register', '/driver/register');
    await visit('driver-verification', '/driver/verification');
    await visit('driver-garage', '/driver/garage', expectFinder: find.byKey(const Key('garageList')));
    await visit('driver-responses', '/driver/responses');
    await visit('devices', '/devices');
    await visit('notification-settings', '/notifications/settings');
    await visit('about', '/about', expectFinder: find.byKey(const Key('profileDeleteAccountButton')));
    if (dealIds.isNotEmpty) await visit('deal-detail', '/deal/${dealIds.first}');
    if (chatIds.isNotEmpty) await visit('chat', '/chat/${chatIds.first}', expectFinder: find.byKey(const Key('chatMessageInput')));
    await run.step(tester, 'выход-водителя', () async {
      router.go('/driver/profile');
      await waitFor(tester, find.byType(NavigationBar));
      await logoutViaProfile(tester, driver: true);
    });

    // --- Логист ---
    await run.step(tester, 'вход-логиста', () async {
      await loginLogist(tester);
      await waitFor(tester, find.text(tester.element(find.byType(Scaffold).first).l10n.navDrivers));
      (dealIds, chatIds) = await myIds();
    });
    await visit('company-cargos', '/company/cargos');
    await visit('company-drivers', '/company/drivers');
    await visit('company-chats', '/company/chats');
    await visit('company-deals', '/company/deals');
    await visit('company-profile', '/company/profile');
    await visit('company-cargo-new', '/company/cargos/new');
    await visit('company-cargo-responses', '/company/cargos/$e2eCargo1/responses');
    if (dealIds.isNotEmpty) await visit('company-deal-detail', '/deal/${dealIds.first}');
    if (chatIds.isNotEmpty) await visit('company-chat', '/chat/${chatIds.first}', expectFinder: find.byKey(const Key('chatMessageInput')));
    await visit('company-devices', '/devices');
    await visit('company-notification-settings', '/notifications/settings');
    // У логиста в «О приложении» есть оферта.
    await visit('company-about', '/about', expectFinder: find.byKey(const Key('aboutOffer')));
  });
}
