// 060 п.5: замер скорости (profile/release): время до первой ленты, прокрутка
// ленты из 200 грузов и переключение вкладок — кадры дольше 16 мс.
// Запуск: scripts/perf.sh (подставляет 200 грузов в e2e-базу).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('060: скорость — первая лента, прокрутка 200 грузов, вкладки', (tester) async {
    // flutter drive: ввод текста робота, а не системная клавиатура эмулятора.
    tester.testTextInput.register();
    await clearPersistedSession();
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    await loginDriver(tester, '7010000002');
    await waitFor(tester, find.byKey(const Key('driverStatusBar')), timeout: const Duration(seconds: 40));

    // Время до первой ленты при запуске с уже сохранённым входом.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final sw = Stopwatch()..start();
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    final firstCard = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('feedCargoCard-'));
    await waitFor(tester, firstCard, timeout: const Duration(seconds: 40));
    final feedReadyMs = sw.elapsedMilliseconds;

    final feedList = find.byType(Scrollable).first;
    await binding.watchPerformance(() async {
      for (var i = 0; i < 12; i++) {
        await tester.fling(feedList, const Offset(0, -900), 2500);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 6; i++) {
        await tester.fling(feedList, const Offset(0, 900), 2500);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'feed_scroll');

    await binding.watchPerformance(() async {
      for (var round = 0; round < 3; round++) {
        for (final tab in [t.navTrips, t.navChats, t.profileTitle, t.navFeed]) {
          await goTab(tester, tab);
          await tester.pump(const Duration(milliseconds: 300));
        }
      }
    }, reportKey: 'tab_switch');

    binding.reportData = {...?binding.reportData, 'feed_ready_ms': feedReadyMs};
  });
}
