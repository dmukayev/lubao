import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';
import 'driver_avatar.dart';

/// Вкладка «Чаты» (задача 017, п.1) — общая для водителя и логиста:
/// чат теперь существует до сделки, нужен отдельный список, не только
/// «чат внутри сделки». У логиста это чаты всей компании (см. backend).
/// Список обновляется по `chat:updated` (задача 029, п.3) — этот экран
/// не состоит в комнатах конкретных чатов (`chat:<id>`), поэтому
/// `message:new` до него никогда не долетит; `chat:updated` сервер шлёт
/// в личную комнату пользователя независимо от того, какие чаты открыты.
/// Плюс фоллбэк на опрос раз в 10с и рефетч при каждом (пере)подключении
/// сокета (onReconnected) — на случай пропущенных во время обрыва событий.
class MyChatsScreen extends ConsumerStatefulWidget {
  const MyChatsScreen({super.key});

  @override
  ConsumerState<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends ConsumerState<MyChatsScreen> {
  StreamSubscription<Map<String, dynamic>>? _chatUpdatedSub;
  StreamSubscription<void>? _reconnectedSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final realtime = ref.read(realtimeServiceProvider);
    _chatUpdatedSub = realtime.onChatUpdated.listen((_) => ref.invalidate(myChatsProvider));
    _reconnectedSub = realtime.onReconnected.listen((_) => ref.invalidate(myChatsProvider));
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!realtime.isConnected) ref.invalidate(myChatsProvider);
    });
  }

  @override
  void dispose() {
    _chatUpdatedSub?.cancel();
    _reconnectedSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final chats = ref.watch(myChatsProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(t.chatsTabTitle)),
      body: chats.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('MyChatsScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(myChatsProvider));
        },
        data: (list) {
          if (list.isEmpty) return EmptyState(message: t.chatsEmpty, icon: LucideIcons.messageCircle);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myChatsProvider),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = list[index];
                final name = entry.thread.counterpartName;
                return ListTile(
                  key: Key('chatListEntry-${entry.thread.id}'),
                  // 054: логист видит фото водителя; у водителя версия всегда null — буква.
                  leading: DriverAvatar(
                    driverId: entry.thread.driverId,
                    name: name,
                    version: entry.thread.counterpartAvatarVersion,
                    radius: 20,
                    fallback: CircleAvatar(
                      backgroundColor: AppColors.accentSoft,
                      child: Text(name.isEmpty ? '' : name.substring(0, 1).toUpperCase(), style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accentText)),
                    ),
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [if (entry.cargoPointName != null) entry.cargoPointName!.forLanguageCode(locale), if (entry.lastMessageText != null) systemMessageText(t, entry.lastMessageSystemCode, entry.lastMessageSystemParams, entry.lastMessageText!)]
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatDate(entry.lastMessageAt), style: AppTextStyles.caption),
                      if (entry.unreadCount > 0) ...[
                        const SizedBox(height: 4),
                        CircleAvatar(radius: 10, backgroundColor: AppColors.primary, child: Text('${entry.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/chat/${entry.thread.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
