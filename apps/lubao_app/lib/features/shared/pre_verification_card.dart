import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 058 п.9: до проверки — одна карточка «можно / нельзя / откроется после
/// проверки» по фактическим правилам (без новых запретов).
class PreVerificationCard extends StatelessWidget {
  const PreVerificationCard({super.key, required this.title, required this.can, required this.cannot, required this.after});

  /// Водитель / компания.
  factory PreVerificationCard.driver(LubaoLocalizations t, {Key? key}) =>
      PreVerificationCard(key: key, title: t.preVerifyTitle, can: t.preVerifyDriverCan, cannot: t.preVerifyDriverCannot, after: t.preVerifyDriverAfter);

  factory PreVerificationCard.company(LubaoLocalizations t, {Key? key, String? title}) =>
      PreVerificationCard(key: key, title: title ?? t.preVerifyTitle, can: t.preVerifyCompanyCan, cannot: t.preVerifyCompanyCannot, after: t.preVerifyCompanyAfter);

  final String title;
  final String can;
  final String cannot;
  final String after;

  @override
  Widget build(BuildContext context) {
    Widget line(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(text, style: AppTextStyles.body)),
            ],
          ),
        );
    return AppCard(
      color: AppColors.primarySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          line(LucideIcons.checkCircle2, AppColors.success, can),
          line(LucideIcons.xCircle, AppColors.error, cannot),
          line(LucideIcons.clock, AppColors.accentText, after),
        ],
      ),
    );
  }
}
