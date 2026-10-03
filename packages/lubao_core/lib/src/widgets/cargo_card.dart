import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'status_badge.dart';

class CargoCard extends StatelessWidget {
  const CargoCard({
    super.key,
    required this.destinationLabel,
    required this.bodyTypeLabel,
    required this.priceLabel,
    required this.readyDateLabel,
    required this.statusLabel,
    required this.statusColor,
    this.onTap,
    this.trailing,
    this.badge,
    this.accentBorder = false,
    this.secondaryPriceLabel,
  });

  final String destinationLabel;
  final String bodyTypeLabel;
  final String priceLabel;
  final String readyDateLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Пересчёт цены в ₸ мелким шрифтом под ценой (см. design/DESIGN.md:
  /// "Цена всегда в валюте груза + пересчёт мелким шрифтом").
  final String? secondaryPriceLabel;

  /// Плашка слева сверху — "Домой" или код страны (CountryCode).
  final Widget? badge;

  /// Рамка accent — карточка "Домой" в ленте.
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: accentBorder ? AppColors.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badge != null) ...[badge!, const Spacer()] else const Spacer(),
              Text(readyDateLabel, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(destinationLabel, style: AppTextStyles.route)),
              StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(bodyTypeLabel, style: AppTextStyles.caption)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(priceLabel, style: AppTextStyles.priceCard),
                  if (secondaryPriceLabel != null)
                    Text(secondaryPriceLabel!, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          if (trailing != null) ...[const SizedBox(height: AppSpacing.sm), trailing!],
        ],
      ),
    );
  }
}
