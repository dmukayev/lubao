import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Чип быстрого ответа в чате ("Да, договорились", "Перезвоню позже"...).
class QuickReplyChip extends StatelessWidget {
  const QuickReplyChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Text(label, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary)),
        ),
      ),
    );
  }
}
