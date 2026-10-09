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
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_app/features/shared/share_action.dart';

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
      // Узкий экран с крупным шрифтом (Android 360 dp): закрыть подсказки и
      // клавиатуру, кузов — ниже чипов категорий, сначала на экран.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('postCargoBodyType')));
      await tester.tap(find.byKey(const Key('postCargoBodyType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тентованный').last);
      await tester.pumpAndSettle();
      // Каждое поле — сначала на экран: иначе нажатие не фокусирует его и
      // текст уходит в предыдущее поле (цена оставалась пустой).
      // 055: вес по умолчанию в кг. «18» в кг — подсказка «Может, 18 т?»;
      // дальше вводим как привыкли логисты — 18 500 кг, под полем «= 18,5 т».
      final weight = find.byKey(const Key('postCargoWeight'));
      await reveal(tester, weight);
      await tester.enterText(weight, '18');
      await tester.pumpAndSettle();
      expect(find.text(t.postCargoWeightLooksLikeTons('18')), findsOneWidget);
      await tester.enterText(weight, '18500');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('postCargoWeightHint')), findsNothing);
      expect(find.text('= 18,5 ${t.unitTon}'), findsOneWidget);
      expectNoOverflow(tester);
      for (final (key, value) in [('postCargoVolume', '90'), ('postCargoPrice', '1500')]) {
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
      // Назад наверх — поле города ленивое, следующий шаг начинается с него.
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'выбор-города-погрузки-и-категории', () async {
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
      // 049 п.1: догруз выключен флагом — переключателя «Можно догрузом» нет.
      expect(find.byKey(const Key('postCargoAllowPartial')), findsNothing);
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
      expect(cargo.weightKg, 18500, reason: '055: введено 18 500 кг — в базе кг');
      expect(cargo.allowPartial, isFalse, reason: 'догруз выключен — пометки нет');
      final refData = await container.read(referenceDataProvider.future);
      expect(refData.pointOrNull(cargo.pointId)?.name.ru, 'Астана', reason: 'город погрузки — из выбора, не первая точка');
      // 047: категория ушла, расстояние Астана → Алматы посчитано (в e2e — из кэша пар городов).
      expect(refData.categoryById(cargo.categoryId)?.code, 'CONSTRUCTION');
      expect(cargo.distanceKm, 1230);
      expect(cargo.pricePerKm, closeTo(1500 / 1230, 0.01));
      cargoId = cargo.id;
      expectNoOverflow(tester);
    });

    // 052: логист делится грузом — системное меню получает текст по эталону 30
    // (маршрут, вес, цена, ссылка /c/<код>, без телефона); «Все» — ссылка /co.
    // Публичная страница по ссылке открывается без входа.
    late String sharePath;
    await run.step(tester, 'поделиться-грузом', () async {
      final shared = <String>[];
      debugShareOverride = (text) async => shared.add(text);
      addTearDown(() => debugShareOverride = null);
      final share = find.byKey(Key('cargoShare-$cargoId'));
      await waitAndReveal(tester, share);
      await tester.tap(share);
      await tester.pumpAndSettle();
      await waitForCondition(tester, () => shared.isNotEmpty);
      final text = shared.single;
      expect(text, contains('→ Алматы'));
      expect(text, contains('18,5 ${t.unitTon}'));
      expect(text, contains(r'$1 500'), reason: 'цена как в ленте (груз в долларах)');
      expect(text, isNot(matches(RegExp(r'\+7\d'))), reason: 'телефона в тексте нет');
      final url = RegExp(r'https?://\S+/c/([A-Za-z0-9]{4,12})').firstMatch(text);
      expect(url, isNotNull, reason: 'ссылка /c/<код>: $text');
      sharePath = '/c/${url!.group(1)}';
      await tester.tap(find.byKey(const Key('shareAllCargos')));
      await tester.pumpAndSettle();
      await waitForCondition(tester, () => shared.length == 2);
      expect(shared.last, contains('/co/'));
      expect(shared.last.split('\n').first, contains('Urumqi Test Logistics'));
      final page = await Dio(BaseOptions(baseUrl: e2eApiBase, validateStatus: (_) => true, headers: {'Accept-Language': 'ru-RU'})).get<String>('/p$sharePath');
      expect(page.statusCode, 200);
      expect(page.data, contains('→ Алматы'));
      expect(page.data, contains('Откликнуться в приложении'));
      expect(page.data, isNot(matches(RegExp(r'\+7\d|tel:'))));
    });

    // 056 п.3: «Повторить» — форма заполнена по старому грузу (маршрут, кузов,
    // вес, цена), дата — сегодня; публикуется новый груз, старый не трогается.
    // 056 п.4: внизу у логиста нет вкладки «Сделки».
    await run.step(tester, 'повторить-груз', () async {
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(t.navDeals)), findsNothing);
      final repeat = find.byKey(Key('cargoRepeat-$cargoId'));
      await waitAndReveal(tester, repeat);
      await tester.tap(repeat);
      await waitFor(tester, find.byKey(const Key('postCargoDestination')));
      // Форма длиннее экрана SE с крупным шрифтом — поля ниже, прокручиваем.
      await waitAndReveal(tester, find.text('18500'));
      await waitAndReveal(tester, find.text('1500'));
      expect(find.text(t.postCargoTitle), findsWidgets, reason: 'новый груз, не редактирование');
      expectNoOverflow(tester);
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitFor(tester, find.byKey(const Key('companyPostCargoFab')));
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      final cargos = await container.read(myCargosProvider.future);
      final copy = cargos.firstWhere((c) => c.id != cargoId);
      final original = cargos.firstWhere((c) => c.id == cargoId);
      expect(copy.price, original.price);
      expect(copy.weightKg, original.weightKg);
      expect(copy.pointId, original.pointId);
      expect(copy.destinationCityId, original.destinationCityId);
      await waitAndReveal(tester, find.byKey(Key('companyCargoCard-${copy.id}')));
      expect(find.textContaining('${t.cargosTabActive} 2'), findsOneWidget, reason: 'на вкладке — число активных');
      await waitAndReveal(tester, find.byKey(Key('companyCargoCard-$cargoId')));
    });

    // 056 п.1 / п.7: водитель откликнулся на копию, логист её снял — у водителя
    // отклик уходит в «Историю рейсов» с причиной «Груз снят».
    late String copyId;
    await run.step(tester, 'снятый-груз-закрывает-отклик', () async {
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      copyId = (await container.read(myCargosProvider.future)).firstWhere((c) => c.id != cargoId).id;
      await (await DriverApi.login('+77010000001')).respond(copyId);
      await container.read(cargoRepositoryProvider).close(copyId, outcome: 'CARGO_CANCELLED');
    });

    // 055: водитель видит вес в тоннах — «18,5 т».
    await run.step(tester, 'вес-в-ленте-водителя', () async {
      await logoutViaProfile(tester, driver: false);
      await loginDriver(tester, '7010000001');
      await waitFor(tester, find.byType(NavigationBar));
      final card = find.byKey(Key('feedCargoCard-$cargoId'));
      await waitAndReveal(tester, card, timeout: const Duration(seconds: 30));
      expect(find.descendant(of: card, matching: find.textContaining('18,5 ${t.unitTon}')), findsOneWidget);
      // 052: вход по ссылке → экран груза; водитель делится чужим грузом.
      GoRouter.of(tester.element(find.byType(NavigationBar))).go(sharePath);
      await waitFor(tester, find.byKey(const Key('cargoDetailShare')), timeout: const Duration(seconds: 30));
      final shared = <String>[];
      debugShareOverride = (text) async => shared.add(text);
      await tester.tap(find.byKey(const Key('cargoDetailShare')));
      await tester.pumpAndSettle();
      await waitForCondition(tester, () => shared.isNotEmpty);
      debugShareOverride = null;
      expect(shared.single, contains('/c/'));
      expect(shared.single, isNot(contains(sharePath)), reason: 'у водителя своя ссылка — отклики считаются за него');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/driver/feed');
      await waitFor(tester, find.byType(NavigationBar));
      // 056 п.6: снятый груз — в «Истории рейсов» с причиной.
      await goTab(tester, t.profileTitle);
      final history = find.byKey(const Key('profileTripHistory'));
      await waitAndReveal(tester, history);
      await tester.tap(history);
      await waitFor(tester, find.byKey(const Key('historyList')));
      await waitAndReveal(tester, find.text(t.closeReasonCargoClosed));
      expectNoOverflow(tester);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await logoutViaProfile(tester, driver: true);
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('companyLoginEmailField')), e2eNewCompanyEmail);
      await tester.enterText(find.byKey(const Key('companyLoginPasswordField')), e2ePassword);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginSubmitButton')));
      await waitFor(tester, find.text(t.navDrivers));
      await goTab(tester, t.navCargos);
      await waitAndReveal(tester, find.byKey(Key('companyCargoCard-$cargoId')));
    });

    await run.step(tester, 'водитель-откликается', () async {
      final driver = await DriverApi.login('+77010000003');
      await driver.respond(cargoId);
    });

    // 056 п.5: отклик → «1 новый» на карточке и цифра на «Грузах»; открыл
    // отклики — точка у нового, после возврата «новых» нет.
    await run.step(tester, 'новый-отклик-у-логиста', () async {
      await goTab(tester, t.navDrivers);
      await goTab(tester, t.navCargos);
      final line = find.byKey(Key('cargoResponsesLine-$cargoId'));
      await waitAndReveal(tester, line);
      await waitFor(tester, find.descendant(of: line, matching: find.textContaining(t.cargoResponsesNew(1)), matchRoot: true));
      await waitFor(tester, find.descendant(of: find.byKey(const Key('navCargosBadge')), matching: find.text('1')));
      await tester.tap(find.byKey(Key('companyCargoCard-$cargoId')));
      await waitFor(tester, find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('responseNewDot-')));
      expectNoOverflow(tester);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.navDrivers);
      await goTab(tester, t.navCargos);
      await waitAndReveal(tester, line);
      expect(find.descendant(of: line, matching: find.textContaining(t.cargoResponsesNew(1)), matchRoot: true), findsNothing);
    });

    await run.step(tester, 'выбор-водителя-в-откликах', () async {
      final card = find.byKey(Key('companyCargoCard-$cargoId'));
      await tester.pumpAndSettle();
      await tester.tap(card);
      await waitFor(tester, find.byKey(const Key('responseSelectButton')));
      expectInsideSafeZone(tester);
      await tester.tap(find.byKey(const Key('responseSelectButton')));
      await tester.pumpAndSettle();
      // 055: груз 18,5 т, а D3 уже везёт 5 т из 20 — честное предупреждение
      // «Машина уже заполнена» (038 п.9); логист выбирает всё равно.
      final anyway = find.text(t.selectDriverAnywayButton);
      if (anyway.evaluate().isNotEmpty) {
        await tester.tap(anyway);
        await tester.pumpAndSettle();
      }
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

    // 056 п.2: груз со сделкой — во вкладке «В работе»; нажатие — сделка.
    await run.step(tester, 'груз-в-работе', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await goTab(tester, t.navCargos);
      await tester.tap(find.byKey(const Key('companyCargosTab-work')));
      await tester.pumpAndSettle();
      final card = find.byKey(Key('companyCargoCard-$cargoId'));
      await waitAndReveal(tester, card);
      expect(find.byKey(Key('cargoRepeat-$cargoId')), findsNothing, reason: 'в работе «Повторить» нет');
      await tester.tap(card);
      await waitFor(tester, find.text(t.dealDetailTitle));
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      expectInsideSafeZone(tester);
      expectNoOverflow(tester);
    });
  });
}
