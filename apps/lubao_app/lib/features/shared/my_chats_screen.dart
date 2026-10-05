import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/data_providers.dart';
import 'status_helpers.dart';

/// Вкладка «Чаты» (задача 017, п.1) — общая для водителя и логиста:
/// чат теперь существует до сделки, нужен отдельный список, не только
/// «чат внутри сделки». У логиста это чаты всей компании (см. backend).
class MyChatsScreen extends ConsumerWidget {
  const MyChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentSoft,
                    child: Text(name.isEmpty ? '' : name.substring(0, 1).toUpperCase(), style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accentText)),
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [if (entry.cargoPointName != null) entry.cargoPointName!.forLanguageCode(locale), if (entry.lastMessageText != null) entry.lastMessageText!]
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
