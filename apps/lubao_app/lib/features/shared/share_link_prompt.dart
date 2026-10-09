import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/share_links.dart';

/// 057 п.8 (iOS): «Пришли по ссылке? Открыть груз» — один раз после первого
/// входа; буфер читается только по нажатию (без системного запроса на каждом входе).
class ShareLinkPrompt extends ConsumerWidget {
  const ShareLinkPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(shareLinkHandlerProvider);
    final t = context.l10n;
    return ValueListenableBuilder<bool>(
      valueListenable: handler.prompt,
      builder: (context, show, _) => !show
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 0),
              child: AppCard(
                key: const Key('shareLinkPrompt'),
                borderColor: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(LucideIcons.link, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(t.shareLinkPromptText, style: AppTextStyles.bodyStrong)),
                    TextButton(
                      key: const Key('shareLinkPromptOpen'),
                      onPressed: () async {
                        final ok = await handler.openFromClipboard();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.shareLinkPromptNotFound)));
                        }
                      },
                      child: Text(t.shareLinkPromptOpen),
                    ),
                    IconButton(key: const Key('shareLinkPromptClose'), icon: const Icon(LucideIcons.x, size: 18), onPressed: handler.dismissPrompt),
                  ],
                ),
              ),
            ),
    );
  }
}
