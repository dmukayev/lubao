import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'responsive.dart';

/// Общий паттерн редактирования карточки (задача 028, п.18): кнопка
/// «Редактировать» → боковая панель справа поверх карточки, внизу —
/// обязательная причина и «Сохранить». Возвращает причину; сами значения
/// полей читает вызывающая сторона из своих локальных переменных —
/// `fieldsBuilder` получает тот же `setState`, что и панель, так что любое
/// изменение в полях сразу переоценивает `canSave`.
Future<String?> showEditSidePanel({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, StateSetter setState) fieldsBuilder,
  bool Function()? canSave,
}) {
  final reasonController = TextEditingController();
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final t = context.l10n;
      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: Material(
            elevation: 8,
            child: SizedBox(
              // Задача 030, п.7 — на телефоне панель редактирования на
              // весь экран (фиксированные 440px были шире самого экрана
              // на 360px и обрезались за правым краем), на компьютере —
              // боковая панель, как раньше.
              width: isMobileWidth(context) ? MediaQuery.sizeOf(context).width : 440,
              height: double.infinity,
              child: SafeArea(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final reasonOk = reasonController.text.trim().isNotEmpty;
                    final fieldsOk = canSave?.call() ?? true;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                          child: Row(
                            children: [
                              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: fieldsBuilder(context, setState),
                          ),
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                label: t.adminReasonLabel,
                                controller: reasonController,
                                maxLines: 2,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: reasonOk && fieldsOk ? () => Navigator.pop(context, reasonController.text.trim()) : null,
                                      child: Text(t.commonSave),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
