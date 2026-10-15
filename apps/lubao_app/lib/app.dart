import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import 'providers/api_providers.dart';
import 'providers/locale_provider.dart';
import 'router/app_router.dart';
import 'services/location_reporter.dart';
import 'services/realtime_connector.dart';
import 'services/push_service.dart';
import 'services/share_links.dart';
import 'services/stale_refresh.dart';
import 'services/connection_watcher.dart';

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
    // 061 п.10: после фона и переподключения — тихое обновление списков.
    ref.watch(staleRefreshWatcherProvider);
    // 078: связь проверяется в фоне — полоса «Нет связи» и без действий на экране.
    ref.watch(connectionWatcherProvider);
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
      // 078: без связи — тонкая полоса сверху, экраны показывают сохранённое.
      builder: (context, child) => _OfflineBar(offline: ref.watch(apiClientProvider).offline, child: child ?? const SizedBox()),
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar({required this.offline, required this.child});

  final ValueListenable<bool> offline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: offline,
      builder: (context, isOffline, child) {
        final media = MediaQuery.of(context);
        // Структура не меняется (всегда Column, содержимое под постоянным
        // ключом) — навигатор и экраны не пересоздаются, когда пропала связь.
        return Column(
          children: [
            if (isOffline)
              Material(
                key: const Key('offlineBanner'),
                color: AppColors.textSecondary,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.md, media.padding.top + 4, AppSpacing.md, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(context.l10n.offlineBanner, style: AppTextStyles.caption.copyWith(color: Colors.white), maxLines: 2),
                      ),
                    ],
                  ),
                ),
              ),
            // Полоса заняла место под статус-баром — экрану отступ сверху не нужен.
            Expanded(
              key: const ValueKey('appContent'),
              child: MediaQuery.removePadding(context: context, removeTop: isOffline, child: child!),
            ),
          ],
        );
      },
      child: child,
    );
  }
}
