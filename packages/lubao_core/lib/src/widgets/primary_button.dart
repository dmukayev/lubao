import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Главная кнопка экрана — один ключевой action. Стиль берётся из
/// FilledButtonThemeData (AppTheme.light), здесь только высота/лоадер/иконка.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Высота — не меньше стандартной и растёт с шрифтом, надпись — до двух
    // строк: с крупным системным шрифтом «Отметить: Доставлено» резалось в
    // «Отметить: Достав…» (iPhone SE в e2e, Huawei ×1,3).
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity, minHeight: AppSizes.buttonHeight),
      child: FilledButton(
        onPressed: loading || onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.sm)],
                  Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                ],
              ),
      ),
    );
  }
}

/// Кнопка ключевого действия экрана (accent) — «Я на месте», «Опубликовать
/// груз», «Подтверждаю». На экране должна быть только одна.
class AccentButton extends StatelessWidget {
  const AccentButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accentSoft,
          foregroundColor: AppColors.onAccent,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
        onPressed: loading || onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.sm)],
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Квадратная кнопка-иконка на фоне primarySoft (уведомления, действия в
/// хедере и т.п.).
class IconSquareButton extends StatelessWidget {
  const IconSquareButton({super.key, this.icon, this.child, this.background, this.semanticLabel, this.onPressed, this.badge = false, this.size = 48, this.loading = false})
      : assert(icon != null || child != null);

  final IconData? icon;
  /// Готовый значок вместо `icon` (например, WhatsAppIcon).
  final Widget? child;
  final Color? background;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool badge;
  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: background ?? AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.field),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.field),
              onTap: loading ? null : onPressed,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Semantics(
                        label: semanticLabel,
                        button: true,
                        child: child ?? Icon(icon, color: AppColors.primary, size: 22),
                      ),
              ),
            ),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
