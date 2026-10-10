import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/api_providers.dart';
import 'error_feedback.dart';
import 'web_share_support_stub.dart' if (dart.library.js_interop) 'web_share_support_web.dart';

/// Подмена системного меню в сквозных сценариях: робот не нажмёт кнопки
/// share sheet, тест получает текст, который ушёл бы в мессенджер.
@visibleForTesting
Future<void> Function(String text)? debugShareOverride;

/// 052 п.4–5: «Поделиться». Телефон (и браузер телефона) — сразу системное
/// меню (`share_plus`): своих кнопок мессенджеров нет. Браузер ПК — своё меню:
/// текст правится, «Копировать текст», WhatsApp, Telegram, WeChat (QR), «Ссылка».
Future<void> shareContent(
  BuildContext context,
  WidgetRef ref, {
  required ShareKind kind,
  required String targetId,
  required String dialogTitle,
  required String Function(String url) buildText,
}) async {
  String url;
  try {
    url = await ref.read(shareRepositoryProvider).link(kind, targetId);
  } catch (e) {
    if (context.mounted) showApiError(context, e);
    return;
  }
  final text = buildText(url);
  final override = debugShareOverride;
  if (override != null) return override(text);
  if (!context.mounted) return;
  final desktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 700;
  // 057 п.10: браузер телефона без Web Share — сразу своё меню, не mailto:.
  if (!desktopWeb && browserCanShare()) {
    // 057 п.9: на iPad системное меню привязывается к кнопке.
    // Контекст может принадлежать списку (RenderSliverList, не RenderBox) —
    // приведение `as RenderBox?` падало, и «Поделиться» в карточке груза
    // ничего не делало. Нет прямоугольника — системное меню без привязки.
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    final origin = box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
      if (result.status != ShareResultStatus.unavailable) return;
    } catch (_) {
      // Нет системного меню — своё.
    }
  }
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (_) => _WebShareDialog(title: dialogTitle, text: text, url: url));
}

class _WebShareDialog extends StatefulWidget {
  const _WebShareDialog({required this.title, required this.text, required this.url});

  final String title;
  final String text;
  final String url;

  @override
  State<_WebShareDialog> createState() => _WebShareDialogState();
}

class _WebShareDialogState extends State<_WebShareDialog> {
  late final _controller = TextEditingController(text: widget.text);
  bool _qr = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy(String value, String done) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }

  Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final wechat = OutlinedButton.icon(
      key: const Key('shareWeChat'),
      icon: const Icon(LucideIcons.qrCode, size: 18),
      label: Text(t.shareWeChatQr),
      onPressed: () async {
        // WeChat на ПК не принимает ссылку «поделиться»: QR для телефона,
        // а текст — сразу в буфер, вставить в чат.
        await Clipboard.setData(ClipboardData(text: _controller.text));
        setState(() => _qr = true);
      },
    );
    final whatsapp = OutlinedButton(
      key: const Key('shareWhatsApp'),
      onPressed: () => _open(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_controller.text)}')),
      child: const Text('WhatsApp'),
    );
    final telegram = OutlinedButton(
      key: const Key('shareTelegram'),
      onPressed: () => _open(Uri.parse('https://t.me/share/url?url=${Uri.encodeComponent(widget.url)}&text=${Uri.encodeComponent(_controller.text.replaceAll(widget.url, '').trim())}')),
      child: const Text('Telegram'),
    );
    final link = OutlinedButton.icon(
      key: const Key('shareCopyLink'),
      icon: const Icon(LucideIcons.link, size: 18),
      label: Text(t.shareLinkButton),
      onPressed: () => _copy(widget.url, t.shareLinkCopied),
    );
    return AlertDialog(
      key: const Key('webShareDialog'),
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(key: const Key('shareText'), controller: _controller, maxLines: null, minLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
              const SizedBox(height: AppSpacing.xs),
              Text(t.shareEditHint, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    key: const Key('shareCopyText'),
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: Text(t.shareCopyText),
                    onPressed: () => _copy(_controller.text, t.shareTextCopied),
                  ),
                  // 052 п.5: китайский интерфейс — WeChat первым.
                  if (zh) wechat,
                  whatsapp,
                  telegram,
                  if (!zh) wechat,
                  link,
                ],
              ),
              if (_qr) ...[
                const SizedBox(height: AppSpacing.md),
                Center(child: QrImageView(key: const Key('shareQr'), data: widget.url, size: 180, backgroundColor: Colors.white)),
                Text(t.shareWeChatHint, textAlign: TextAlign.center, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonDone))],
    );
  }
}
