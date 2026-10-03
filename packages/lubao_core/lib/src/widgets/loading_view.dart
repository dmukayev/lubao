import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Загрузка — skeleton, а не спиннер (см. design/DESIGN.md). Показывает
/// несколько плейсхолдер-карточек, форма которых близка к типичному списку
/// (лента грузов, сделки, чаты), поэтому подходит как дефолт почти везде.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    // Column, а не ListView: LoadingView вставляется и в места с
    // ограниченной высотой (тело Scaffold), и в Column без Expanded — там
    // ListView падает с "unbounded height". Фиксированных 3 карточек-плейсхолдеров
    // достаточно, скролл для загрузки не нужен.
    return Skeletonizer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration:
                    BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Хоргос → Шымкент', style: AppTextStyles.route),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Тент · 20 т · 82 м³', style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('\$1 500', style: AppTextStyles.priceCard),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry, this.retryLabel});

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 200,
                child: PrimaryButton(label: retryLabel ?? 'Retry', onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = LucideIcons.inbox});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
