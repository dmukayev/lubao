import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/company/drivers/drivers_at_point_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_app/features/shared/city_picking.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 036, п.8 — экран «Водители» открывается без переполнений на 360 px
/// (и при крупном шрифте 1.3), фильтр «Проверенные» меняет список.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient(baseUrl: 'http://localhost'));
  @override
  Future<Session?> restore() async => null;
}

class _FakeArrivalRepository extends ArrivalRepository {
  _FakeArrivalRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  final calls = <bool>[];
  String? lastPointId;
  double? lastMinCapacity;
  String? lastBodyTypeId;

  ArrivalListing _driver(String id, String name, {required bool verified, required ArrivalStatus status}) => ArrivalListing(
        arrivalId: 'a-$id',
        driverId: id,
        driverName: name,
        phone: '+77010000000',
        isVerified: verified,
        ratingAvg: 4.8,
        ratingCount: 3,
        pointId: 'p1',
        status: status,
        plannedAt: DateTime.now(),
        plannedDay: DateTime.now(),
        arrivedAt: status == ArrivalStatus.onSite ? DateTime.now().subtract(const Duration(minutes: 15)) : null,
        bodyTypeId: 'bt1',
        capacityTons: 20,
        volumeM3: 90,
        palletsEuro: 33,
        anyCountry: false,
        directionCountryIds: const ['kz', 'uz', 'kg'],
      );

  @override
  Future<List<ArrivalListing>> listForCompany({
    DateTime? date,
    String? pointId,
    String? countryId,
    String? bodyTypeId,
    double? minCapacityTons,
    bool verifiedOnly = false,
  }) async {
    calls.add(verifiedOnly);
    lastPointId = pointId;
    lastMinCapacity = minCapacityTons;
    lastBodyTypeId = bodyTypeId;
    final all = [
      _driver('d1', 'Ерлан Сагынбаев Очень Длинное Имя', verified: true, status: ArrivalStatus.onSite),
      _driver('d2', 'Асет Нурланов', verified: false, status: ArrivalStatus.planned),
    ];
    return verifiedOnly ? all.where((d) => d.isVerified).toList() : all;
  }

  @override
  Future<List<ArrivalSummaryDay>> summary({int days = 7, String? pointId}) async =>
      [for (var i = 0; i < days; i++) ArrivalSummaryDay(date: DateTime.now().add(Duration(days: i)), count: i == 0 ? 2 : (i == 2 ? 3 : 0))];
}

ReferenceData _refData({bool twoPoints = false}) => ReferenceData(
      countries: [
        for (final c in ['kz', 'uz', 'kg'])
          Country(id: c, code: c.toUpperCase(), name: I18nText(kk: c, ru: c, zh: c), isCisMember: true),
      ],
      cities: const [],
      bodyTypes: const [BodyType(id: 'bt1', code: 'TENT', name: I18nText(kk: 'Тент', ru: 'Тент', zh: '篷布'))],
      permits: const [],
      points: [
        const LoadingPoint(id: 'p1', cityId: 'c1', name: I18nText(kk: 'Хоргос', ru: 'Хоргос', zh: '霍尔果斯'), isActive: true),
        if (twoPoints) const LoadingPoint(id: 'p2', cityId: 'c2', name: I18nText(kk: 'Алтынколь', ru: 'Алтынколь', zh: '阿拉山口'), isActive: true),
      ],
    );

class _FakeRecentPoints extends RecentPointsStore {
  @override
  Future<List<String>> load() async => const [];

  @override
  Future<void> remember(String pointId) async {}
}

/// Последний груз компании — из него берётся город по умолчанию (040, п.8).
Cargo _lastCargo() => Cargo(
      id: 'cargo-1',
      companyId: 'co',
      companyName: 'Co',
      pointId: 'p1',
      destinationCountryId: 'kz',
      bodyTypeId: 'bt1',
      price: 100,
      currency: Currency.usd,
      readyDate: DateTime.now(),
      status: CargoStatus.published,
      publishedAt: DateTime.now(),
      expiresAt: DateTime.now(),
    );

Future<_FakeArrivalRepository> _pump(WidgetTester tester, {required Size size, double textScale = 1.0, String locale = 'ru', bool twoPoints = false}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final arrivals = _FakeArrivalRepository();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      arrivalRepositoryProvider.overrideWithValue(arrivals),
      myCargosProvider.overrideWith((ref) async => [_lastCargo()]),
      recentPointsStoreProvider.overrideWithValue(_FakeRecentPoints()),
      referenceDataProvider.overrideWith((ref) async => _refData(twoPoints: twoPoints)),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const DriversAtPointScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return arrivals;
}

