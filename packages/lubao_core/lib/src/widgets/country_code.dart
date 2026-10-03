import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Плашка кода страны (KZ, UZ, KG...) — НЕ эмодзи-флаг, только текст на
/// мягком фоне, см. design/DESIGN.md.
class CountryCode extends StatelessWidget {
  const CountryCode({super.key, required this.code, this.label, this.dense = false, this.onDark = false});

  /// ISO alpha-2, например "KZ".
  final String code;

  /// Необязательное название рядом с кодом ("KZ Казахстан").
  final String? label;
  final bool dense;

  /// На синей/тёмной подложке (например, карточка анонса) — полупрозрачный
  /// белый вместо primarySoft, иначе плашка теряется на синем фоне.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? AppSpacing.sm : AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withAlpha(38) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code.toUpperCase(), style: AppTextStyles.small.copyWith(color: fg)),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(label!, style: AppTextStyles.caption.copyWith(color: fg)),
          ],
        ],
      ),
    );
  }
}
