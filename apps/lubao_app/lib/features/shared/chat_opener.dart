import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../services/local_data.dart';
import 'chat_screen.dart';

/// 078 п.1: кому пишем — водитель (логисту) и/или груз.
class ChatTarget {
  const ChatTarget({this.driverId, this.cargoId, required this.title});

  final String? driverId;
  final String? cargoId;

  /// Имя собеседника — в шапке сразу, до ответа сервера.
  final String title;
}

/// «Написать»: экран чата открывается сразу; тред — в фоне (или из
/// запомненной связи «водитель/груз → чат» — без запроса).
void openChat(BuildContext context, ChatTarget target) => context.push('/chat/open', extra: target);

class ChatOpeningScreen extends ConsumerStatefulWidget {
  const ChatOpeningScreen({super.key, required this.target});

  final ChatTarget target;

  @override
  ConsumerState<ChatOpeningScreen> createState() => _ChatOpeningScreenState();
}

class _ChatOpeningScreenState extends ConsumerState<ChatOpeningScreen> {
  String? _chatId;
  Object? _error;
  final _controller = TextEditingController();

  /// Написанное до того, как тред нашёлся, — уйдёт из чата очередью.
  final _queued = <OutgoingMessage>[];

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final local = ref.read(localDataProvider);
    final target = widget.target;
    try {
      var chatId = await local.chatFor(driverId: target.driverId, cargoId: target.cargoId);
      if (chatId == null) {
        final thread = await ref.read(chatRepositoryProvider).findOrCreate(driverId: target.driverId, cargoId: target.cargoId);
        chatId = thread.id;
        await local.rememberChat(chatId, driverId: target.driverId, cargoId: target.cargoId);
      }
      // Написанное до этого момента передаётся чату целиком при переходе (build),
      // — не здесь: между проверкой и переходом могли отправить ещё.
      if (mounted) setState(() => _chatId = chatId);
    } catch (e) {
      debugPrint('ChatOpeningScreen: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  void _queue() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _queued.add(OutgoingMessage(localId: '${DateTime.now().microsecondsSinceEpoch}', text: text, createdAt: DateTime.now())));
  }

  @override
  Widget build(BuildContext context) {
    final chatId = _chatId;
    if (chatId != null) {
      return ChatScreen(key: ValueKey(chatId), chatId: chatId, initialText: _controller.text, initialOutbox: List.of(_queued));
    }
    final t = context.l10n;
    return Scaffold(
      key: const Key('chatOpening'),
      appBar: AppBar(title: Text(widget.target.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? ErrorView(
                    message: t.chatOpenFailed,
                    onRetry: () {
                      setState(() => _error = null);
                      unawaited(_resolve());
                    },
                  )
                : ListView(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    children: [
                      for (final m in _queued.reversed)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Opacity(opacity: 0.7, child: ChatBubble(text: m.text, isMine: true)),
                                Text(t.chatPendingSend, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ),
                      Center(child: Text(t.chatOpening, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
                    ],
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(key: const Key('chatMessageInput'), label: '', hintText: t.chatInputHint, controller: _controller),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconSquareButton(key: const Key('chatSendButton'), icon: LucideIcons.send, onPressed: _queue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
