import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Плитка выбора (страна, тип кузова, допуск...). Выбрана: рамка 2px primary
/// + фон primarySoft — см. design/DESIGN.md.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyStrong.copyWith(color: selected ? AppColors.primary : AppColors.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
