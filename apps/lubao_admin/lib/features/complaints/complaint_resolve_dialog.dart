import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/admin_status_helpers.dart';
import '../shared/responsive.dart';

class ComplaintResolveResult {
  const ComplaintResolveResult({required this.resolution, required this.resolutionNote});

  final String resolution;
  final String resolutionNote;
}

/// Решение по жалобе (задача 028, п.24d) — один из 4 вариантов; «Снять
/// груз» показывается только для CARGO/DEAL, остальные — для любого типа.
/// Ответ автору обязателен всегда.
Future<ComplaintResolveResult?> showComplaintResolveDialog(BuildContext context, {required String targetType}) {
  final options = ['DISMISSED', 'WARNED', if (targetType == 'CARGO' || targetType == 'DEAL') 'CARGO_UNPUBLISHED', 'BLOCKED'];
  String resolution = options.first;
  final noteController = TextEditingController();
  // «Сохранить» всегда нажимается: пустой ответ — причина под полем
  // (раньше кнопка была серой без объяснения — «не нажимается»).
  var noteMissing = false;

  return showDialog<ComplaintResolveResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final t = dialogContext.l10n;
        return AlertDialog(
          title: Text(t.adminComplaintResolutionTitle),
          content: SizedBox(
            // Задача 030, п.10 — фиксированные 420px клипались на экране
            // 360px (AlertDialog.insetPadding оставляет ~280px): на
            // телефоне ширина содержимого подстраивается под диалог,
            // не наоборот.
            width: isMobileWidth(dialogContext) ? double.infinity : 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final o in options)
                    RadioListTile<String>(
                      value: o,
                      groupValue: resolution,
                      title: Text(complaintResolutionLabel(t, o)),
                      onChanged: (v) => setState(() => resolution = v!),
                    ),
                  const SizedBox(height: 8),
                  AppTextField(
                    key: const Key('complaintResolutionNote'),
                    label: t.adminComplaintResolutionNoteLabel,
                    controller: noteController,
                    maxLines: 3,
                    errorText: noteMissing ? t.adminComplaintNoteRequired : null,
                    onChanged: (_) => setState(() => noteMissing = false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(
              key: const Key('complaintResolveSave'),
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) return setState(() => noteMissing = true);
                Navigator.pop(dialogContext, ComplaintResolveResult(resolution: resolution, resolutionNote: note));
              },
              child: Text(t.commonSave),
            ),
          ],
        );
      },
    ),
  );
}
