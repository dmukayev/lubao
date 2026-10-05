import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import '../shared/admin_status_helpers.dart';

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

  return showDialog<ComplaintResolveResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final t = dialogContext.l10n;
        final canConfirm = noteController.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(t.adminComplaintResolutionTitle),
          content: SizedBox(
            width: 420,
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
                  AppTextField(label: t.adminComplaintResolutionNoteLabel, controller: noteController, maxLines: 3, onChanged: (_) => setState(() {})),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
            FilledButton(
              onPressed: canConfirm ? () => Navigator.pop(dialogContext, ComplaintResolveResult(resolution: resolution, resolutionNote: noteController.text.trim())) : null,
              child: Text(t.commonSave),
            ),
          ],
        );
      },
    ),
  );
}
