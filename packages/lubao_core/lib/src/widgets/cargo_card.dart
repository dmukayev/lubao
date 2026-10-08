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
    this.statusLabel,
    this.statusColor = StatusBadge.neutral,
    this.onTap,
    this.trailing,
    this.badge,
    this.accentBorder = false,
    this.secondaryPriceLabel,
    this.originLabel,
    this.partialLabel,
  });

  /// Город погрузки (задача 040, п.7) — крупно, до маршрута: «Алматы → Ташкент».
  final String? originLabel;

  /// Плашка «Догруз» (040, п.6), если груз можно брать догрузом.
  final String? partialLabel;

  final String destinationLabel;
  final String bodyTypeLabel;
  final String priceLabel;
  final String readyDateLabel;
  /// null — без плашки (045 п.2: в ленте водителя плашка — только состояние
  /// груза для него самого, «Опубликован» не показываем).
  final String? statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Пересчёт цены в ₸ мелким шрифтом под ценой (см. design/DESIGN.md:
  /// "Цена всегда в валюте груза + пересчёт мелким шрифтом").
  final String? secondaryPriceLabel;

  /// Плашка слева сверху — "Близко к дому" или код страны (CountryCode).
  final Widget? badge;

  /// Рамка accent — карточка "Близко к дому" в ленте.
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
              Expanded(
                child: Text(
                  originLabel == null ? destinationLabel : '$originLabel → $destinationLabel',
                  style: AppTextStyles.route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (statusLabel != null) StatusBadge(label: statusLabel!, color: statusColor),
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
          if (partialLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
              child: Text(partialLabel!, style: AppTextStyles.small.copyWith(color: AppColors.primary)),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: AppSpacing.sm), trailing!],
        ],
      ),
    );
  }
}
