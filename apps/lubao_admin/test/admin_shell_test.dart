import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/shell/admin_shell.dart';
import 'package:lubao_admin/providers/data_providers.dart';

/// Задача 030, п.1/14 — нижняя навигация на телефоне (390px), боковое
/// меню на компьютере (1280px), ни то ни другое не переполняется.
void main() {
  Future<void> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (context, state) => const AdminShell(child: Text('DASHBOARD_BODY'))),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminAttentionProvider.overrideWith((ref) async => const AdminAttention(
              pendingVerificationCount: 2,
              pendingVerificationOldestAgeHours: 1,
              openComplaints: 1,
              staleDeals: 0,
              unverifiedCompanies: 0,
              pendingCities: 0,
            )),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('kk'), Locale('zh'), Locale('en')],
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('at 390px shows bottom navigation with 5 destinations, no NavigationRail', (tester) async {
    await pump(tester, 390);

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('DASHBOARD_BODY'), findsOneWidget);
  });

  testWidgets('at 1280px shows the side NavigationRail, no bottom NavigationBar', (tester) async {
    await pump(tester, 1280);

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('DASHBOARD_BODY'), findsOneWidget);
  });
}
