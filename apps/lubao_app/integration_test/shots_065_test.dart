// Задача 065: снимки для сравнения с эталоном 35 — грузы логиста как в эталоне
// («Астана → Ош» $100 000, «Астана → Минск» $4 800, «Алматы → Шымкент»
// 520 000 ₸) и лента водителя с грузом в рублях. Только снимки: в общий
// прогон `scripts/e2e.sh` не входит (E2E_ONLY="shots_065_test"). Данные — синтетика.
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

  testWidgets('065: снимки карточек — правый столбец цены по эталону 35', (tester) async {
    final run = E2eRun(binding, 'shots_065');
    await clearPersistedSession();
    final ref = (await Dio(BaseOptions(baseUrl: e2eApiBase)).get('/reference-data')).data as Map;
    Map city(String code) => (ref['cities'] as List).cast<Map>().firstWhere((c) => c['code'] == code);
    String pointIn(String cityCode) => (ref['points'] as List).cast<Map>().firstWhere((p) => p['cityId'] == city(cityCode)['id'])['id'] as String;
    String body(String code) => (ref['bodyTypes'] as List).cast<Map>().firstWhere((b) => b['code'] == code)['id'] as String;
    final category = (ref['cargoCategories'] as List).cast<Map>().firstWhere((c) => c['isActive'] != false)['id'];
    String day(int d) => ymd(DateTime.now().add(Duration(days: d)));
    Map<String, dynamic> cargo(String from, String to, String bodyCode, int kg, num price, String currency, {int? delay, String? form, num? advance, int trucks = 1, num? volume, Map<String, dynamic>? specs}) => {
          'pointId': pointIn(from),
          'destinationCountryId': city(to)['countryId'],
          'destinationCityId': city(to)['id'],
          'bodyTypeId': body(bodyCode),
          'categoryId': category,
          'weightKg': kg,
          if (volume != null) 'volumeM3': volume,
          if (specs != null) 'specs': specs,
          'price': price,
          'currency': currency,
          if (delay != null) 'paymentDelayDays': delay,
          if (form != null) 'paymentForm': form,
          if (advance != null) 'advanceAmount': advance,
          'trucksNeeded': trucks,
          'readyDate': day(1),
        };

    await run.step(tester, 'данные-как-в-эталоне-35', () async {
      final logist = await LogistApi.login();
      // Порядок публикации — снизу вверх: новые в «Активных» сверху.
      final shymkent = await logist.publishCargo(cargo('KZ-ALMATY', 'KZ-SHYMKENT', 'TENT', 18000, 520000, 'KZT', delay: 10, form: 'CARD', trucks: 2));
      await (await DriverApi.login('+77010000003')).respond(shymkent);
      await logist.select((await logist.pendingResponses(shymkent)).first['id'] as String);
      final minsk = await logist.publishCargo(cargo('KZ-ASTANA', 'BY-MINSK', 'ISOTHERM', 10000, 4800, 'USD', form: 'CASHLESS', advance: 1000, volume: 35));
      await (await DriverApi.login('+77010000004')).respond(minsk);
      await logist.pendingResponses(minsk); // логист открыл отклики — первый уже не «новый»
      await (await DriverApi.login('+77010000005')).respond(minsk);
      await (await DriverApi.login('+77010000001')).respond(minsk);
      await logist.publishCargo(cargo('KZ-ASTANA', 'KG-OSH', 'CONTAINER', 20000, 100000, 'USD', delay: 5, form: 'CASH', advance: 1000, trucks: 5, specs: {'containerType': '40', 'containerCount': 1}));
      // Лента водителя — груз в рублях с километрами.
      final kz = await LogistApi.login(email: _kzLogist);
      await kz.publishCargo(cargo('KZ-ASTANA', 'RU-MOSCOW', 'TENT', 20000, 1250000, 'RUB', delay: 5, form: 'CASH', advance: 300000, volume: 82));
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'грузы-активные', () async {
      await loginLogist(tester);
      await waitFor(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text(t.navCargos)), timeout: const Duration(seconds: 30));
      await goTab(tester, t.navCargos);
      await waitFor(tester, find.byKey(const Key('companyCargosList-active')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    await run.step(tester, 'грузы-активные-ниже', () async {
      await tester.drag(find.byKey(const Key('companyCargosList-active')), const Offset(0, -420));
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'лента-водителя-рубли', () async {
      await logoutViaProfile(tester, driver: false);
      await loginDriver(tester, '7010000005');
      await waitFor(tester, find.byKey(const Key('feedChipsBar')));
      await reveal(tester, find.text('1 250 000 ₽'));
      await tester.pumpAndSettle();
    });
  });
}
