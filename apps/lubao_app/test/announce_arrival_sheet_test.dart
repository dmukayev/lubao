import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/feed/announce_arrival_sheet.dart';
import 'package:lubao_app/features/shared/city_picking.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

const _kz = Country(id: 'kz-1', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true);
const _uz = Country(id: 'uz-1', code: 'UZ', name: I18nText(kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦'), isCisMember: true);
const _almaty = LoadingPoint(id: 'point-almaty', cityId: 'city-almaty', name: I18nText(kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图', en: 'Almaty'), isActive: true);
const _astana = LoadingPoint(id: 'point-astana', cityId: 'city-astana', name: I18nText(kk: 'Астана', ru: 'Астана', zh: '阿斯塔纳', en: 'Astana'), isActive: true);

final _fixture = ReferenceData(
  countries: const [_kz, _uz],
  regions: const [],
  cities: const [],
  bodyTypes: const [],
  permits: const [],
  points: const [_almaty, _astana],
);

class _FakeRecentPoints extends RecentPointsStore {
  final remembered = <String>[];

  @override
  Future<List<String>> load() async => const [];

  @override
  Future<void> remember(String pointId) async => remembered.add(pointId);
}

class _FakeArrivalRepository extends ArrivalRepository {
  _FakeArrivalRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  int announceCalls = 0;
  String? lastArrivalId;
  String? lastPointId;
  DateTime? lastPlannedAt;
  bool? lastAnyCountry;
  List<String>? lastCountryIds;
  int? lastWaitDays;

  @override
  Future<Arrival> announce({
    String? arrivalId,
    required String pointId,
    required DateTime plannedAt,
    bool anyCountry = false,
    List<String> countryIds = const [],
    int waitDays = 2,
    String? tractorId,
    String? trailerId,
  }) async {
    announceCalls++;
    lastArrivalId = arrivalId;
    lastPointId = pointId;
    lastPlannedAt = plannedAt;
    lastAnyCountry = anyCountry;
    lastCountryIds = countryIds;
    lastWaitDays = waitDays;
    return Arrival(
      id: 'arrival-1',
      pointId: pointId,
      plannedAt: plannedAt,
      plannedDay: plannedAt,
      waitDays: waitDays,
      anyCountry: anyCountry,
      countryIds: countryIds,
      status: ArrivalStatus.planned,
      viewsCount: 0,
    );
  }
}

void main() {
  testWidgets('3 taps: домашний город по умолчанию + today + country + publish calls announce with the right point and country',
      (tester) async {
    final fakeRepo = _FakeArrivalRepository();
    late BuildContext capturedContext;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        arrivalRepositoryProvider.overrideWithValue(fakeRepo),
        recentPointsStoreProvider.overrideWithValue(_FakeRecentPoints()),
        garageVehiclesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          capturedContext = context;
          return const Scaffold(body: SizedBox());
        }),
      ),
    ));
    await tester.pumpAndSettle();

    showAnnounceArrivalSheet(capturedContext, refData: _fixture, driverHomeCityId: 'city-almaty');
    await tester.pumpAndSettle();

    // Шаг 1: «Когда» — «Сегодня» уже выбрано по умолчанию, трогать не нужно.
    // Шаг 2: «Куда готов» — выбрать страну.
    await tester.tap(find.text('Узбекистан'));
    await tester.pumpAndSettle();

    // Шаг 3: «Опубликовать».
    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastPointId, 'point-almaty');
    expect(fakeRepo.lastAnyCountry, false);
    expect(fakeRepo.lastCountryIds, ['uz-1']);
    expect(fakeRepo.lastPlannedAt, isNotNull);
    final now = DateTime.now();
    expect(fakeRepo.lastPlannedAt!.year, now.year);
    expect(fakeRepo.lastPlannedAt!.month, now.month);
    expect(fakeRepo.lastPlannedAt!.day, now.day);
  });

  testWidgets('tapping "Любая страна" clears individual country chips and sends anyCountry=true', (tester) async {
    final fakeRepo = _FakeArrivalRepository();
    late BuildContext capturedContext;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        arrivalRepositoryProvider.overrideWithValue(fakeRepo),
        recentPointsStoreProvider.overrideWithValue(_FakeRecentPoints()),
        garageVehiclesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          capturedContext = context;
          return const Scaffold(body: SizedBox());
        }),
      ),
    ));
    await tester.pumpAndSettle();

    showAnnounceArrivalSheet(capturedContext, refData: _fixture, driverHomeCityId: 'city-almaty');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Любая страна'));
    await tester.pumpAndSettle();
    expect(find.text('Узбекистан'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastAnyCountry, true);
    expect(fakeRepo.lastCountryIds, isEmpty);
  });

  Future<(_FakeArrivalRepository, BuildContext)> pumpHost(WidgetTester tester, {_FakeRecentPoints? recent}) async {
    final fakeRepo = _FakeArrivalRepository();
    late BuildContext capturedContext;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        arrivalRepositoryProvider.overrideWithValue(fakeRepo),
        recentPointsStoreProvider.overrideWithValue(recent ?? _FakeRecentPoints()),
        garageVehiclesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          capturedContext = context;
          return const Scaffold(body: SizedBox());
        }),
      ),
    ));
    await tester.pumpAndSettle();
    return (fakeRepo, capturedContext);
  }

  testWidgets('040: без города по умолчанию «Опубликовать» показывает ошибку и не отправляет; город из выбора уходит в анонс', (tester) async {
    final recent = _FakeRecentPoints();
    final (fakeRepo, context) = await pumpHost(tester, recent: recent);

    showAnnounceArrivalSheet(context, refData: _fixture);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите город, где вы свободны'), findsOneWidget);
    expect(fakeRepo.announceCalls, 0);

    await tester.ensureVisible(find.byKey(const Key('announceCityField')));
    await tester.tap(find.byKey(const Key('announceCityField')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cityPickerRow-point-astana')));
    await tester.pumpAndSettle();

    expect(find.text('Выберите город, где вы свободны'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastPointId, 'point-astana');
    expect(recent.remembered, ['point-astana']);
  });

  testWidgets('040: выбор города ищет на любом языке и на латинице («Astana» при русском интерфейсе)', (tester) async {
    final (_, context) = await pumpHost(tester);

    showAnnounceArrivalSheet(context, refData: _fixture);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('announceCityField')));
    await tester.tap(find.byKey(const Key('announceCityField')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('cityPickerSearch')), 'Astana');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cityPickerRow-point-astana')), findsOneWidget);
    expect(find.byKey(const Key('cityPickerRow-point-almaty')), findsNothing);

    await tester.enterText(find.byKey(const Key('cityPickerSearch')), 'зззз');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('040: правка существующего анонса — город уже выбран, в запрос уходит arrivalId', (tester) async {
    final (fakeRepo, context) = await pumpHost(tester);
    final editing = Arrival(
      id: 'arrival-42',
      pointId: 'point-astana',
      plannedAt: DateTime.now(),
      plannedDay: DateTime.now(),
      waitDays: 3,
      anyCountry: true,
      countryIds: const [],
      status: ArrivalStatus.planned,
      viewsCount: 0,
    );

    showAnnounceArrivalSheet(context, refData: _fixture, editing: editing);
    await tester.pumpAndSettle();
    expect(find.text('Астана'), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Опубликовать'));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastArrivalId, 'arrival-42');
    expect(fakeRepo.lastPointId, 'point-astana');
    expect(fakeRepo.lastWaitDays, 3);
    expect(fakeRepo.lastAnyCountry, true);
  });
}
