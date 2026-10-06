import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/feed/cargo_feed_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 040: лента на сервере (город → область → остальные, страницами),
/// несколько анонсов, вопрос свежести, «Догруз».

const _almaty = LoadingPoint(id: 'p-almaty', cityId: 'c-almaty', name: I18nText(kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图', en: 'Almaty'), isActive: true);
const _astana = LoadingPoint(id: 'p-astana', cityId: 'c-astana', name: I18nText(kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳', en: 'Astana'), isActive: true);

final _refData = ReferenceData(
  countries: const [
    Country(id: 'kz', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true),
    Country(id: 'uz', code: 'UZ', name: I18nText(kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦'), isCisMember: true),
  ],
  cities: const [],
  bodyTypes: const [BodyType(id: 'bt1', code: 'TENT', name: I18nText(kk: 'Тент', ru: 'Тент', zh: '篷布'))],
  permits: const [],
  points: const [_almaty, _astana],
);

Cargo _cargo(String id, {required String pointId, int? rank, bool partial = false}) => Cargo(
      id: id,
      companyId: 'co',
      companyName: 'Co',
      pointId: pointId,
      destinationCountryId: 'uz',
      bodyTypeId: 'bt1',
      price: 1000,
      currency: Currency.usd,
      readyDate: DateTime(2026, 10, 8),
      status: CargoStatus.published,
      publishedAt: DateTime(2026, 10, 1),
      expiresAt: DateTime(2026, 10, 10),
      allowPartial: partial,
      pickupRank: rank,
      feedSection: CargoFeedSection.selected,
    );

class _FakeCargoRepository extends CargoRepository {
  _FakeCargoRepository(this.pages) : super(ApiClient(baseUrl: 'http://localhost'));

  /// offset → страница.
  final Map<int, CargoFeedPage> pages;
  final requestedOffsets = <int>[];

  @override
  Future<CargoFeedPage> feed({int limit = 30, int offset = 0}) async {
    requestedOffsets.add(offset);
    return pages[offset]!;
  }
}

class _FakeArrivalRepository extends ArrivalRepository {
  _FakeArrivalRepository(this.mineResult) : super(ApiClient(baseUrl: 'http://localhost'));

  final MyArrivals mineResult;
  final calls = <String>[];

  @override
  Future<MyArrivals> mine() async => mineResult;

  @override
  Future<Arrival> stillLooking({String? arrivalId}) async {
    calls.add('still:$arrivalId');
    return mineResult.current!;
  }

  @override
  Future<void> cancel({String? arrivalId}) async => calls.add('cancel:$arrivalId');

  @override
  Future<Arrival> checkIn({String? arrivalId, String? pointId}) async {
    calls.add('checkin:$arrivalId');
    return mineResult.current!;
  }
}

Arrival _arrival(String id, String pointId, ArrivalStatus status, {ArrivalQuestion? ask, DateTime? day}) => Arrival(
      id: id,
      pointId: pointId,
      plannedAt: day ?? DateTime.now(),
      plannedDay: day ?? DateTime.now(),
      arrivedAt: status == ArrivalStatus.onSite ? DateTime.now().subtract(const Duration(hours: 13)) : null,
      waitDays: 3,
      anyCountry: true,
      countryIds: const [],
      status: status,
      viewsCount: 0,
      ask: ask,
    );

Future<void> _pump(
  WidgetTester tester, {
  required _FakeCargoRepository cargos,
  required _FakeArrivalRepository arrivals,
}) async {
  tester.view.physicalSize = const Size(390, 1600) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      cargoRepositoryProvider.overrideWithValue(cargos),
      arrivalRepositoryProvider.overrideWithValue(arrivals),
      referenceDataProvider.overrideWith((ref) async => _refData),
      arrivalTemplateProvider.overrideWith((ref) async => null),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const CargoFeedScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('город погрузки — крупно в карточке («Алматы → Узбекистан»), «Догруз» — плашка, порядок как у сервера', (tester) async {
    final cargos = _FakeCargoRepository({
      0: CargoFeedPage(items: [
        _cargo('here', pointId: 'p-almaty', rank: 0, partial: true),
        _cargo('far', pointId: 'p-astana', rank: 2),
      ], total: 2, offset: 0),
    });
    await _pump(tester, cargos: cargos, arrivals: _FakeArrivalRepository(const MyArrivals(current: null, all: [])));

    expect(find.text('Алматы → Узбекистан'), findsOneWidget);
    expect(find.text('Астана → Узбекистан'), findsOneWidget);
    expect(find.text('Догруз'), findsOneWidget);
    final first = tester.getTopLeft(find.byKey(const Key('feedCargoCard-here'))).dy;
    final second = tester.getTopLeft(find.byKey(const Key('feedCargoCard-far'))).dy;
    expect(first, lessThan(second));
    expect(find.byKey(const Key('feedLoadMoreButton')), findsNothing);
  });

  testWidgets('лента страницами: «Показать ещё» дозагружает следующую страницу и прячется, когда всё показано', (tester) async {
    final cargos = _FakeCargoRepository({
      0: CargoFeedPage(items: [_cargo('c1', pointId: 'p-almaty', rank: 0), _cargo('c2', pointId: 'p-almaty', rank: 0)], total: 3, offset: 0),
      2: CargoFeedPage(items: [_cargo('c3', pointId: 'p-astana', rank: 2)], total: 3, offset: 2),
    });
    await _pump(tester, cargos: cargos, arrivals: _FakeArrivalRepository(const MyArrivals(current: null, all: [])));

    expect(find.byKey(const Key('feedCargoCard-c3')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('feedLoadMoreButton')));
    await tester.tap(find.byKey(const Key('feedLoadMoreButton')));
    await tester.pumpAndSettle();

    expect(cargos.requestedOffsets, [0, 2]);
    expect(find.byKey(const Key('feedCargoCard-c3')), findsOneWidget);
    expect(find.byKey(const Key('feedLoadMoreButton')), findsNothing);
  });

  testWidgets('несколько анонсов: текущий — крупно, остальные — строками с «Отменить»', (tester) async {
    final here = _arrival('a-here', 'p-almaty', ArrivalStatus.onSite);
    final next = _arrival('a-next', 'p-astana', ArrivalStatus.planned, day: DateTime.now().add(const Duration(days: 3)));
    final arrivals = _FakeArrivalRepository(MyArrivals(current: here, all: [here, next]));
    final cargos = _FakeCargoRepository({0: const CargoFeedPage(items: [], total: 0, offset: 0)});
    await _pump(tester, cargos: cargos, arrivals: arrivals);

    expect(find.byKey(const Key('anonsCityName')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('anonsCityName'))).data, 'Алматы');
    expect(find.byKey(const Key('otherArrival-a-next')), findsOneWidget);
    expect(find.textContaining('Астана ·'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('otherArrivalCancel-a-next')));
    await tester.tap(find.byKey(const Key('otherArrivalCancel-a-next')));
    await tester.pumpAndSettle();
    expect(arrivals.calls, ['cancel:a-next']);
  });

  testWidgets('«Ещё ищете груз?»: «Да, ищу» подтверждает именно этот анонс, «Уехал» его закрывает', (tester) async {
    final here = _arrival('a-here', 'p-almaty', ArrivalStatus.onSite, ask: ArrivalQuestion.stillLooking);
    final arrivals = _FakeArrivalRepository(MyArrivals(current: here, all: [here]));
    final cargos = _FakeCargoRepository({0: const CargoFeedPage(items: [], total: 0, offset: 0)});
    await _pump(tester, cargos: cargos, arrivals: arrivals);

    expect(find.text('Ещё ищете груз?'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('arrivalStillYesButton')));
    await tester.tap(find.byKey(const Key('arrivalStillYesButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('arrivalStillLeftButton')));
    await tester.tap(find.byKey(const Key('arrivalStillLeftButton')));
    await tester.pumpAndSettle();

    expect(arrivals.calls, ['still:a-here', 'cancel:a-here']);
  });

  testWidgets('«Доехали?» в день приезда: вопрос + кнопка «Я на месте» с id анонса', (tester) async {
    final today = _arrival('a-today', 'p-almaty', ArrivalStatus.planned, ask: ArrivalQuestion.day);
    final arrivals = _FakeArrivalRepository(MyArrivals(current: today, all: [today]));
    final cargos = _FakeCargoRepository({0: const CargoFeedPage(items: [], total: 0, offset: 0)});
    await _pump(tester, cargos: cargos, arrivals: arrivals);

    expect(find.text('Доехали? Нажмите «Я на месте»'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('driverCheckInButton')));
    await tester.tap(find.byKey(const Key('driverCheckInButton')));
    await tester.pumpAndSettle();
    expect(arrivals.calls, ['checkin:a-today']);
  });
}
