import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'providers/locale_provider.dart';
import 'router/app_router.dart';
import 'services/realtime_connector.dart';

class LubaoApp extends ConsumerWidget {
  const LubaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Задача 032, п.14 — фоновая отправка координат выключена до задачи
    // 008 (согласие, геолокация только логисту активной сделки во время
    // рейса): LocationReporter слал координаты каждые 45с ЛЮБОГО вошедшего
    // водителя без согласия и без сделки. Геопозиция теперь запрашивается
    // только по нажатию «📍» в чате (chat_screen.dart#_sendMyLocation) и
    // никуда не отправляется на сервер — только в ссылку на карту.
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
