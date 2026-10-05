import 'package:flutter/material.dart';
import '../l10n/context_extension.dart';
import '../theme/app_theme.dart';
import 'linkified_text.dart';

/// Пузырь сообщения в чате: входящее — белое, исходящее — primary.
/// Если сообщение переведено, под пузырём — строка «Переведено · оригинал»,
/// по тапу на «оригинал» разворачивается исходный текст.
class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.isTranslated = false,
    this.originalText,
    this.isTranslationFailed = false,
    this.onRetryTranslation,
  });

  final String text;
  final bool isMine;
  final bool isTranslated;
  final String? originalText;
  /// Перевод не удался (задача 010, п.7) — показываем оригинал и
  /// «Перевод недоступен · повторить» вместо значка «Переведено».
  final bool isTranslationFailed;
  final VoidCallback? onRetryTranslation;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bg = widget.isMine ? AppColors.primary : AppColors.surface;
    final fg = widget.isMine ? Colors.white : AppColors.text;
    final showOriginalNow = widget.isTranslated && _showOriginal && widget.originalText != null;

    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: widget.isMine ? null : Border.all(color: AppColors.divider),
            ),
            child: LinkifiedText(
              showOriginalNow ? widget.originalText! : widget.text,
              style: AppTextStyles.body.copyWith(color: fg),
            ),
          ),
          if (widget.isTranslationFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: widget.onRetryTranslation,
                child: Text(
                  '${t.chatTranslationFailed} · ${t.chatTranslationRetry}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
            )
          else if (widget.isTranslated && widget.originalText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _showOriginal = !_showOriginal),
                child: Text(
                  '${t.chatTranslatedBadge} · ${t.chatShowOriginal}',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
