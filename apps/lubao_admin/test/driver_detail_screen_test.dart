import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/drivers/driver_detail_screen.dart';
import 'package:lubao_admin/providers/data_providers.dart';
import 'package:lubao_admin/providers/locale_provider.dart';

/// Живая проверка в браузере нашла `BoxConstraints forces an infinite
/// width` при открытии карточки водителя: в заголовочном Row бок о бок с
/// Expanded(Column) стояли голые OutlinedButton — та же причина, что уже
/// чинили в complaints_screen.dart (задача 030). Этот тест ловит ровно тот
/// баг: настоящий рендер заголовка, не заглушка.
AdminDriverDetail _driver({bool isBlocked = false}) => AdminDriverDetail(
      id: 'd1',
      fullName: 'Ерлан Тохтаров',
      isVerified: true,
      userId: 'u1',
      phone: '+77011234501',
      locale: 'ru',
      registeredAt: DateTime(2026, 9, 1),
      isBlocked: isBlocked,
      lastLoginAt: DateTime(2026, 10, 1),
      homeCityId: 'city-1',
      homeCityName: const I18nText(kk: 'Алматы', ru: 'Алматы', zh: '阿拉木图'),
      anyCountry: true,
      directionNames: const [],
      directionCountryIds: const [],
      permitNames: const [],
      permitIds: const [],
      vehicles: const [],
      documents: const [],
      stats: const AdminDriverStats(
        dealsByStatus: {},
        cancellations: 0,
        ratingAvg: 0,
        ratingCount: 0,
        reviews: [],
        calls: 0,
        whatsapp: 0,
        complaintsAgainst: 0,
        complaintsBy: 0,
      ),
      deals: const [],
      sessions: const [],
      auditLog: const [],
    );

Future<void> _pump(WidgetTester tester, {bool isBlocked = false}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      adminDriverDetailProvider('d1').overrideWith((ref) async => _driver(isBlocked: isBlocked)),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const DriverDetailScreen(id: 'd1'),
    ),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('an unblocked driver renders the header (avatar, Edit, Block) without a layout exception', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ерлан Тохтаров'), findsOneWidget);
    expect(find.text('Редактировать'), findsOneWidget);
    expect(find.text('Блокировать'), findsOneWidget);
  });

  testWidgets('a blocked driver renders the header (Unblock button) without a layout exception', (tester) async {
    await _pump(tester, isBlocked: true);

    expect(tester.takeException(), isNull);
    expect(find.text('Разблокировать'), findsOneWidget);
  });

  testWidgets('renders correctly at a 390px mobile width too', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ерлан Тохтаров'), findsOneWidget);
  });
}
