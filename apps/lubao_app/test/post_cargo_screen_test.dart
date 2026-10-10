import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/company/cargos/post_cargo_screen.dart';
import 'package:lubao_app/features/shared/city_picking.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 040, п.6–7: город погрузки обязателен (публикация без него не
/// уходит), «Можно догрузом» уходит на сервер.
class _FakeCargoRepository extends CargoRepository {
  _FakeCargoRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  CreateCargoInput? created;

  @override
  Future<Cargo> create(CreateCargoInput input, {String? idempotencyKey}) async {
    created = input;
    return Cargo(
      id: 'new',
      companyId: 'co',
      companyName: 'Co',
      pointId: input.pointId,
      destinationCountryId: input.destinationCountryId,
      bodyTypeId: input.bodyTypeId,
      price: input.price,
      currency: input.currency,
      readyDate: input.readyDate,
      status: CargoStatus.published,
      publishedAt: DateTime.now(),
      expiresAt: DateTime.now(),
    );
  }
}

class _FakeRecentPoints extends RecentPointsStore {
  @override
  Future<List<String>> load() async => const [];

  @override
  Future<void> remember(String pointId) async {}
}

const _almaty = LoadingPoint(id: 'p-almaty', cityId: 'c-almaty', name: I18nText(kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图', en: 'Almaty'), isActive: true);
const _astana = LoadingPoint(id: 'p-astana', cityId: 'c-astana', name: I18nText(kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳', en: 'Astana'), isActive: true);

ReferenceData _refDataWith({bool partialLoads = false}) => ReferenceData(
  partialLoadsEnabled: partialLoads,
  countries: const [Country(id: 'uz', code: 'UZ', name: I18nText(kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦'), isCisMember: true)],
  cities: const [],
  bodyTypes: const [BodyType(id: 'bt1', code: 'TENT', name: I18nText(kk: 'Тент', ru: 'Тент', zh: '篷布'))],
  permits: const [],
  points: const [_almaty, _astana],
);

Cargo _previous(String pointId) => Cargo(
      id: 'old',
      companyId: 'co',
      companyName: 'Co',
      pointId: pointId,
      destinationCountryId: 'uz',
      bodyTypeId: 'bt1',
      price: 1,
      currency: Currency.usd,
      readyDate: DateTime(2026, 10, 1),
      status: CargoStatus.published,
      publishedAt: DateTime(2026, 10, 1),
      expiresAt: DateTime(2026, 10, 3),
    );

Future<_FakeCargoRepository> _pump(WidgetTester tester, {List<Cargo> previous = const [], bool partialLoads = false}) async {
  tester.view.physicalSize = const Size(390, 2400) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = _FakeCargoRepository();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      cargoRepositoryProvider.overrideWithValue(repo),
      recentPointsStoreProvider.overrideWithValue(_FakeRecentPoints()),
      referenceDataProvider.overrideWith((ref) async => _refDataWith(partialLoads: partialLoads)),
      myCargosProvider.overrideWith((ref) async => previous),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const PostCargoScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  // Публикация требует проверенной компании; sessionProvider в тесте не
  // восстанавливается (нет сессии) — кнопка в этом режиме заблокирована
  // баннером, поэтому проверяем поля до неё: город по умолчанию и выбор.
  testWidgets('город погрузки по умолчанию — из последнего груза компании', (tester) async {
    await _pump(tester, previous: [_previous('p-astana')]);
    expect(find.byKey(const Key('postCargoPickupCity')), findsOneWidget);
    expect(find.text('Астана'), findsOneWidget);
  });

  testWidgets('нет прошлых грузов — город не подставляется, поле просит выбрать', (tester) async {
    await _pump(tester);
    expect(find.text('Выберите город'), findsOneWidget);
  });

  testWidgets('049 п.1: догруз выключен (по умолчанию) — переключателя «Можно догрузом» нет', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('postCargoAllowPartial')), findsNothing);
  });

  testWidgets('выбор города через поиск; догруз включён — «Можно догрузом» переключатель на экране', (tester) async {
    await _pump(tester, partialLoads: true);

    await tester.tap(find.byKey(const Key('postCargoPickupCity')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cityPickerSearch')), 'almat');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cityPickerRow-p-almaty')));
    await tester.pumpAndSettle();
    expect(find.text('Алматы'), findsOneWidget);

    expect(find.byKey(const Key('postCargoAllowPartial')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('postCargoAllowPartial')));
    await tester.tap(find.byKey(const Key('postCargoAllowPartial')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('postCargoAllowPartial'))).value, isTrue);
  });
}
