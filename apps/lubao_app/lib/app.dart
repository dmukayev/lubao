import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'providers/locale_provider.dart';
import 'router/app_router.dart';
import 'services/location_reporter.dart';
import 'services/realtime_connector.dart';

class LubaoApp extends ConsumerWidget {
  const LubaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    ref.watch(locationReporterProvider);
    ref.watch(realtimeConnectorProvider);

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
