// Задача 034, сценарий 9 (после одобрения компании админом): логист входит,
// баннер «Публикация откроется после проверки» исчез, публикует груз с
// объёмом → водитель откликается → логист выбирает его в откликах → сделка.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_core/lubao_core.dart';

import 'company_register_test.dart' show e2eNewCompanyEmail;
import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('логист: вход → публикация груза с объёмом → отклик → выбор водителя → сделка', (tester) async {
    final run = E2eRun(binding, 'logist_publish');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'вход-одобренной-компании', () async {
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('companyLoginEmailField')), e2eNewCompanyEmail);
      await tester.enterText(find.byKey(const Key('companyLoginPasswordField')), e2ePassword);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginSubmitButton')));
      await waitFor(tester, find.text(t.navDrivers));
      await goTab(tester, t.profileTitle);
      await waitFor(tester, find.text(t.profileLogout).first);
      expect(find.byKey(const Key('companyNotVerifiedBanner')), findsNothing, reason: 'после одобрения баннера быть не должно');
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'форма-груза', () async {
      await goTab(tester, t.navCargos);
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('postCargoDestination')));
      expect(find.byKey(const Key('postCargoVerificationBanner')), findsNothing);
      await tester.enterText(find.byKey(const Key('postCargoDestination')), 'Алматы');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Алматы').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('postCargoBodyType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тентованный').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('postCargoVolume')), '90');
      await tester.enterText(find.byKey(const Key('postCargoWeight')), '12000');
      await tester.enterText(find.byKey(const Key('postCargoPrice')), '1500');
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
    });

    late String cargoId;
    await run.step(tester, 'публикация', () async {
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitFor(tester, find.byKey(const Key('companyPostCargoFab')));
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      final cargos = await container.read(myCargosProvider.future);
      expect(cargos, isNotEmpty);
      final cargo = cargos.first;
      expect(cargo.volumeM3, 90);
      cargoId = cargo.id;
      expectNoOverflow(tester);
    });

    await run.step(tester, 'водитель-откликается', () async {
      final driver = await DriverApi.login('+77010000003');
      await driver.respond(cargoId);
    });

    await run.step(tester, 'выбор-водителя-в-откликах', () async {
      final card = find.byKey(Key('companyCargoCard-$cargoId'));
      await tester.pumpAndSettle();
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('responseSelectButton')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('responseSelectButton')));
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (find.byKey(const Key('responseSelectButton')).evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('Выбор водителя не создал сделку за 20 с');
        await tester.pump(const Duration(milliseconds: 300));
      }
    });

    await run.step(tester, 'сделка-в-списке', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.navDeals);
      await waitFor(tester, find.textContaining('Алматы'));
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });
  });
}
