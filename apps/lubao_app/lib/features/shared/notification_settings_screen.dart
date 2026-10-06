import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';

final notificationEventSettingsProvider = FutureProvider.autoDispose<List<NotificationEventSetting>>((ref) {
  return ref.watch(notificationsRepositoryProvider).eventSettings();
});

String _groupLabel(BuildContext context, NotificationEventGroup group) {
  final t = context.l10n;
  switch (group) {
    case NotificationEventGroup.newCargoMatch:
      return t.notificationGroupNewCargoMatch;
    case NotificationEventGroup.cargoInvite:
      return t.notificationGroupCargoInvite;
    case NotificationEventGroup.chatMessage:
      return t.notificationGroupChatMessage;
    case NotificationEventGroup.newResponse:
      return t.notificationGroupNewResponse;
    case NotificationEventGroup.newDriverDigest:
      return t.notificationGroupNewDriverDigest;
    case NotificationEventGroup.dealStatus:
      return t.notificationGroupDealStatus;
    case NotificationEventGroup.verification:
      return t.notificationGroupVerification;
    case NotificationEventGroup.agreedCheck:
      return t.notificationGroupAgreedCheck;
    case NotificationEventGroup.arrivalCheck:
      return t.notificationGroupArrivalCheck;
  }
}

/// Вкл/выкл по группе событий (задача 011, п.4), общий экран для водителя
/// и логиста — список групп одинаковый на бэкенде, различий по роли нет.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _toggle(WidgetRef ref, NotificationEventGroup group, bool enabled) async {
    // Оптимистично не трогаем локальный список — просто ждём ответа и
    // перезапрашиваем; экран маленький, задержка не ощущается, а код
    // проще, чем держать локальную копию списка в синхроне с сервером.
    await ref.read(notificationsRepositoryProvider).setEventSetting(group, enabled);
    ref.invalidate(notificationEventSettingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final settings = ref.watch(notificationEventSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.notificationSettingsTitle)),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('NotificationSettingsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(notificationEventSettingsProvider));
        },
        data: (list) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Text(t.notificationSettingsHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ),
            ...list.map((setting) => SwitchListTile(
                  title: Text(_groupLabel(context, setting.eventGroup)),
                  value: setting.enabled,
                  onChanged: (value) => _toggle(ref, setting.eventGroup, value),
                )),
          ],
        ),
      ),
    );
  }
}
