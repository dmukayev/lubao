import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/driver/feed/announce_arrival_sheet.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

const _kz = Country(id: 'kz-1', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true);
const _uz = Country(id: 'uz-1', code: 'UZ', name: I18nText(kk: 'Өзбекстан', ru: 'Узбекистан', zh: '乌兹别克斯坦'), isCisMember: true);
const _point = LoadingPoint(id: 'point-1', cityId: 'city-1', name: I18nText(kk: 'Қорғас', ru: 'Хоргос', zh: '霍尔果斯'), isActive: true);

final _fixture = ReferenceData(
  countries: const [_kz, _uz],
  regions: const [],
  cities: const [],
  bodyTypes: const [],
  permits: const [],
  points: const [_point],
);

class _FakeArrivalRepository extends ArrivalRepository {
  _FakeArrivalRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  String? lastPointId;
  DateTime? lastPlannedAt;
  bool? lastAnyCountry;
  List<String>? lastCountryIds;
  int? lastWaitDays;

  @override
  Future<Arrival> announce({
    required String pointId,
    required DateTime plannedAt,
    bool anyCountry = false,
    List<String> countryIds = const [],
    int waitDays = 2,
  }) async {
    lastPointId = pointId;
    lastPlannedAt = plannedAt;
    lastAnyCountry = anyCountry;
    lastCountryIds = countryIds;
    lastWaitDays = waitDays;
    return Arrival(
      id: 'arrival-1',
      pointId: pointId,
      plannedAt: plannedAt,
      waitDays: waitDays,
      anyCountry: anyCountry,
      countryIds: countryIds,
      status: ArrivalStatus.planned,
      viewsCount: 0,
    );
  }
}

void main() {
  testWidgets('3 taps: today (default) + country + publish calls announce with the right point and country',
      (tester) async {
    final fakeRepo = _FakeArrivalRepository();
    late BuildContext capturedContext;

    await tester.pumpWidget(ProviderScope(
      overrides: [arrivalRepositoryProvider.overrideWithValue(fakeRepo)],
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

    showAnnounceArrivalSheet(capturedContext, refData: _fixture);
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

    expect(fakeRepo.lastPointId, 'point-1');
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
      overrides: [arrivalRepositoryProvider.overrideWithValue(fakeRepo)],
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

    showAnnounceArrivalSheet(capturedContext, refData: _fixture);
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
}
