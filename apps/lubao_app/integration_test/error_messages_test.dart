// Задача 074: вместо «Что-то пошло не так» — настоящая причина. Нет сети →
// «Нет интернета»; груза нет → «Груз не найден»; два логиста выбирают одного
// водителя → «отклик уже рассмотрен». Данные — синтетические e2e.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

const _kzLogist = 'e2e-owner@lubao-test.kz';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('074: понятные причины ошибок вместо «Что-то пошло не так»', (tester) async {
    final run = E2eRun(binding, 'error_messages');
    await clearPersistedSession();
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));

    await run.step(tester, 'вход-водителя', () async {
      await loginDriver(tester, '7010000005');
      await waitFor(tester, find.byKey(const Key('feedChipsBar')));
    });

    await run.step(tester, 'нет-сети-нет-интернета', () async {
      // Сеть «пропала»: запросы ленты падают так же, как без связи.
      final offline = InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path == '/cargos') {
          return handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
        }
        handler.next(options);
      });
      final dio = container.read(apiClientProvider).dio;
      // 078: сохранённая лента показалась бы без ошибки — проверяем случай,
      // когда сохранённого нет: тогда «Нет интернета», не «Что-то пошло не так».
      await container.read(apiClientProvider).clearCache();
      dio.interceptors.insert(0, offline);
      try {
        container.invalidate(cargoFeedProvider);
        await tester.pumpAndSettle();
        await waitFor(tester, find.text(t.errNoInternet));
        expect(find.text(t.commonError), findsNothing);
      } finally {
        dio.interceptors.remove(offline);
      }
      container.invalidate(cargoFeedProvider);
      await waitFor(tester, find.byKey(const Key('feedChipsBar')));
    });

    await run.step(tester, 'груза-нет-не-найден', () async {
      GoRouter.of(tester.element(find.byType(NavigationBar))).push('/driver/cargo/00000000-0000-4000-8000-000000000000');
      await waitFor(tester, find.text(t.errCargoNotFound));
      expect(find.text(t.commonError), findsNothing);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'два-логиста-один-водитель', () async {
      // Груз и отклик — через API; другой логист компании успел выбрать водителя,
      // пока у этого логиста открыт список откликов.
      final ref = (await Dio(BaseOptions(baseUrl: e2eApiBase)).get('/reference-data')).data as Map;
      final points = (ref['points'] as List).cast<Map>();
      final kz = (ref['countries'] as List).cast<Map>().firstWhere((c) => c['code'] == 'KZ');
      final logist = await LogistApi.login(email: _kzLogist);
      final cargoId = await logist.publishCargo({
        'pointId': points.firstWhere((p) => '${(p['name'] as Map)['ru']}'.contains('Алматы'))['id'],
        'destinationCountryId': kz['id'],
        'bodyTypeId': (ref['bodyTypes'] as List).cast<Map>().firstWhere((b) => b['code'] == 'TENT')['id'],
        'categoryId': (ref['cargoCategories'] as List).cast<Map>().firstWhere((c) => c['isActive'] != false)['id'],
        'weightKg': 5000,
        'price': 900,
        'currency': 'USD',
        'readyDate': ymd(DateTime.now().add(const Duration(days: 1))),
      });
      addTearDown(() => logist.closeCargo(cargoId));
      await (await DriverApi.login('+77010000004')).respond(cargoId);
      await logoutViaProfile(tester, driver: true);
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('companyLoginEmailField')), _kzLogist);
      await tester.enterText(find.byKey(const Key('companyLoginPasswordField')), e2ePassword);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginSubmitButton')));
      await waitFor(tester, find.text(t.navDrivers));
      GoRouter.of(tester.element(find.byType(NavigationBar))).push('/company/cargos/$cargoId/responses');
      final select = find.byKey(const Key('responseSelectButton'));
      await waitAndReveal(tester, select);
      // «Второй логист» выбирает водителя раньше.
      await logist.select((await logist.pendingResponses(cargoId)).first['id'] as String);
      await tester.tap(select);
      await tester.pumpAndSettle();
      await waitFor(tester, find.text(t.chatResponseClosed));
      expect(find.text(t.commonError), findsNothing);
      expectNoOverflow(tester);
    });
  });
}
