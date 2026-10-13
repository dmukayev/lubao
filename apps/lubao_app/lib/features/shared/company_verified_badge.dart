import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 066 (decisions.md «Компания публикует грузы без проверки»): у названия
/// компании — «Проверена» с зелёной галочкой, у непроверенной — серое
/// «Не проверена», мелко. Предупреждений нет — водитель решает сам.
class CompanyVerifiedBadge extends StatelessWidget {
  const CompanyVerifiedBadge({super.key, required this.isVerified, this.keySuffix = ''});

  final bool isVerified;

  /// Для e2e: `companyVerifiedBadge-<suffix>` / `companyUnverifiedBadge-<suffix>`.
  final String keySuffix;

  /// Плашка внутри строки текста (лента, «Мои рейсы»).
  static InlineSpan span({required bool isVerified, String keySuffix = ''}) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: CompanyVerifiedBadge(isVerified: isVerified, keySuffix: keySuffix),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final suffix = keySuffix.isEmpty ? '' : '-$keySuffix';
    if (!isVerified) {
      return Text(
        t.companyBadgeUnverified,
        key: Key('companyUnverifiedBadge$suffix'),
        style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
      );
    }
    return Row(
      key: Key('companyVerifiedBadge$suffix'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.success),
        const SizedBox(width: 2),
        Text(t.companyBadgeVerified, style: AppTextStyles.small.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
