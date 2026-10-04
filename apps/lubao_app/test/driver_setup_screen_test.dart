import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/profile/driver_setup_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

const _kz = Country(id: 'kz', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true);
const _region =
    Region(id: 'region-1', countryId: 'kz', name: I18nText(kk: 'Жетісу облысы', ru: 'Область Жетысу', zh: '哲特苏州'));
const _shymkent = City(
  id: 'city-1',
  countryId: 'kz',
  regionId: 'region-1',
  name: I18nText(kk: 'Шымкент', ru: 'Шымкент', zh: '奇姆肯特'),
  isCapital: false,
);
const _tent = BodyType(id: 'body-1', code: 'TENT', name: I18nText(kk: 'Тентті', ru: 'Тентованный', zh: '帆布篷车'));

final _fixture = ReferenceData(
  countries: const [_kz],
  regions: const [_region],
  cities: const [_shymkent],
  bodyTypes: const [_tent],
  permits: const [],
  points: const [],
);

class _FakeDriverRepository extends DriverRepository {
  _FakeDriverRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  Driver? lastSubmitted;

  @override
  Future<Driver> updateProfile(DriverSetupInput input) async {
    final driver = Driver(
      id: 'driver-1',
      userId: 'user-1',
      fullName: input.fullName,
      homeCityId: input.homeCityId,
      anyCountry: input.anyCountry,
      isVerified: false,
      ratingAvg: 0,
      ratingCount: 0,
      directionCountryIds: input.directionCountryIds,
      permitIds: input.permitIds,
    );
    lastSubmitted = driver;
    return driver;
  }
}

Widget _wrap(Widget child, {required _FakeDriverRepository driverRepo}) {
  // GoRouter в дереве — `_submit()` при регистрации уходит на '/driver/feed'
  // через context.go(), которому нужен GoRouter-предок.
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => child),
    GoRoute(path: '/driver/feed', builder: (context, state) => const SizedBox()),
  ]);
  return ProviderScope(
    overrides: [
      referenceDataProvider.overrideWith((ref) async => _fixture),
      driverRepositoryProvider.overrideWithValue(driverRepo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
    ),
  );
}

void main() {
  for (final name in ['Ерлан Қасымов', 'Ли Вэй', '李伟', "John O'Neil"]) {
    testWidgets('full-name field accepts "$name" unchanged', (tester) async {
      await tester.pumpWidget(_wrap(const DriverSetupScreen(isRegistration: true), driverRepo: _FakeDriverRepository()));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'Ф.И.О.');
      await tester.enterText(field, name);
      await tester.pump();

      expect(find.text(name), findsOneWidget);
    });
  }

  testWidgets('tapping "Далее" with an empty home city shows the inline error and stays on step 1',
      (tester) async {
    await tester.pumpWidget(_wrap(const DriverSetupScreen(isRegistration: true), driverRepo: _FakeDriverRepository()));
    await tester.pumpAndSettle();

    // Шаг 1 из 3 (задача 021): имя + город. Кузов — шаг 2, недоступен пока
    // не пройдена валидация этого шага.
    await tester.enterText(find.widgetWithText(TextField, 'Ф.И.О.'), 'Ерлан Қасымов');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Выберите город'), findsOneWidget);
    expect(find.text('Какая у вас машина?'), findsNothing);
  });

  testWidgets('selecting "Нет моего города" opens the fallback sheet and completing it finishes registration',
      (tester) async {
    final driverRepo = _FakeDriverRepository();
    await tester.pumpWidget(_wrap(const DriverSetupScreen(isRegistration: true), driverRepo: driverRepo));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Ф.И.О.'), 'Ерлан Қасымов');

    final cityField = find.widgetWithText(TextField, 'Домашний город');
    await tester.tap(cityField);
    await tester.enterText(cityField, 'несуществующийгород');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Нет моего города').last);
    await tester.pumpAndSettle();

    expect(find.text('Населённый пункт'), findsOneWidget);
  });

  testWidgets('3-step wizard: step indicator advances and registration completes on the last step',
      (tester) async {
    final driverRepo = _FakeDriverRepository();
    await tester.pumpWidget(_wrap(const DriverSetupScreen(isRegistration: true), driverRepo: driverRepo));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 1 из 3'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Ф.И.О.'), 'Ерлан Қасымов');
    await tester.tap(find.widgetWithText(TextField, 'Домашний город'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Шымкент, Казахстан').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 2 из 3'), findsOneWidget);
    await tester.tap(find.text('Тентованный'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Далее'));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 3 из 3'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(driverRepo.lastSubmitted, isNotNull);
    expect(driverRepo.lastSubmitted!.fullName, 'Ерлан Қасымов');
  });
}
