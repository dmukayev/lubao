import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'providers/locale_provider.dart';
import 'router/app_router.dart';
import 'services/location_reporter.dart';
import 'services/realtime_connector.dart';
import 'services/push_service.dart';
import 'services/share_links.dart';

class LubaoApp extends ConsumerWidget {
  const LubaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Геопозиция (041, п.8): LocationReporter шлёт координаты ТОЛЬКО при
    // активной сделке «Загружен»/«В пути» и уже выданном разрешении;
    // разрешение просят с объяснением по «📍» в чате.
    ref.watch(realtimeConnectorProvider);
    // 052: ссылки «Поделиться» — после входа открыть нужный экран.
    ref.watch(shareLinkHandlerProvider);
    ref.watch(locationReporterProvider);
    // Push (042 п.1) — только при сборке с PUSH_ENABLED, иначе ничего не делает.
    ref.watch(pushServiceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