void main() {
  testWidgets('360 px: нет переполнений, видны заголовок, итоги и карточки', (tester) async {
    final arrivals = await _pump(tester, size: const Size(360, 780));
    final arrivalsCalledWithPoint = arrivals.lastPointId;

    expect(tester.takeException(), isNull);
    expect(find.text('Водители'), findsOneWidget);
    expect(find.text('На месте сейчас · 1'), findsOneWidget);
    expect(find.text('ещё 1 будут сегодня'), findsOneWidget);
    // Город по умолчанию — город последнего груза компании, название — из справочника (040, п.8).
    expect(find.text('Кто свободен: Хоргос'), findsOneWidget);
    expect(arrivalsCalledWithPoint, 'p1');
  });

  testWidgets('крупный шрифт 1.3 на 320 px: нет переполнений', (tester) async {
    await _pump(tester, size: const Size(320, 700), textScale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('«Проверенные» меняет список и перезапрашивает с verifiedOnly', (tester) async {
    final arrivals = await _pump(tester, size: const Size(360, 780));
    expect(find.text('Ерлан С.'), findsOneWidget);
    expect(find.text('Асет Н.'), findsOneWidget);

    // Лента фильтров — вторая горизонтальная прокрутка (первая — полоса дней).
    await tester.scrollUntilVisible(
      find.byKey(const Key('driversFilterVerified')),
      80,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.horizontal).at(1),
    );
    await tester.ensureVisible(find.byKey(const Key('driversFilterVerified')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('driversFilterVerified')));
    await tester.pumpAndSettle();

    expect(arrivals.calls.last, isTrue);
    expect(find.text('Ерлан С.'), findsOneWidget);
    expect(find.text('Асет Н.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('шапка: до списка водителей не больше ~40% высоты 16e (≈ 667 pt)', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    final firstCard = tester.getTopLeft(find.text('На месте сейчас · 1')).dy;
    expect(firstCard / 844, lessThan(0.4));
  });

  testWidgets('040, п.8: «Кто свободен: <город>» — выбор города открывает поиск и перезапрашивает с pointId', (tester) async {
    final arrivals = await _pump(tester, size: const Size(390, 844), twoPoints: true);
    expect(arrivals.lastPointId, 'p1');
    expect(find.byKey(const Key('driversPointChip')), findsOneWidget);
    await tester.tap(find.byKey(const Key('driversPointChip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cityPickerRow-p2')));
    await tester.pumpAndSettle();
    expect(arrivals.lastPointId, 'p2');
    expect(find.text('Кто свободен: Алтынколь'), findsOneWidget);
  });

  testWidgets('п.8: в полосе дней — «Сег», а не «Сегодня»', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(find.text('Сег'), findsOneWidget);
  });

  testWidgets('п.10: «от N т» — шторка тоннажа, «Все» сбрасывает; «Кузов» сбрасывается на «Все»', (tester) async {
    final arrivals = await _pump(tester, size: const Size(390, 844));
    await tester.tap(find.text('Кузов'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тент'));
    await tester.pumpAndSettle();
    expect(arrivals.lastBodyTypeId, 'bt1');
    await tester.tap(find.text('Тент'));
    await tester.pumpAndSettle();
    expect(find.text('Все'), findsOneWidget);
    await tester.tap(find.text('Все'));
    await tester.pumpAndSettle();
    expect(arrivals.lastBodyTypeId, isNull);

    await tester.ensureVisible(find.byKey(const Key('driversFilterCapacity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('driversFilterCapacity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('от 20 т'));
    await tester.pumpAndSettle();
    expect(arrivals.lastMinCapacity, 20);
    expect(find.text('от 20 т'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('driversFilterCapacity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('driversFilterCapacity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все'));
    await tester.pumpAndSettle();
    expect(arrivals.lastMinCapacity, isNull);
  });

  testWidgets('п.10: месяц в календаре — из локали, в том числе en', (tester) async {
    await _pump(tester, size: const Size(390, 844), locale: 'en');
    await tester.tap(find.byIcon(LucideIcons.calendar));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    expect(find.text('${months[now.month - 1]} ${now.year}'), findsOneWidget);
  });

  testWidgets('п.9: статус и кнопки в одной строке, «Проверен» — плашка', (tester) async {
    await _pump(tester, size: const Size(390, 844));
    expect(find.byKey(const Key('driverVerifiedPill-d1')), findsOneWidget);
    final invite = tester.getCenter(find.text('Пригласить').first).dy;
    final status = tester.getCenter(find.textContaining('На месте ·')).dy;
    expect((invite - status).abs(), lessThan(24));
    expect(tester.takeException(), isNull);
  });
}
