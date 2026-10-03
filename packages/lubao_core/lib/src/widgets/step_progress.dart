import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Индикатор шагов регистрации (7 сегментов, см. 04/05-register-*.png).
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.currentStep, this.totalSteps = 7});

  /// Номер текущего шага, начиная с 1.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final done = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : AppSpacing.xs),
            height: 4,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
