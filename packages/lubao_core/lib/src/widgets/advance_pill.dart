import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

/// 063, эталон 34: аванс — отдельной зелёной плашкой внизу карточки груза.
class AdvancePill extends StatelessWidget {
  const AdvancePill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.banknote, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(label, style: AppTextStyles.small.copyWith(color: AppColors.success, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
