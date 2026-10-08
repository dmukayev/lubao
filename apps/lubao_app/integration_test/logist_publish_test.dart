// Задача 034, сценарий 9 (после одобрения компании админом): логист входит,
// баннер «Публикация откроется после проверки» исчез, публикует груз с
// объёмом → водитель откликается → логист выбирает его в откликах → сделка.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
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
      await waitFor(tester, find.text('Urumqi Test Logistics'));
      expect(find.byKey(const Key('companyNotVerifiedBanner')), findsNothing, reason: 'после одобрения баннера быть не должно');
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'форма-груза', () async {
      await goTab(tester, t.navCargos);
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('postCargoDestination')));
      expect(find.byKey(const Key('postCargoVerificationBanner')), findsNothing);
      // 040, п.7: у новой компании грузов ещё нет — города по умолчанию нет, он обязателен.
      expect(find.text(t.cityFieldPlaceholder), findsOneWidget);
      await tester.enterText(find.byKey(const Key('postCargoDestination')), 'Алматы');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Алматы').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('postCargoBodyType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тентованный').last);
      await tester.pumpAndSettle();
      // Каждое поле — сначала на экран: иначе нажатие не фокусирует его и
      // текст уходит в предыдущее поле (цена оставалась пустой).
      for (final (key, value) in [('postCargoVolume', '90'), ('postCargoWeight', '12'), ('postCargoPrice', '1500')]) {
        final field = find.byKey(Key(key));
        await reveal(tester, field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }
      expect(find.text('1500'), findsOneWidget);
      expectInsideSafeZone(tester);
    });

    // Груз без города погрузки не публикуется: форма говорит почему.
    await run.step(tester, 'город-погрузки-обязателен', () async {
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      // Поле города — первое в форме: возвращаемся наверх, оно ленивое.
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text(t.postCargoPickupCityError), findsOneWidget);
      // 047 п.1: без категории тоже не публикуется.
      await reveal(tester, find.byKey(const Key('postCargoCategoryError')));
      expect(find.text(t.postCargoCategoryRequired), findsOneWidget);
    });

    await run.step(tester, 'выбор-города-погрузки-и-догруз', () async {
      final field = find.byKey(const Key('postCargoPickupCity'));
      await waitFor(tester, field);
      await tester.tap(field);
      await pickCityByName(tester, 'Astana', 'Астана');
      expect(find.text(t.postCargoPickupCityError), findsNothing);
      final category = find.byKey(const Key('postCargoCategory-CONSTRUCTION'));
      await reveal(tester, category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('postCargoCategoryError')), findsNothing);
      final partial = find.byKey(const Key('postCargoAllowPartial'));
      await reveal(tester, partial);
      await tester.tap(partial);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(partial).value, isTrue);
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
      expect(cargo.allowPartial, isTrue, reason: '«Можно догрузом» ушло на сервер');
      final refData = await container.read(referenceDataProvider.future);
      expect(refData.pointOrNull(cargo.pointId)?.name.ru, 'Астана', reason: 'город погрузки — из выбора, не первая точка');
      // 047: категория ушла, расстояние Астана → Алматы посчитано (в e2e — из кэша пар городов).
      expect(refData.categoryById(cargo.categoryId)?.code, 'CONSTRUCTION');
      expect(cargo.distanceKm, 1230);
      expect(cargo.pricePerKm, closeTo(1500 / 1230, 0.01));
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

    // Живая проверка 2026-10-07: у выбранного отклика был только «Выбран» и
    // никакого перехода — теперь статус сделки и нажатие открывает её.
    await run.step(tester, 'отклик-ведёт-в-сделку', () async {
      final selected = find.byWidgetPredicate((w) => w.key is ValueKey && w.key.toString().contains('responseCard-'));
      await waitFor(tester, selected);
      await tester.tap(selected.first);
      await waitFor(tester, find.text(t.dealDetailTitle));
      expectInsideSafeZone(tester);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
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
