import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lubao_core/lubao_core.dart';

/// Подтверждение опасного действия с обязательной причиной (задача 026,
/// п.16: блокировка/снятие проверки/сброс пароля — всегда через диалог с
/// причиной, не одно случайное касание). `null`, если отменили или причина
/// осталась пустой.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  bool danger = false,
}) async {
  final controller = TextEditingController();
  final t = context.l10n;
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final canConfirm = controller.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(title),
          content: AppTextField(
            label: t.adminReasonLabel,
            controller: controller,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(
              style: danger ? FilledButton.styleFrom(backgroundColor: StatusBadge.danger) : null,
              onPressed: canConfirm ? () => Navigator.pop(dialogContext, controller.text.trim()) : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    ),
  );
  return result;
}

/// Переключение «Проверен» (задача 026, п.5): причина всегда обязательна;
/// при попытке поставить true, когда бэкенд ответит 400 (не все документы
/// одобрены), показываем тот же диалог с чекбоксом «Я проверил документы
/// лично» (force) — не отдельным повторным действием, а дополнением.
Future<({String reason, bool force})?> showVerifyDialog(
  BuildContext context, {
  required bool settingVerified,
  bool offerForce = false,
}) async {
  final controller = TextEditingController();
  var force = false;
  final t = context.l10n;
  return showDialog<({String reason, bool force})>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final canConfirm = controller.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(settingVerified ? t.adminVerifyDialogTitle : t.adminUnverifyDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(label: t.adminReasonLabel, controller: controller, maxLines: 3, onChanged: (_) => setState(() {})),
              if (settingVerified && offerForce) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: force,
                  onChanged: (v) => setState(() => force = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.adminForceVerifyCheckbox),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: canConfirm ? () => Navigator.pop(dialogContext, (reason: controller.text.trim(), force: force)) : null,
              child: Text(t.commonDone),
            ),
          ],
        );
      },
    ),
  );
}

/// Бэкенд отказал в «Подтвердить» 409 `BLACKLIST_MATCH` (задача 032, п.2) —
/// показываем находки явно и спрашиваем отдельное подтверждение, прежде
/// чем повторить вызов с `force: true` (checkbox «проверил лично» из
/// [showVerifyDialog] не годится — он про документы, а не про чёрный
/// список, молча объединять эти два смысла нельзя).
Future<bool> showBlacklistMatchDialog(BuildContext context, List<AdminBlacklistBlock> blocks) async {
  final t = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.adminBlacklistMatchTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.adminBlacklistMatchIntro),
          const SizedBox(height: 8),
          ...blocks.map((b) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${b.type} ${b.valueMasked} · ${b.reason}', style: Theme.of(dialogContext).textTheme.bodySmall),
              )),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: StatusBadge.danger),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t.adminBlacklistMatchOverride),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Причина отклонения документа — пресеты + свободный текст (задача 026,
/// п.13). Выбор пресета заполняет поле, админ может его отредактировать.
Future<String?> showRejectReasonDialog(BuildContext context) async {
  final t = context.l10n;
  final controller = TextEditingController();
  final presets = [
    t.adminRejectPresetUnreadable,
    t.adminRejectPresetExpired,
    t.adminRejectPresetMismatch,
    t.adminRejectPresetPlateMismatch,
  ];

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final canConfirm = controller.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(t.adminRejectReasonLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets
                    .map((p) => ActionChip(
                          label: Text(p),
                          onPressed: () => setState(() {
                            controller.text = p;
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              AppTextField(label: t.adminRejectPresetOther, controller: controller, maxLines: 3, onChanged: (_) => setState(() {})),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: canConfirm ? () => Navigator.pop(dialogContext, controller.text.trim()) : null,
              child: Text(t.adminReject),
            ),
          ],
        );
      },
    ),
  );
}

void copyToClipboardWithToast(BuildContext context, String value, String toastMessage) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(toastMessage)));
}
