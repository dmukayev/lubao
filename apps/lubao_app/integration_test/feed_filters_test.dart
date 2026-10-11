// Задача 059: лента водителя — чип «Россия» → только грузы в Россию; фильтр
// кузов + вес → счётчик шторки совпадает со списком; сортировка «выгоднее
// ₸/км» — как на сервере; «Грузы из других городов» свёрнуты и раскрываются.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

const _kzLogist = 'e2e-owner@lubao-test.kz';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('059: чипы «куда», фильтры со счётчиком, сортировка ₸/км, свёрнутые другие города', (tester) async {
    final run = E2eRun(binding, 'feed_filters');
    await clearPersistedSession();

    late String ruId, tentId;
    await run.step(tester, 'логист-публикует-грузы-из-алматы', () async {
      final ref = (await Dio(BaseOptions(baseUrl: e2eApiBase)).get('/reference-data')).data as Map;
      final countries = (ref['countries'] as List).cast<Map>();
      final cities = (ref['cities'] as List).cast<Map>();
      final points = (ref['points'] as List).cast<Map>();
      ruId = countries.firstWhere((c) => c['code'] == 'RU')['id'] as String;
      final uzId = countries.firstWhere((c) => c['code'] == 'UZ')['id'] as String;
      final moscow = cities.firstWhere((c) => c['code'] == 'RU-MOSCOW')['id'];
      tentId = (ref['bodyTypes'] as List).cast<Map>().firstWhere((b) => b['code'] == 'TENT')['id'] as String;
      final category = (ref['cargoCategories'] as List).cast<Map>().firstWhere((c) => c['isActive'] != false)['id'];
      final almaty = points.firstWhere((p) => '${(p['name'] as Map)['ru']}'.contains('Алматы'))['id'];
      final logist = await LogistApi.login(email: _kzLogist);
      final tomorrow = ymd(DateTime.now().add(const Duration(days: 1)));
      Map<String, dynamic> body(String country, Object? city, int weightKg, num price) => {
            'pointId': almaty, 'destinationCountryId': country, if (city != null) 'destinationCityId': city, 'bodyTypeId': tentId,
            'categoryId': category, 'weightKg': weightKg, 'price': price, 'currency': 'USD', 'readyDate': tomorrow,
          };
      final ids = [
        await logist.publishCargo(body(ruId, moscow, 18000, 3000)),
        await logist.publishCargo(body(ruId, moscow, 8000, 1500)),
        await logist.publishCargo(body(uzId, null, 12000, 1200)),
      ];
      // Грузы сценария снимаются в конце (и при падении): счётчики админки и
      // следующих сценариев — как без него.
      addTearDown(() async {
        for (final id in ids) {
          await logist.closeCargo(id);
        }
      });
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    late DriverApi api;

    Set<String> visibleCardIds() => find
        .byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('feedCargoCard-'))
        .evaluate()
        .map((e) => (e.widget.key! as ValueKey<String>).value.substring('feedCargoCard-'.length))
        .toSet();

    await run.step(tester, 'вход-водителя', () async {
      await loginDriver(tester, '7010000005');
      await waitFor(tester, find.byKey(const Key('feedChipsBar')));
      api = await DriverApi.login('+77010000005');
    });

    await run.step(tester, 'чип-россия-только-грузы-в-россию', () async {
      final chip = find.byKey(Key('feedChipCountry-$ruId'));
      // Полоса чипов горизонтальная — прокручиваем её до «России».
      await tester.scrollUntilVisible(chip, 120, scrollable: find.descendant(of: find.byKey(const Key('feedChipsBar')), matching: find.byType(Scrollable)).first, maxScrolls: 30);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final expected = ((await api.feed({'toCountryId': ruId}))['items'] as List).cast<Map>().map((c) => c['id'] as String).toSet();
      expect(expected.length, greaterThanOrEqualTo(2));
      for (final id in expected) {
        await reveal(tester, find.byKey(Key('feedCargoCard-$id')));
      }
      // Все грузы в Россию (и из других городов — если строку раскрыли).
      final allRu = ((await api.feed({'toCountryId': ruId, 'showOtherCities': 'true'}))['items'] as List).cast<Map>().map((c) => c['id'] as String).toSet();
      expect(visibleCardIds().difference(allRu), isEmpty, reason: 'в ленте только грузы в Россию');
      expectNoOverflow(tester);
      // Снова «Все».
      await tester.tap(find.byKey(const Key('feedChipAll')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    await run.step(tester, 'фильтр-кузов-и-вес-счётчик-как-список', () async {
      await tester.tap(find.byKey(const Key('feedFiltersButton')));
      await waitFor(tester, find.byKey(const Key('feedFilterSheet')));
      final tent = find.byKey(Key('feedFilterBody-$tentId'));
      await reveal(tester, tent);
      await tester.tap(tent);
      await reveal(tester, find.byKey(const Key('feedFilterWeight-min')));
      await tester.enterText(find.byKey(const Key('feedFilterWeight-min')), '10');
      await tester.enterText(find.byKey(const Key('feedFilterWeight-max')), '20');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final expected = (await api.feed({'bodyTypeIds': tentId, 'weightMinT': 10, 'weightMaxT': 20}))['total'] as int;
      await waitFor(tester, find.text(t.feedFilterShow('$expected')));
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('feedFilterShow')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await waitFor(tester, find.text(t.driverHomeFeedCount(expected)));
      expect(find.byKey(const Key('feedActive-weight')), findsOneWidget);
      // Снять фильтры ✕.
      await tester.tap(find.descendant(of: find.byKey(const Key('feedActive-weight')), matching: find.byType(Icon)).last);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byKey(Key('feedActive-body-$tentId')), matching: find.byType(Icon)).last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('feedActiveFilters')), findsNothing);
    });

    await run.step(tester, 'сортировка-выгоднее-км', () async {
      await tester.tap(find.byKey(const Key('feedSortButton')));
      await waitFor(tester, find.byKey(const Key('feedSort-perKm')));
      await tester.tap(find.byKey(const Key('feedSort-perKm')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final first = ((await api.feed({'sort': 'per_km'}))['items'] as List).cast<Map>().first['id'] as String;
      await waitFor(tester, find.byKey(Key('feedCargoCard-$first')));
      expect(firstFeedCargoId(tester), first);
      await tester.tap(find.byKey(const Key('feedSortButton')));
      await waitFor(tester, find.byKey(const Key('feedSort-standard')));
      await tester.tap(find.byKey(const Key('feedSort-standard')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    await run.step(tester, 'другие-города-свёрнуты-и-раскрываются', () async {
      final res = await api.feed({});
      final other = res['otherCitiesCount'] as int;
      expect(other, greaterThan(0), reason: 'у водителя из Алматы грузы из Хоргоса — «другие города»');
      final expand = find.byKey(const Key('feedOtherCitiesExpand'));
      await reveal(tester, expand);
      expect(find.descendant(of: expand, matching: find.text(t.feedOtherCities('$other'))), findsOneWidget);
      await tester.tap(expand);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final all = ((await api.feed({'showOtherCities': 'true'}))['total'] as int);
      await reveal(tester, find.text(t.driverHomeFeedCount(all)));
      await reveal(tester, find.byKey(const Key('feedOtherCitiesCollapse')));
      await tester.tap(find.byKey(const Key('feedOtherCitiesCollapse')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
  });
}
