import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_admin/features/dashboard/dashboard_screen.dart';
import 'package:lubao_admin/providers/api_providers.dart';
import 'package:lubao_admin/providers/data_providers.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository() : super(ApiClient(baseUrl: 'http://localhost:1'));
  final dismissed = <String>[];

  @override
  Future<void> dismissSuspiciousContacts(String userId) async => dismissed.add(userId);
}

/// 043 п.11: «Похоже на парсинг» в «Требует внимания» — строка с числом
/// открытых номеров, «Всё в порядке» прячет аккаунт.
void main() {
  testWidgets('строка «Похоже на парсинг» и «Всё в порядке»', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _FakeAdminRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repo),
        adminStatsProvider.overrideWith((ref) => Future.error('нет в тесте')),
        adminRecentEventsProvider.overrideWith((ref) => Future.error('нет в тесте')),
        adminCityStatsProvider.overrideWith((ref) => Future.error('нет в тесте')),
        adminAttentionProvider.overrideWith((ref) async => const AdminAttention(
              pendingVerificationCount: 0,
              pendingVerificationOldestAgeHours: 0,
              openComplaints: 0,
              staleDeals: 0,
              unverifiedCompanies: 0,
              pendingCities: 0,
              suspiciousContacts: [
                AdminSuspiciousContact(userId: 'u1', role: 'DRIVER', name: 'Парсер Тестов', driverId: 'd1', opens24h: 25, limitHits24h: 3),
              ],
            )),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('kk'), Locale('zh'), Locale('en')],
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        theme: AppTheme.light(),
        home: const DashboardScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    final t = tester.element(find.byType(DashboardScreen)).l10n;
    expect(find.text(t.adminSuspiciousTitle('Парсер Тестов', 25)), findsOneWidget);
    expect(find.text(t.adminSuspiciousLimitHits(3)), findsOneWidget);
    await tester.ensureVisible(find.text(t.adminSuspiciousOk));
    await tester.tap(find.text(t.adminSuspiciousOk));
    await tester.pumpAndSettle();
    expect(repo.dismissed, ['u1']);
    expect(tester.takeException(), isNull);
  });
}
