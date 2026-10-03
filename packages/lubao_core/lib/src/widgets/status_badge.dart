import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Пилюля статуса ("StatusPill" из design/DESIGN.md). Принимает готовый цвет
/// (одну из статических констант ниже) и сама подбирает к нему точный
/// парный фон-токен из палитры — так вызывающему коду не нужно знать пары
/// текст/фон, достаточно передать один семантический цвет.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  static const Color neutral = AppColors.neutral;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color danger = AppColors.danger;
  static const Color info = AppColors.primary;

  Color get _background => switch (color) {
        AppColors.success => AppColors.successSoft,
        AppColors.primary => AppColors.primarySoft,
        AppColors.textSecondary => AppColors.divider,
        AppColors.accentText => AppColors.accentSoft,
        AppColors.error => AppColors.errorSoft,
        _ => color.withAlpha(30),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppTextStyles.small.copyWith(color: color)),
    );
  }
}
